# Run from the release root. Summaries use valid-response denominators.
d<-read.csv('data/survey_numeric_clean.csv',check.names=FALSE)
source<-read.csv('data/survey_numeric_source.csv',check.names=FALSE)
log<-read.csv('data/corrections.csv',check.names=FALSE)
stopifnot(nrow(d)==2000,nrow(source)==2000,identical(d$record_id,source$record_id),nrow(log)==6)
changed<-list()
for(v in setdiff(names(d),'record_id')) {
  a<-source[[v]];b<-d[[v]]
  same<-ifelse(is.na(a)&is.na(b),TRUE,ifelse(is.na(a)|is.na(b),FALSE,a==b))
  for(i in which(!same))changed[[length(changed)+1]]<-data.frame(record_id=d$record_id[i],item=v,source=a[i],cleaned=b[i])
}
changes<-do.call(rbind,changed)
stopifnot(nrow(changes)==6,setequal(paste(changes$record_id,changes$item),paste(log$record_id,log$item)))
out<-'results/descriptive';dir.create(out,recursive=TRUE,showWarnings=FALSE)
write.csv(changes,file.path(out,'verified_six_cell_reconciliation.csv'),row.names=FALSE)
missing<-data.frame(item=names(d),valid=vapply(d,function(x)sum(!is.na(x)),integer(1)),missing=vapply(d,function(x)sum(is.na(x)),integer(1)))
write.csv(missing,file.path(out,'item_missingness.csv'),row.names=FALSE)
counts<-list()
for(country in c(1,2))for(item in setdiff(names(d),'record_id')) {
  a<-d[[item]][d$Country==country]
  tt<-table(a,useNA='no')
  counts[[length(counts)+1]]<-data.frame(country=country,item=item,response=names(tt),n=as.numeric(tt),valid=sum(!is.na(a)),percent=100*as.numeric(tt)/sum(!is.na(a)))
}
write.csv(do.call(rbind,counts),file.path(out,'all_item_counts_by_country.csv'),row.names=FALSE)
items<-c('E1','E10','E6','E7','E8','E9')
occ<-do.call(rbind,lapply(c(0,1,2),function(g)do.call(rbind,lapply(items,function(v){a<-if(g==0)d[[v]]else d[[v]][d$Country==g];data.frame(country=if(g==0)'combined'else as.character(g),item=v,positive=sum(a>0,na.rm=TRUE),valid=sum(!is.na(a)),percent=100*mean(a>0,na.rm=TRUE))}))))
write.csv(occ,file.path(out,'symptom_occurrence.csv'),row.names=FALSE)
profiles<-d[,setdiff(names(d),'record_id'),drop=FALSE]
duplicated_n<-sum(duplicated(profiles))
stopifnot(duplicated_n==21)
write.csv(data.frame(records=2000,unique_numerical_profiles=2000-duplicated_n,excess_matching_profiles=duplicated_n),file.path(out,'numerical_profile_counts.csv'),row.names=FALSE)
cat('All2000 records accounted for; six numerical corrections verified; valid denominators exported.\n')
