if(dir.exists('.Rlib')) .libPaths(c('.Rlib',.libPaths()))
library(sandwich)
library(jsonlite)
d <- read.csv('data/survey_numeric_clean.csv',check.names=FALSE)
dir.create('results/observed',showWarnings=FALSE)
scores <- list(Training=paste0('B',1:3), Support=c('B4','B5'),Oversight=c('B6','B7'),Risk=paste0('C',1:4),Barriers=paste0('C',5:8),Benefits=c('C9','C10'),Coping=paste0('C',11:13),Confidence=paste0('C',14:16),Norms=c('C17','C19'),PPE=paste0('D',1:4),Handling=paste0('D',5:8),HeatProtection=c('D10','D12','D13'),Symptoms=paste0('E',1:4),Distress=paste0('E',13:15))
for(n in names(scores)) d[[n]] <- rowMeans(d[,scores[[n]],drop=FALSE],na.rm=FALSE)
dups <- duplicated(d[,setdiff(names(d),'record_id')])
controls <- paste(c('Country',paste0('A',1:11)),collapse='+')
for(v in c('Country',paste0('A',1:11))) d[[v]] <- factor(d[[v]])
user <- !is.na(d$A10) & d$A10 %in% c('1','2')
models <- list(Training=c('Support','Oversight'), PPE=c('Support','Oversight','Training','Risk','Barriers','Benefits','Coping','Confidence','Norms'),Handling=c('Support','Oversight','Training','Risk','Barriers','Benefits','Coping','Confidence','Norms'),Symptoms=c('PPE','Handling'),E10='HeatProtection',Distress=c('PPE','Handling','Coping','Confidence','Symptoms'))
fitone <- function(y,dat,label,logistic=FALSE) {
 form <- as.formula(paste(y,'~',paste(models[[y]],collapse='+'),'+',controls))
 dat <- droplevels(dat[complete.cases(dat[,all.vars(form)]),])
 # Drop any constant nuisance controls only in stratified/subset analyses.
 flat <- c('Country',paste0('A',1:11)); flat<-flat[sapply(dat[,flat],function(x) length(unique(x)))<2]
 if(length(flat)) form<-as.formula(paste(y,'~',paste(c(models[[y]],setdiff(c('Country',paste0('A',1:11)),flat)),collapse='+')))
 if(logistic) {dat[[y]]<-as.integer(dat[[y]]>0); f<-glm(form,dat,family=binomial())} else f<-lm(form,dat)
 V<-vcovHC(f,type='HC3'); b<-coef(f); se<-sqrt(diag(V)); z<-b/se
 p<-if(logistic)2*pnorm(-abs(z)) else 2*pt(-abs(z),df=df.residual(f))
 crit<-if(logistic)qnorm(.975) else qt(.975,df=df.residual(f))
 out<-data.frame(analysis=label,outcome=y,term=names(b),estimate=b,se=se,lower=b-crit*se,upper=b+crit*se,p=p,n=nobs(f),focal=names(b)%in%models[[y]],row.names=NULL)
 out$odds_ratio<-NA_real_; out$or_lower<-NA_real_; out$or_upper<-NA_real_
 if(logistic){out$odds_ratio<-exp(b);out$or_lower<-exp(out$lower);out$or_upper<-exp(out$upper)}
 diagnostics<-data.frame(analysis=label,outcome=y,n=nobs(f),rank=f$rank,df=df.residual(f),max_leverage=max(hatvalues(f)),max_cook=max(cooks.distance(f)),converged=if(logistic)f$converged else TRUE,rank_deficient=anyNA(b),r2=if(logistic)NA else summary(f)$r.squared,pred_min=min(fitted(f)),pred_max=max(fitted(f)))
 write.csv(diagnostics,paste0('results/observed/',label,'_',y,'_diagnostics.csv'),row.names=FALSE)

 out
}
rows<-list()
joint<-complete.cases(d[,c(names(scores),'E10','Country',paste0('A',1:11))])
for(y in names(models)) {
 restrict<-y%in%c('PPE','Handling','Symptoms','Distress')
 main<-if(restrict)d[user,] else d
 rows[[paste(y,'main')]]<-fitone(y,main,'main')
 rows[[paste(y,'joint_complete')]]<-fitone(y,d[joint & if(restrict)user else TRUE,],'joint_complete')
 rows[[paste(y,'unique_profiles')]]<-fitone(y,d[!dups & if(restrict)user else TRUE,],'unique_profiles')
 if(restrict) rows[[paste(y,'all_farmers')]]<-fitone(y,d,'all_farmers')
 for(g in levels(d$Country)) rows[[paste(y,g)]]<-fitone(y,main[main$Country==g,],paste0('country_',g))
 if(y%in%c('Symptoms','E10'))rows[[paste(y,'binary')]]<-fitone(y,main,'binary',TRUE)
}
results<-do.call(rbind,rows)
results$p_holm<-NA_real_
idx<-results$analysis=='main' & results$focal
stopifnot(sum(idx)==28)
results$p_holm[idx]<-p.adjust(results$p[idx],method='holm')
write.csv(results,'results/observed/all_coefficients.csv',row.names=FALSE)
write.csv(results[idx,],'results/observed/main_focal.csv',row.names=FALSE)
write.csv(data.frame(score=names(scores),items=sapply(scores,paste,collapse=','),min=sapply(d[,names(scores)],min,na.rm=TRUE),max=sapply(d[,names(scores)],max,na.rm=TRUE),missing=sapply(d[,names(scores)],function(x)sum(is.na(x)))),'results/observed/score_definitions.csv',row.names=FALSE)
desc<-do.call(rbind,lapply(c('1','2'),function(g) do.call(rbind,lapply(names(scores),function(n){x<-d[d$Country==g,n];data.frame(country=g,score=n,n=sum(!is.na(x)),mean=mean(x,na.rm=TRUE),sd=sd(x,na.rm=TRUE))}))))
write.csv(desc,'results/observed/score_descriptives.csv',row.names=FALSE)
print(results[idx,c('outcome','term','estimate','lower','upper','p','p_holm','n')],row.names=FALSE)
capture.output(sessionInfo(),file='results/observed/sessionInfo.txt')
