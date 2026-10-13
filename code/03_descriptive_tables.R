d<-read.csv('data/survey_numeric_clean.csv',check.names=FALSE)
dir.create('results/descriptive',recursive=TRUE,showWarnings=FALSE)
demo<-list(Male=c('A2','1'),Age_36_55=c('A1','2'),Five_or_more_years_farming=c('A4','2','3','4'),Tertiary_education=c('A3','5'),No_formal_education=c('A3','1'),Farm_below_five_acres=c('A7','1'),Regular_pesticide_use=c('A10','2'),Farming_primary_income=c('A11','1'))
rows<-list()
for(g in 1:2)for(n in names(demo)) {
 spec<-demo[[n]];x<-d[d$Country==g,spec[1]];den<-sum(!is.na(x));num<-sum(x%in%as.numeric(spec[-1]))
 rows[[paste(g,n)]]<-data.frame(country=g,characteristic=n,numerator=num,denominator=den,percent=100*num/den)
}
write.csv(do.call(rbind,rows),'results/descriptive/table2_sample.csv',row.names=FALSE)
health<-c(Skin_symptoms='E3',Heat_dizziness='E10',Lower_back_pain='E6',Shoulder_pain='E7',Hand_wrist_pain='E8',Knee_pain='E9')
rows<-list()
for(g in 0:2)for(n in names(health)) {
 x<-if(g==0)d[[health[n]]] else d[d$Country==g,health[n]]
 den<-sum(!is.na(x));num<-sum(x>0,na.rm=TRUE)
 rows[[paste(g,n)]]<-data.frame(country=g,symptom=n,numerator=num,denominator=den,percent=100*num/den)
}
write.csv(do.call(rbind,rows),'results/descriptive/table3_health.csv',row.names=FALSE)
rows<-list()
for(item in paste0('E',6:9)) {
 x<-d[d[[item]]==1 & !is.na(d[[item]]),paste0(item,' (If yes)')]
 den<-sum(!is.na(x));num<-sum(x==1,na.rm=TRUE)
 rows[[item]]<-data.frame(item=item,numerator=num,denominator=den,percent=100*num/den)
}
write.csv(do.call(rbind,rows),'results/descriptive/work_limitation.csv',row.names=FALSE)
items<-grep('^[BCDE][0-9]+$',names(d),value=TRUE)
rows<-list()
for(g in 0:2)for(item in items) {
 x<-if(g==0)d[[item]] else d[d$Country==g,item]
 den<-sum(!is.na(x))
 for(v in sort(unique(x[!is.na(x)])))rows[[paste(g,item,v)]]<-data.frame(country=g,item=item,response_category=v,count=sum(x==v,na.rm=TRUE),valid_n=den,percent=100*sum(x==v,na.rm=TRUE)/den,mean=mean(x,na.rm=TRUE),sd=sd(x,na.rm=TRUE))
}
write.csv(do.call(rbind,rows),'results/descriptive/item_distributions.csv',row.names=FALSE)
cat('Descriptive tables and separate item distributions saved. Country0 denotes all participants.\n')
