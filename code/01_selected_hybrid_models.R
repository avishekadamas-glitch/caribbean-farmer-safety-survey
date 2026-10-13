# Run from this directory: Rscript run_selected_models.R data/survey_numeric_clean.csv data/model_folds.csv .
# Requires lavaan0.7-3 and semTools0.5.10. Fits only the selected models and fixed diagnostics.
suppressPackageStartupMessages(library(lavaan))
suppressPackageStartupMessages(library(semTools))
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==3)
input<-args[1];fold_path<-args[2];out<-args[3]
for(p in c('results','tables','models','data'))dir.create(file.path(out,p),recursive=TRUE,showWarnings=FALSE)
source('code/selected_model_helpers.R')
d0<-read.csv(input,check.names=FALSE)
fold<-read.csv(fold_path)
stopifnot(nrow(d0)==2000,!anyDuplicated(d0$record_id),!anyDuplicated(fold$record_id))
idx<-match(d0$record_id,fold$record_id);stopifnot(!anyNA(idx),all(d0$Country==fold$Country[idx]))
d0$fold<-fold$fold[idx]
blocks<-list(Training=paste0('B',1:3),Support=c('B4','B5'),Oversight=c('B6','B7'),
  Barriers=paste0('C',5:8),Benefits=c('C9','C10'),Norms=c('C17','C19'),
  PPE=paste0('D',1:4),Handling=paste0('D',5:8))
belief_items<-c(paste0('C',1:4),paste0('C',11:16))
for(nm in names(blocks))d0[[nm]]<-rowMeans(d0[,blocks[[nm]],drop=FALSE],na.rm=FALSE)
controls<-c('Country',paste0('A',1:11))
required<-unique(c(unlist(blocks),belief_items,controls))
eligible<-!is.na(d0$A10)&d0$A10%in%c(1,2)
complete<-complete.cases(d0[,required])
d<-d0[eligible&complete,]
stopifnot(sum(eligible)==1897,nrow(d)==1832)
write.csv(data.frame(record_id=d$record_id,Country=d$Country,fold=d$fold),file.path(out,'data','H1_analysis_population.csv'),row.names=FALSE)
write.csv(data.frame(population=c('All released records','Current pesticide users','Joint complete H1 variables'),n=c(nrow(d0),sum(eligible),nrow(d))),file.path(out,'tables','behavioral_population_counts.csv'),row.names=FALSE)
write.csv(data.frame(score=names(blocks),items=vapply(blocks,paste,collapse=',',character(1)),scoring='Equally weighted mean; every item required; no prorating'),file.path(out,'tables','observed_score_definitions.csv'),row.names=FALSE)
for(v in controls)d[[v]]<-droplevels(factor(d[[v]]))
X<-model.matrix(reformulate(controls),d)[,-1,drop=FALSE]
X<-X[,apply(X,2,function(x)length(unique(x))>1),drop=FALSE]
mapping<-data.frame(dummy=colnames(X),model_name=paste0('Z',seq_len(ncol(X))))
colnames(X)<-mapping$model_name;d<-cbind(d,X)
write.csv(mapping,file.path(out,'tables','categorical_control_mapping.csv'),row.names=FALSE)
H1<-build_behavior_model(colnames(X),FALSE)
BC<-build_behavior_model(colnames(X),TRUE)
writeLines(H1$syntax,file.path(out,'models','H1.lav'))
writeLines(BC$syntax,file.path(out,'models','Barrier_components.lav'))
parts<-list(pooled=d,development=d[d$fold<=3,],validation=d[d$fold>=4,])
rows<-list();primary<-NULL
for(sample in names(parts))for(nm in c('H1','Barrier_components')) {
  s<-if(nm=='H1')H1 else BC;dat<-parts[[sample]]
  stopifnot(all(sapply(dat[,colnames(X),drop=FALSE],function(x)length(unique(x))>1)))
  for(v in belief_items)stopifnot(all(table(factor(dat[[v]],levels=1:5))>0))
  ff<-fit_with_warnings(s$syntax,dat,belief_items)
  z<-save_selected_fit(ff$model,nm,sample,nrow(dat),s$focal,out,ff$warnings,
    if(nm=='H1'&&sample=='pooled')'primary_behavioral'else'sensitivity')
  rows[[paste(nm,sample)]]<-z$fit
  if(nm=='H1'&&sample=='pooled')primary<-z$focal
  cat(nm,sample,'n',nrow(dat),'CFI-scaled',z$fit$cfi.scaled,'SRMR',z$fit$srmr,'\n');flush.console()
}
stopifnot(nrow(primary)==18)
family<-data.frame(analysis_id=paste('behavior',primary$lhs,primary$rhs,sep='|'),
 model_component='H1_behavior',outcome=primary$lhs,predictor=primary$rhs,
 p_nominal=primary$pvalue,primary_family_member=TRUE,estimate=primary$est,se=primary$se,
 ci_lower=primary$ci.lower,ci_upper=primary$ci.upper,estimate_scale=primary$unstandardized_units,
 n=primary$n,beta=primary$beta,beta_se=primary$beta_se,
 beta_ci_lower=primary$beta_ci_lower,beta_ci_upper=primary$beta_ci_upper)
write.csv(family,file.path(out,'tables','behavioral_primary_family_unadjusted.csv'),row.names=FALSE)

# Numerical-indicator robustness diagnostic, preserving categorical covariate dummies.
for(sample in names(parts)) {
 ff<-fit_with_warnings(H1$syntax,parts[[sample]],NULL,'MLR')
 z<-save_selected_fit(ff$model,'H1_MLR',sample,nrow(parts[[sample]]),H1$focal,out,ff$warnings,'estimator_sensitivity')
 rows[[paste('H1_MLR',sample)]]<-z$fit
}

# Within-country direction checks; no between-country latent parameter comparison.
for(g in c('1','2')) {
 dat<-d[d$Country==g,]
 flat<-colnames(X)[sapply(dat[,colnames(X),drop=FALSE],function(x)length(unique(x))<2)]
 write.csv(mapping[mapping$model_name%in%flat,],file.path(out,'tables',paste0('H1_country_',g,'_constant_dummies.csv')),row.names=FALSE)
 s<-build_behavior_model(setdiff(colnames(X),flat),FALSE)
 ff<-fit_with_warnings(s$syntax,dat,belief_items)
 z<-save_selected_fit(ff$model,'H1',paste0('country_',g),nrow(dat),s$focal,out,ff$warnings,'country_direction_sensitivity')
 rows[[paste('H1_country',g)]]<-z$fit
}

# Selected ordinal belief measurement: distinct Risk/Coping/Confidence factors.
M1<-'Risk =~ C1+C2+C3+C4\nCoping =~ C11+C12+C13\nConfidence =~ C14+C15+C16'
writeLines(M1,file.path(out,'models','M1_measurement.lav'))
mparts<-list(pooled=d0,development=d0[d0$fold<=3,],validation=d0[d0$fold>=4,],
 country_1=d0[d0$Country==1,],country_2=d0[d0$Country==2,])
for(sample in names(mparts)) {
 dat<-mparts[[sample]];w<-character()
 for(v in belief_items)stopifnot(all(table(factor(dat[[v]],levels=1:5))>0))
 f<-withCallingHandlers(cfa(M1,data=dat,ordered=belief_items,estimator='WLSMV',missing='pairwise'),
 warning=function(z){w<<-c(w,conditionMessage(z));invokeRestart('muffleWarning')})
 z<-save_selected_fit(f,'M1_measurement',sample,nrow(dat),NULL,out,w,'measurement_diagnostic')
 rows[[paste('M1',sample)]]<-z$fit
}

# Fixed ordinal invariance diagnostics using Wu-Estabrook categorical identification.
invariant<-list();iddata<-d0;iddata$Country<-factor(iddata$Country,levels=c(1,2))
for(stage in c('configural','thresholds','thresholds_loadings')) {
 eq<-switch(stage,configural='',thresholds='thresholds',thresholds_loadings=c('thresholds','loadings'))
 w<-character()
 f<-withCallingHandlers({sy<-measEq.syntax(configural.model=M1,data=iddata,ordered=belief_items,
   parameterization='theta',ID.fac='std.lv',ID.cat='Wu.Estabrook.2016',group='Country',group.equal=eq)
   writeLines(as.character(sy),file.path(out,'models',paste0('M1_invariance_',stage,'.lav')))
   cfa(as.character(sy),data=iddata,ordered=belief_items,group='Country',
    estimator='WLSMV',parameterization='theta',missing='pairwise')},
   warning=function(z){w<<-c(w,conditionMessage(z));invokeRestart('muffleWarning')})
 invariant[[stage]]<-f
 z<-save_selected_fit(f,'M1_invariance',stage,nrow(iddata),NULL,out,w,'measurement_invariance_diagnostic')
 rows[[paste('invariance',stage)]]<-z$fit
}
diff<-lavTestLRT(invariant$configural,invariant$thresholds,invariant$thresholds_loadings,method='satorra.2000')
write.csv(as.data.frame(diff),file.path(out,'tables','M1_invariance_difference_tests.csv'))
capture.output(print(diff),file=file.path(out,'results','M1_invariance_difference_tests.txt'))
fits<-do.call(rbind,rows)
write.csv(fits,file.path(out,'tables','selected_model_fit.csv'),row.names=FALSE)

# Directly matched non-barrier sensitivity estimates; component coefficients use different units.
a<-read.csv(file.path(out,'tables','H1_pooled_focal.csv'))
b<-read.csv(file.path(out,'tables','Barrier_components_pooled_focal.csv'))
m<-merge(a[a$rhs!='Barriers',],b,by=c('lhs','rhs'),suffixes=c('_primary','_components'))
stopifnot(nrow(m)==16,nrow(b)==24)
m$beta_difference<-m$beta_components-m$beta_primary
m$same_direction<-sign(m$est_primary)==sign(m$est_components)
write.csv(m,file.path(out,'tables','barrier_sensitivity_matched_16_paths.csv'),row.names=FALSE)
capture.output(sessionInfo(),file=file.path(out,'results','session_info.txt'))
cat('PrimaryH1 n=',nrow(d),'current users=',sum(eligible),'primary18 paths; barrier sensitivity24 paths.\n')
