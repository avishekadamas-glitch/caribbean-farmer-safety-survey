# Caribbean farmer safety survey data and reproducible analyses

Authors: Barry Parasram and Avishek Choudhury, West Virginia University.

Cross-sectional survey of 2,000 farmers (1,000 Trinidad and Tobago, 1,000 Guyana), January–March 2026. Eligibility was active farming; the authors report that all farmers approached agreed to participate. The study received a WVU IRB exemption under protocol 2401909110. Public release of survey data was authorized by the corresponding author; interviews are excluded.

## Scientific status

The original confirmatory SEM is not supported by adequate fit. Correcting independence restrictions improves fit but does not validate the model. Ordinal CFA also has inadequate corrected robust fit; grouped robust fit is unavailable. Reanalyses therefore report exploratory observed-domain associations, not causal effects, validated latent pathways, mediation or intervention superiority. This release is a reproducibility package for a manuscript being revised for PLOS ONE; it is not evidence of journal acceptance.

## Files

- `data/survey_numeric_original.csv`: deidentified numerical source values, including documented invalid/missing entries.
- `data/survey_numeric_clean.csv`: same rows, with two E15 coding omissions restored and four invalid A11 values set missing.
- `data/corrections.csv`: changes using release-only record labels.
- `data/data_dictionary.csv`: variable wording, coding and recall periods.
- `models/`: exact legacy SEM and transparent alternative measurement specifications.
- `code/01_observed_associations.R`: primary and sensitivity analyses; HC3 confidence intervals; Holm adjustment across all 28 focal tests.
- `code/02_sem_diagnostics.R`: ML/FIML legacy replication and ordinal WLSMV measurement diagnostics.
- `results/`: executed numerical results and software information.
- `analysis_review.ipynb`: executed companion with results, figures and a rerun option.
- `figures/`: final scientific figure.

Original survey IDs and geographic labels have been removed and row order shuffled. No names, emails, phone numbers, initials, signatures, interviews, paper scans or identifying lookup table are included. Country and coarse coded demographic/farm categories are retained for reproducibility. Users must not attempt reidentification.

## Reproduce

Run from this repository directory, with R installed:

```sh
Rscript code/install_dependencies.R
Rscript code/00_validate_cleaning.R
Rscript code/01_observed_associations.R
Rscript code/02_sem_diagnostics.R
Rscript code/03_descriptive_tables.R
```

To reproduce the figure, install Python pandas, matplotlib and Pillow, then run `python code/04_figure.py`.

Reference environment: R 4.2.3, lavaan 0.7-3, sandwich 3.1-3. Numerical optimization may differ slightly by platform/version. The notebook uses Python for presentation and invokes the R scripts; its saved outputs can be read without executing.

## Interpretation and limitations

Recruitment had purposive and convenience elements; unknown individual inclusion probabilities and missing community identifiers preclude population weighting or verified design-correct standard errors. Main models use complete constituent-item scores and modelwise complete cases; pesticide behavior/symptom/distress models primarily include current pesticide users. Country is adjusted categorically. Scores are equally weighted observed summaries and do not establish a latent trait or clinical diagnosis. Distress recall is one week; recent pesticide symptoms three months; heat items have nonuniform wording/windows. Identical profiles are retained in primary analyses because distinct survey IDs are not evidence of duplicate interviews; exclusion of excess profiles is sensitivity only. Some nonusers answered pesticide questions without a not-applicable option. Model intervals are nominal 95% HC3, not adjusted for clustering; focal p values use Holm adjustment.

### Legacy reproduction

The original AMOS model has 160 estimated parameters and 920 degrees of freedom. Normal-likelihood lavaan chi-square differs from supplied AMOS by the N vs N−1 convention; scaling by 1999/2000 reproduces AMOS chi-square 12336.354. Baseline degrees of freedom differ (lavaan 990, AMOS 1035), so TLI is not identical. This is an independent reproduction, not a new AMOS run.

## License

Survey data, dictionary, figures and documentation: Creative Commons Attribution 4.0 (CC BY 4.0), https://creativecommons.org/licenses/by/4.0/ . Analysis code: MIT (see LICENSE_CODE).

## Citation

Parasram B, Choudhury A. Caribbean farmer safety survey data and reproducible analyses. 2026. Repository: https://github.com/avishekadamas-glitch/caribbean-farmer-safety-survey . Version 1.0.0 is archived in Zenodo: https://doi.org/10.5281/zenodo.23347518 . The archive contains the frozen package at GitHub commit `3c7ff253ce92f3bb1a3b8c61c8a84ef48ee47607`; this GitHub update adds DOI metadata without changing those archived files.
