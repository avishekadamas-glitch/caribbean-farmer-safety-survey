raw <- read.csv('data/survey_numeric_original.csv',check.names=FALSE)
clean <- read.csv('data/survey_numeric_clean.csv',check.names=FALSE)
changes <- read.csv('data/corrections.csv',check.names=FALSE,colClasses='character')
stopifnot(nrow(raw)==2000, !anyDuplicated(raw$record_id), !any(c('Survey ID','Location') %in% names(raw)))
recreated <- raw
for(i in seq_len(nrow(changes))) {
 row <- match(as.integer(changes$record_id[i]),recreated$record_id)
 stopifnot(!is.na(row), changes$item[i] %in% names(recreated))
 recreated[row,changes$item[i]] <- if(changes$cleaned[i]=='missing') NA_real_ else as.numeric(changes$cleaned[i])
}
stopifnot(isTRUE(all.equal(recreated,clean,check.attributes=FALSE)))
stopifnot(all(clean$A11[!is.na(clean$A11)] %in% c(0,1)))
stopifnot(sum(clean$Country==1)==1000,sum(clean$Country==2)==1000)
cat('Original-to-clean reconstruction passes: exactly six documented corrections; 2,000 records.\n')
