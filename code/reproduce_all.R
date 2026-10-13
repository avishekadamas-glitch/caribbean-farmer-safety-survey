# Run from the release root: Rscript code/reproduce_all.R
if (dir.exists('.Rlib')) .libPaths(c('.Rlib', .libPaths()))
needed <- c('lavaan','semTools','sandwich','MASS','jsonlite')
stopifnot(all(vapply(needed, requireNamespace, logical(1), quietly=TRUE)))
rscript <- file.path(R.home('bin'),'Rscript')
run <- function(script,args=character()) {
  status <- system2(rscript,c(script,args))
  if(status != 0)stop(paste('Analysis failed:',script))
}
run('code/01_selected_hybrid_models.R',c('data/survey_numeric_clean.csv','data/model_folds.csv','results/behavior'))
run('code/02_health_associations.R')
run('code/03_combine_primary_family.R')
run('code/04_descriptives_and_data_checks.R')
cat('Numerical analysis complete. Run the Python figure scripts described in README.md.\n')
