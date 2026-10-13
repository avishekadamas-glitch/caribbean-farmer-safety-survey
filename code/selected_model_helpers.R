save_selected_fit <- function(f, name, sample, n_requested, focal, out, warnings=character(), role='sensitivity') {
  key <- paste(name,sample,sep='_')
  pe <- parameterEstimates(f,standardized=TRUE)
  ss <- standardizedSolution(f,type='std.all',se=TRUE,ci=TRUE,level=.95)
  sl <- standardizedSolution(f,type='std.lv',se=TRUE,ci=TRUE,level=.95)
  write.csv(pe,file.path(out,'results',paste0(key,'_parameters.csv')),row.names=FALSE)
  write.csv(ss,file.path(out,'results',paste0(key,'_standardized_all.csv')),row.names=FALSE)
  write.csv(sl,file.path(out,'results',paste0(key,'_standardized_latent.csv')),row.names=FALSE)
  capture.output(summary(f,fit.measures=TRUE,standardized=TRUE,rsquare=TRUE),file=file.path(out,'results',paste0(key,'_output.txt')))
  writeLines(if(length(warnings))warnings else 'No warnings.',file.path(out,'results',paste0(key,'_warnings.txt')))
  metrics <- c('ntotal','npar','chisq.scaled','df.scaled','cfi.scaled','tli.scaled','rmsea.scaled',
    'rmsea.ci.lower.scaled','rmsea.ci.upper.scaled','cfi.robust','tli.robust','rmsea.robust',
    'rmsea.ci.lower.robust','rmsea.ci.upper.robust','srmr')
  fm <- fitMeasures(f,metrics)
  row <- data.frame(model=name,sample=sample,role=role,n_requested=n_requested,
    as.list(fm),converged=lavInspect(f,'converged'),admissible=lavInspect(f,'post.check'),
    corrected_robust_available=all(is.finite(fm[c('cfi.robust','tli.robust','rmsea.robust')])),
    warnings=if(length(warnings))paste(warnings,collapse=' | ')else'No warnings.',check.names=FALSE)
  if(length(focal)) {
    a <- pe[pe$op=='~'&pe$lhs%in%c('PPE','Handling')&pe$rhs%in%focal,]
    b <- ss[ss$op=='~',c('lhs','rhs','est.std','se','pvalue','ci.lower','ci.upper')]
    names(b)[3:7] <- c('beta','beta_se','beta_p_nominal','beta_ci_lower','beta_ci_upper')
    a <- merge(a,b,by=c('lhs','rhs'),all.x=TRUE,sort=FALSE)
    b <- sl[sl$op=='~',c('lhs','rhs','est.std','se','ci.lower','ci.upper')]
    names(b)[3:6] <- c('latent_standardized_estimate','latent_standardized_se','latent_standardized_ci_lower','latent_standardized_ci_upper')
    a <- merge(a,b,by=c('lhs','rhs'),all.x=TRUE,sort=FALSE)
    a$model<-name;a$sample<-sample;a$n<-as.integer(fm['ntotal']);a$role<-role
    a$predictor_representation <- ifelse(grepl('^F_',a$rhs),'latent_ordinal_response_factor',
      ifelse(a$rhs%in%c('C5','C6','C7','C8'),'individual_numeric_ordinal_item','observed_complete_item_mean'))
    a$unstandardized_units <- ifelse(grepl('^F_',a$rhs),
      'Outcome mean-score units per one underlying marker-indicator liability unit of the latent factor',
      'Outcome mean-score units per one observed predictor-score unit')
    a$beta_units <- 'Dimensionless fully standardized coefficient; nominal95% delta-method interval from standardizedSolution(type=std.all)'
    a$native_test <- 'Unstandardized WLSMV coefficient z test; primary Holm adjustment uses this p value'
    a <- a[order(match(a$lhs,c('PPE','Handling')),match(a$rhs,focal)),]
    write.csv(a,file.path(out,'tables',paste0(key,'_focal.csv')),row.names=FALSE)
  } else a<-NULL
  list(fit=row,focal=a,model=f)
}

fit_with_warnings <- function(model, dat, ordered, estimator='WLSMV', grouped=FALSE) {
  w<-character()
  f<-withCallingHandlers({
    if(estimator=='MLR')sem(model,data=dat,estimator='MLR',fixed.x=TRUE,meanstructure=FALSE)
    else sem(model,data=dat,ordered=ordered,estimator='WLSMV',fixed.x=TRUE,
      conditional.x=TRUE,missing='listwise')
  },warning=function(z){w<<-c(w,conditionMessage(z));invokeRestart('muffleWarning')})
  list(model=f,warnings=w)
}

build_behavior_model <- function(controls, barrier_components=FALSE) {
  lv<-c('F_Risk','F_Coping','F_Confidence')
  measurement<-c('F_Risk =~ C1+C2+C3+C4','F_Coping =~ C11+C12+C13',
    'F_Confidence =~ C14+C15+C16')
  base<-if(barrier_components)c('Support','Oversight','Training','Benefits','Norms','C5','C6','C7','C8')else
    c('Support','Oversight','Training','Barriers','Benefits','Norms')
  x<-c(base,controls)
  reg<-vapply(lv,function(v)paste(v,'~',paste(x,collapse=' + ')),character(1))
  behavior<-vapply(c('PPE','Handling'),function(v)paste(v,'~',paste(c(lv,x),collapse=' + ')),character(1))
  covs<-c('F_Risk ~~ F_Coping + F_Confidence','F_Coping ~~ F_Confidence','PPE ~~ Handling')
  list(syntax=paste(c(measurement,reg,behavior,covs),collapse='\n'),focal=c(lv,base))
}
