# Caribbean farmer safety survey

Deidentified numerical survey data and reproducible analyses for **Institutional support and occupational safety among farmers in Trinidad and Tobago and Guyana**, by Barry Parasram and Avishek Choudhury.

Version **2.0.0**, 13 October 2026. Zenodo: https://doi.org/10.5281/zenodo.23349784. Repository: https://github.com/avishekadamas-glitch/caribbean-farmer-safety-survey.

The cross-sectional survey recruited 2,000 active farmers, 1,000 per country, between January and March 2026. Recruitment combined geographic stratification with purposive community selection and convenience/referral recruitment; individual inclusion probabilities and community identifiers are unavailable. The sample does not support national prevalence estimates. WVU exempt protocol: **2401909110**.

## Analysis

The focused hybrid SEM represents risk beliefs (C1–C4), coping (C11–C13), and safety confidence (C14–C16) as ordinal latent factors. PPE and handling are defined observed inventories. Their equations each include the three factors, six context indices, and categorical country and A1–A11 controls. The factors are also adjusted for the context indices and controls, with correlated factor residuals and correlated practice residuals. Conditional WLSMV is used on **1,832 farmers reporting current pesticide or other agricultural-chemical use**. Corrected robust fit is available for the stand-alone psychological CFA, but unavailable for the mixed conditional SEM; the SEM fit indices are explicitly scaled.

Separate health models use farmers reporting current pesticide or other agricultural-chemical use for symptom recurrence (**n = 1,859**) and study-specific distress (**n = 1,851**) and all farmers for any farming-season heat dizziness (**n = 1,966**). Linear models and the pooled binary heat model use HC3 covariance. A joint Holm correction covers exactly **26 focal coefficients**, 18 SEM and 8 health; intervals are nominal. Native unstandardized SEM tests are used for multiplicity adjustment, while standardized coefficients use delta-method confidence intervals.

The individual-barrier sensitivity changes only the C5–C8 mean to four numerical items, retaining the same SEM cohort and all other choices. Additional outputs document internal partitions, estimator assumptions, country measurement equality, cohort/profile checks, symptom occurrence and the qualified ordinal heat model. Ordinal heat proportional-odds equality is rejected. Exact country measurement equality is unsupported; no formal latent country mean/path comparison or ordinary-MLE country heat inference is claimed. Specifications are exploratory and data-informed; the internal validation partition is not independent external confirmation. All associations remain cross-sectional and do not establish mediation, clinical diagnosis or intervention effectiveness.

## Contents

- `data/`: deidentified numerical source/cleaned records, dictionary, six-cell correction log, fixed folds and SEM cohort labels.
- `models/`: explicit selected SEM, individual-barrier and measurement syntax.
- `code/`: selected-model, health, joint multiplicity, descriptive/data-check and figure scripts.
- `results/behavior/`: complete SEM/measurement parameters, standardized delta-method intervals, fit indices, warnings and population/adjustment mappings.
- `results/health/`: every health/control coefficient, diagnostics and specified sensitivities.
- `results/primary_family/`: the joint 26 family, exact nominal p values and Holm mapping.
- `figures/`: Figs 1–3, source tables, captions and plotting metadata.

The numerical source file preserves coding exceptions; all models use the reconciled cleaned file. Two valid E15 category3 responses are restored and four invalid A11 category2 responses are treated as missing. No other numerical responses are changed. Matching profiles are retained in primary analyses and assessed for influence, since matching answers do not establish duplicated respondents.

## Reproduce

Use R 4.2.3 with lavaan 0.7-3, semTools 0.5-10, sandwich 3.1-3, MASS 7.3-58.2 and jsonlite 2.0.0 (executed session details are saved). Install the required R packages in your own library, and run from this release root:

```sh
Rscript code/reproduce_all.R
```

Alternatively run the numbered scripts individually. Optional inputs/output directories are documented at the top of each script. Outputs are overwritten reproducibly. The fixed partition is supplied in `data/model_folds.csv`; its seed is 20261013 and exact numerical profiles remain in the same fold. No raw location/community labels are released.

Python figure reproduction uses matplotlib, numpy, pandas and Pillow. From this root, run the figure scripts listed in `figures/plotting_instructions.txt`; they read saved numerical results and write the PNG and TIFF figure files. Figures use separate linear-coefficient and odds-ratio axes.

## Sharing and interpretation

Source participant identifiers, detailed locations, consent initials/signatures, contacts, scans, interview transcripts and identity lookup tables are excluded. Release `record_id` values are arbitrary row labels linking the numerical files, not participant identifiers. Only the deidentified survey is public. Self-reported symptoms are not clinical diagnoses; no unrecorded sampling clusters or causal interpretation are supplied by the code.

Data, dictionary, documentation and figures are licensed under **CC BY 4.0**; analysis and figure code under **MIT**. Cite the authors and the version-specific Zenodo DOI. A SHA256 manifest permits file-integrity checks.
