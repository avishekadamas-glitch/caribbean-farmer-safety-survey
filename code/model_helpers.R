savefit <- function(f,name) {

 capture.output(summary(f,fit.measures=TRUE,standardized=TRUE,rsquare=TRUE),file=paste0('results/sem/',name,'.txt'))
 write.csv(parameterEstimates(f,standardized=TRUE),paste0('results/sem/',name,'_parameters.csv'),row.names=FALSE)
 fm <- fitMeasures(f)
 write.csv(data.frame(metric=names(fm),value=as.numeric(fm)),paste0('results/sem/',name,'_fit.csv'),row.names=FALSE)
 cat('\n',name,'converged',lavInspect(f,'converged'),'admissible',lavInspect(f,'post.check'),'\n')
 print(fm[intersect(c('chisq','df','cfi','tli','rmsea','srmr','chisq.scaled','df.scaled','cfi.scaled','tli.scaled','rmsea.scaled','cfi.robust','tli.robust','rmsea.robust'),names(fm))])
 flush.console()
}
