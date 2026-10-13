# Run from the release root after the behavioral and health scripts.
# Optional arguments: behavioral CSV, health CSV, output directory.
args<-commandArgs(trailingOnly=TRUE)
behavior_file<-if(length(args)>=1)args[1]else'results/behavior/tables/behavioral_primary_family_unadjusted.csv'
health_file<-if(length(args)>=2)args[2]else'results/health/primary_focal_unadjusted.csv'
outdir<-if(length(args)>=3)args[3]else'results/primary_family'
dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
b<-read.csv(behavior_file,check.names=FALSE)
h<-read.csv(health_file,check.names=FALSE)
required<-c('analysis_id','model_component','outcome','predictor','p_nominal','primary_family_member','estimate','se','ci_lower','ci_upper','estimate_scale','n')
stopifnot(all(required%in%names(b)),all(required%in%names(h)),nrow(b)==18,nrow(h)==8,all(b$primary_family_member),all(h$primary_family_member))
cols<-union(names(b),names(h))
for(v in setdiff(cols,names(b)))b[[v]]<-NA
for(v in setdiff(cols,names(h)))h[[v]]<-NA
all<-rbind(b[,cols,drop=FALSE],h[,cols,drop=FALSE])
stopifnot(nrow(all)==26,!anyDuplicated(all$analysis_id),all(is.finite(all$p_nominal)),all(all$p_nominal>=0&all$p_nominal<=1))
all$p_holm<-p.adjust(all$p_nominal,method='holm')
all$family_size<-26L
all$p_test_source<-ifelse(grepl('^behavior\\|',all$analysis_id),'Native unstandardized WLSMV path test','HC3 test for the unstandardized observed association')
all$interval_note<-'Nominal 95% intervals; Holm adjustment applies to the joint 26-test focal family'
all$holm_below_0_05<-all$p_holm<.05
write.csv(all,file.path(outdir,'combined_primary_family.csv'),row.names=FALSE)
write.csv(all[grepl('^health\\|',all$analysis_id),],file.path(outdir,'health_primary_focal.csv'),row.names=FALSE)
write.csv(all[grepl('^behavior\\|',all$analysis_id),],file.path(outdir,'behavioral_primary_focal.csv'),row.names=FALSE)
write.csv(all[,c('analysis_id','p_nominal','p_holm','family_size','p_test_source','holm_below_0_05')],file.path(outdir,'holm_mapping.csv'),row.names=FALSE)
writeLines(c('The designated primary family has 18 behavioral paths and 8 health-regression coefficients.', 'Behavioral p values come from native unstandardized WLSMV tests. The same Holm p values are attached to the corresponding standardized beta rows; no standardized-zero-test substitution is made.', 'Health tests are HC3 tests of unstandardized score coefficients or log odds. Nominal intervals are not multiplicity-adjusted confidence sets.', 'The models and their comparison are exploratory. This family correction does not account for measurement uncertainty, model specification uncertainty, or unrecorded sampling clusters.', 'Secondary training, assumption diagnostics, candidate comparisons and sensitivity coefficients are excluded from the primary family. Very small native p values may round numerically to zero; manuscript display uses a threshold such as p<0.001.'),file.path(outdir,'family_definition.txt'))
print(all[,c('analysis_id','p_nominal','p_holm','family_size')],row.names=FALSE)
