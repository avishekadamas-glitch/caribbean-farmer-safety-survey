if(dir.exists('.Rlib')) .libPaths(c('.Rlib',.libPaths()))
library(lavaan)
dir.create('results/sem',recursive=TRUE,showWarnings=FALSE)
source('code/model_helpers.R')
d<-read.csv('data/survey_numeric_clean.csv',check.names=FALSE)
raw<-read.csv('data/survey_numeric_original.csv',check.names=FALSE)
# Ordinal analyses use the corrected dataset; legacy replication uses uncorrected values.
for(n in c('original','content')) {
 m<-paste(readLines(paste0('models/',n,'_measurement.lav')),collapse='\n')
 for(g in c(FALSE,TRUE)) {
  label<-paste0(n,'_ordinal_',if(g)'groups' else 'pooled')
  f<-cfa(m,data=d,ordered=TRUE,estimator='WLSMV',missing='pairwise',group=if(g)'Country' else NULL)
  savefit(f,label)
 }
}
for(n in c('original_amos','exogenous_covariances_free')) {
 m<-paste(readLines(paste0('models/',n,'.lav')),collapse='\n')
 f<-sem(m,data=raw,estimator='ML',missing='fiml',meanstructure=TRUE,fixed.x=FALSE,int.lv.free=FALSE,auto.cov.lv.x=FALSE,auto.cov.y=FALSE)
 savefit(f,n)
}
# Failed measurement adequacy prevents interpretation of latent country path comparisons.
# Do not select the favorable scaled CFI while omitting corrected robust CFI/RMSEA.
capture.output(sessionInfo(),file='results/sem/sessionInfo.txt')
