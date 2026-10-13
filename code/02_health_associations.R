# Run from the release root. Optional arguments: input CSV and output directory.
if (dir.exists('.Rlib')) .libPaths(c('.Rlib', .libPaths()))
library(sandwich)
library(MASS)
library(jsonlite)
args <- commandArgs(trailingOnly=TRUE)
input <- if(length(args)>=1)args[1]else'data/survey_numeric_clean.csv'
outdir <- if(length(args)>=2)args[2]else'results/health'
dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
d <- read.csv(input,check.names=FALSE)
stopifnot(!anyDuplicated(d$record_id))
raw_columns <- setdiff(names(d),'record_id')
matching_profile <- duplicated(d[,raw_columns,drop=FALSE])
scores <- list(Training=paste0('B',1:3),Support=c('B4','B5'),Oversight=c('B6','B7'),Risk=paste0('C',1:4),Barriers=paste0('C',5:8),Benefits=c('C9','C10'),Coping=paste0('C',11:13),Confidence=paste0('C',14:16),Norms=c('C17','C19'),PPE=paste0('D',1:4),Handling=paste0('D',5:8),HeatProtection=c('D10','D12','D13'),Symptoms=paste0('E',1:4),Distress=paste0('E',13:15))
for(n in names(scores))d[[n]] <- rowMeans(d[,scores[[n]],drop=FALSE],na.rm=FALSE)
stopifnot(all(d$E10[!is.na(d$E10)]%in%0:2))
d$HeatOccurrence <- ifelse(is.na(d$E10),NA_integer_,as.integer(d$E10>0))
d$AnyPesticideSymptom <- ifelse(is.na(d$Symptoms),NA_integer_,as.integer(d$Symptoms>0))
d$HeatOrdinal <- ordered(d$E10,levels=0:2)
controls <- c('Country',paste0('A',1:11))
for(v in controls)d[[v]]<-factor(d[[v]])
user <- !is.na(d$A10)&d$A10%in%c('1','2')
joint <- complete.cases(d[,c(names(scores),'E10',controls),drop=FALSE])
predictors <- list(Symptoms=c('PPE','Handling'),HeatOccurrence='HeatProtection',Distress=c('PPE','Handling','Coping','Confidence','Symptoms'),Training=c('Support','Oversight'),AnyPesticideSymptom=c('PPE','Handling'),HeatOrdinal='HeatProtection')
kind <- c(Symptoms='linear',HeatOccurrence='binary',Distress='linear',Training='linear',AnyPesticideSymptom='binary',HeatOrdinal='ordinal')
diagnostics <- list(); models <- list(); errors <- list()
fit_one <- function(y,dat,label,primary=FALSE) {
  cc <- controls
  form <- reformulate(c(predictors[[y]],cc),response=y)
  dd <- droplevels(dat[complete.cases(dat[,all.vars(form),drop=FALSE]),])
  cc <- controls[vapply(dd[,controls,drop=FALSE],function(x)length(unique(x))>1,logical(1))]
  form <- reformulate(c(predictors[[y]],cc),response=y)
  warnings <- character()
  result <- tryCatch(withCallingHandlers({
    if(kind[[y]]=='linear')f<-lm(form,dd)
    if(kind[[y]]=='binary')f<-glm(form,dd,family=binomial(),control=glm.control(maxit=100))
    if(kind[[y]]=='ordinal')f<-polr(form,dd,method='logistic',Hess=TRUE,model=TRUE,control=list(maxit=1000))
    b<-coef(f)
    converged<-if(kind[[y]]=='linear')TRUE else if(kind[[y]]=='binary')f$converged else f$convergence==0
    if(!converged||any(!is.finite(b)))stop('Nonconvergence or nonfinite coefficient')
    V<-if(kind[[y]]=='ordinal')sandwich(f) else vcovHC(f,type='HC3')
    V<-V[names(b),names(b),drop=FALSE];se<-sqrt(diag(V))
    if(any(!is.finite(se))||any(se<=0))stop('Nonfinite or zero robust standard error')
    rdf<-if(kind[[y]]=='ordinal')nrow(dd)-length(b)-length(f$zeta)else df.residual(f)
    crit<-if(kind[[y]]=='linear')qt(.975,rdf)else qnorm(.975)
    p<-if(kind[[y]]=='linear')2*pt(-abs(b/se),rdf)else 2*pnorm(-abs(b/se))
    scale<-if(kind[[y]]=='linear')'mean score difference'else if(kind[[y]]=='binary')'log odds of occurrence'else'common log odds of a higher response category'
    focal<-names(b)%in%predictors[[y]]
    out<-data.frame(analysis_id=ifelse(primary&focal,paste('health',y,names(b),sep='|'),paste(label,y,names(b),sep='|')),model_component=if(primary)'health primary'else if(y=='Training')'secondary training'else'health sensitivity',analysis=label,outcome=y,predictor=names(b),estimate=as.numeric(b),se=as.numeric(se),ci_lower=as.numeric(b-crit*se),ci_upper=as.numeric(b+crit*se),p_nominal=as.numeric(p),primary_family_member=primary&focal,focal=focal,estimate_scale=scale,variance=if(kind[[y]]=='ordinal')'sandwich HC0'else'HC3',n=nrow(dd),row.names=NULL)
    out$odds_ratio<-if(kind[[y]]=='linear')NA_real_ else exp(out$estimate)
    out$or_lower<-if(kind[[y]]=='linear')NA_real_ else exp(out$ci_lower)
    out$or_upper<-if(kind[[y]]=='linear')NA_real_ else exp(out$ci_upper)
    mm<-model.matrix(form,dd);rnk<-qr(mm)$rank
    fp<-if(kind[[y]]=='ordinal')as.numeric(predict(f,type='probs'))else fitted(f)
    sep<-character()
    if(kind[[y]]=='binary')for(v in cc)for(lv in levels(dd[[v]])) {
      yy<-dd[[y]][dd[[v]]==lv]
      if(length(yy)&&length(unique(yy))==1)sep<-c(sep,paste(v,lv,'constant outcome',length(yy),sep=':'))
    }
    diagnostics[[length(diagnostics)+1]]<<-data.frame(analysis=label,outcome=y,kind=kind[[y]],n=nrow(dd),rank=rnk,columns=ncol(mm),df=rdf,converged=converged,max_abs_coefficient=max(abs(b)),fitted_min=min(fp),fitted_max=max(fp),extreme_probability_n=if(kind[[y]]=='linear')NA_integer_ else sum(fp<1e-8|fp>1-1e-8),nuisance_constant_outcome_cells=paste(sep,collapse=';'),max_leverage=if(kind[[y]]=='ordinal')NA_real_ else max(hatvalues(f)),max_cook=if(kind[[y]]=='ordinal')NA_real_ else max(cooks.distance(f)),r_squared=if(kind[[y]]=='linear')summary(f)$r.squared else NA_real_,warnings=paste(unique(warnings),collapse=' | '))
    if(primary&&(length(sep)||rnk<ncol(mm)))stop('Primary binary model has a separated nuisance cell or rank deficiency')
    models[[paste(label,y,sep='|')]]<<-list(f=f,data=dd,form=form)
    out
  },warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e){
    errors[[length(errors)+1]]<<-data.frame(analysis=label,outcome=y,error=conditionMessage(e),warnings=paste(unique(warnings),collapse=' | '))
    if(primary)stop(conditionMessage(e))
    NULL
  })
  result
}
rows<-list()
for(y in c('Symptoms','HeatOccurrence','Distress')) {
  restrict<-y%in%c('Symptoms','Distress')
  main<-if(restrict)d[user,]else d
  rows[[length(rows)+1]]<-fit_one(y,main,'primary',TRUE)
  rows[[length(rows)+1]]<-fit_one(y,d[joint&if(restrict)user else TRUE,],'joint_complete')
  rows[[length(rows)+1]]<-fit_one(y,d[!matching_profile&if(restrict)user else TRUE,],'unique_profiles')
  if(restrict) {
    rows[[length(rows)+1]]<-fit_one(y,d,'all_farmers')
    for(g in levels(d$Country))rows[[length(rows)+1]]<-fit_one(y,main[main$Country==g,],paste0('country_',g,'_descriptive'))
  }
}
rows[[length(rows)+1]]<-fit_one('Training',d,'secondary_training')
rows[[length(rows)+1]]<-fit_one('AnyPesticideSymptom',d[user,],'binary_symptom_occurrence')
rows[[length(rows)+1]]<-fit_one('HeatOrdinal',d,'ordinal_heat_recurrence')
all<-do.call(rbind,rows);primary<-all[all$primary_family_member,]
stopifnot(nrow(primary)==8,!anyDuplicated(primary$analysis_id))
write.csv(all,file.path(outdir,'all_coefficients.csv'),row.names=FALSE)
write.csv(primary,file.path(outdir,'primary_focal_unadjusted.csv'),row.names=FALSE)
write.csv(all[all$outcome=='Training'&all$focal,],file.path(outdir,'secondary_training.csv'),row.names=FALSE)
ordinal_model<-models[['ordinal_heat_recurrence|HeatOrdinal']]$f
if(!is.null(ordinal_model)) {
  cutpoints<-ordinal_model$zeta;VC<-sandwich(ordinal_model)[names(cutpoints),names(cutpoints),drop=FALSE];cutse<-sqrt(diag(VC))
  write.csv(data.frame(outcome='HeatOrdinal',cutpoint=names(cutpoints),estimate=as.numeric(cutpoints),se_hc0=cutse,ci_lower=cutpoints-qnorm(.975)*cutse,ci_upper=cutpoints+qnorm(.975)*cutse,n=nobs(ordinal_model),row.names=NULL),file.path(outdir,'ordinal_heat_cutpoints.csv'),row.names=FALSE)
}
write.csv(do.call(rbind,diagnostics),file.path(outdir,'model_diagnostics.csv'),row.names=FALSE)
if(length(errors))write.csv(do.call(rbind,errors),file.path(outdir,'model_errors.csv'),row.names=FALSE)else write.csv(data.frame(analysis=character(),outcome=character(),error=character(),warnings=character()),file.path(outdir,'model_errors.csv'),row.names=FALSE)

# Correlated-score Wald diagnostic comparing the cumulative-logit slopes.
heat<-models[['primary|HeatOccurrence']]$data
x<-model.matrix(models[['primary|HeatOccurrence']]$form,heat)
y0<-as.integer(heat$E10>0);y1<-as.integer(heat$E10>1)
f0<-glm.fit(x,y0,family=binomial(),control=glm.control(maxit=100))
f1<-glm.fit(x,y1,family=binomial(),control=glm.control(maxit=100))
stopifnot(f0$converged,f1$converged,all(is.finite(coef(f0))),all(is.finite(coef(f1))))
p0<-f0$fitted.values;p1<-f1$fitted.values
B0<-solve(crossprod(x,x*as.vector(p0*(1-p0))))
B1<-solve(crossprod(x,x*as.vector(p1*(1-p1))))
h0<-rowSums((x%*%B0)*x)*p0*(1-p0);h1<-rowSums((x%*%B1)*x)*p1*(1-p1)
S0<-x*as.vector((y0-p0)/(1-h0));S1<-x*as.vector((y1-p1)/(1-h1))
V0<-B0%*%crossprod(S0)%*%B0;V1<-B1%*%crossprod(S1)%*%B1;V01<-B0%*%crossprod(S0,S1)%*%B1
VD<-V0+V1-V01-t(V01);delta<-coef(f1)-coef(f0)
z<-delta/sqrt(diag(VD))
diagrows<-data.frame(check='slope equality',term=colnames(x),lower_threshold_estimate=as.numeric(coef(f0)),upper_threshold_estimate=as.numeric(coef(f1)),difference=as.numeric(delta),difference_se_hc3=sqrt(diag(VD)),wald_statistic=as.numeric(z^2),df=1,p=2*pnorm(-abs(z)),n=nrow(heat),row.names=NULL)
ii<-which(colnames(x)!='(Intercept)');W<-drop(t(delta[ii])%*%solve(VD[ii,ii],delta[ii]))
diagrows<-rbind(diagrows,data.frame(check='all slope equality',term='all nonintercept slopes',lower_threshold_estimate=NA,upper_threshold_estimate=NA,difference=NA,difference_se_hc3=NA,wald_statistic=W,df=length(ii),p=pchisq(W,length(ii),lower.tail=FALSE),n=nrow(heat)))
write.csv(diagrows,file.path(outdir,'heat_proportional_odds_diagnostic.csv'),row.names=FALSE)
catrows<-do.call(rbind,lapply(c('all','1','2'),function(g){dd<-if(g=='all')heat else heat[heat$Country==g,];data.frame(country=g,E10_category=0:2,n=as.numeric(table(factor(dd$E10,levels=0:2))),valid_n=nrow(dd))}))
write.csv(catrows,file.path(outdir,'heat_category_counts.csv'),row.names=FALSE)
write.csv(data.frame(score=names(scores),items=vapply(scores,paste,collapse=',',FUN.VALUE=character(1)),rule='Unweighted mean; all component responses required',row.names=NULL),file.path(outdir,'score_definitions.csv'),row.names=FALSE)
write_json(list(primary_family_health_n=8,primary_family_combined_n=26,primary_family='18 behavioral SEM paths plus 8 health coefficients; joint Holm correction applied by the combined-family script',case_selection='Modelwise complete cases. Symptoms and distress restrict A10 to 1 or 2; heat uses all farmers. All covariates categorical. Constant controls omitted only in descriptive subgroup fits.',joint_sensitivity='All fourteen observed summaries, E10 and Country/A1-A11 complete; current-user restriction retained for pesticide outcomes.',matching_profile_sensitivity='One numerical profile representative retained for influence assessment; matching answers do not establish duplicated participants.',primary_heat='Binary E10>0, any dizziness/faintness in past farming season. Ordinal PO sensitivity retains all three response categories and is qualified by correlated-score threshold diagnostics.',symptom_coding='E1-E4: 0 no, 1 yes, 2 yes more than once; past three months after handling. Mean is a defined category-recurrence summary, not event count, dose or poisoning diagnosis. E5 ever medically attended poisoning is separate.',distress_coding='E13-E15 past week, each 0-3. Mean is study-specific distress summary, not DASS diagnosis or clinical severity threshold.',inference='All analyses exploratory; nominal robust intervals. Holm controls the designated combined focal family, not model-selection uncertainty or diagnostic/sensitivity tests.',country_heat='No ordinary-MLE country-specific heat inference is reported; sparse nuisance categories can generate boundary estimates.'),file.path(outdir,'methods_metadata.json'),pretty=TRUE,auto_unbox=TRUE)
capture.output(sessionInfo(),file=file.path(outdir,'sessionInfo.txt'))
print(primary[,c('analysis_id','estimate','ci_lower','ci_upper','p_nominal','n')],row.names=FALSE)
