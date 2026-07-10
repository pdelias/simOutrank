# Datasets for "Improving the non-compensatory trace-clustering decision process" (Delias et al., 2023, ITOR, 30(3), 1387-1406, doi:10.1111/itor.13062)

Traced from `Robustness enhancements/simOutrank enhancments scripts.R` and
`Robustness enhancements/Non-compensatory_process_scripts.R`. Both scripts
also exist verbatim under `R package/`.

## Files

- `Illustrative_event_Log.csv` — the 25-case synthetic "Gold/Blue customer"
  example (Section 4.1, Tables 1-3 of the paper). Source:
  `Robustness enhancements/Illustrative event Log.csv`. Read at line 7 of
  the enhancement script (`Log<- read_csv("Illustrative event Log.csv")`).
  Small enough to ship as package data (`data/`) per the design doc.

- `similarity_ord.rds` — the precomputed outranking similarity matrix S for
  the BPIC'11 case study, same criteria/thresholds as the foundations paper
  (Delias et al. 2018). Source: `Datasets/similarity_ord.rds` (top level of
  `Outranking Similarity/`). Loaded directly at line 169 of the enhancement
  script instead of being recomputed, so this is the regression fixture for
  the spectral-clustering / must-link / outlier-trimming demonstrations in
  Section 4.2-4.3 of the paper.

- `global_Log2_n10_ord.csv` — the preprocessed BPIC'11 event log (new case
  IDs after the 7-day revisit split, as described in Delias et al. 2018),
  used to attach case IDs and case attributes (Start.Depart, Treat.101,
  Urgency, etc.) back onto the cluster memberships. Source:
  `Datasets/global_Log2_n10_ord.csv` (top level). Read at line 207 of the
  enhancement script.

- `Outliers_trimmingPLG.csv` — CN / CNC / CNCk complexity metrics at
  trimming percentages 0, 5, 10, 15, 20% (both average and max), underlying
  Fig. 3 of the paper. Source:
  `Robustness enhancements/Datasets/Outliers_trimmingPLG.csv`. Read at
  line 340 of the enhancement script.

- `MustLink_Urgency.csv` — cluster x Urgency-category composition, Baseline
  vs. Domain (must-link) scenario, underlying Fig. 2 of the paper. Source:
  `Robustness enhancements/Datasets/MustLink_Urgency.csv`. Read at line 436
  of the enhancement script.

## Not copied (yet)

- `Robustness enhancements/Datasets/Experiments Results.xlsx` — Table 4
  benchmark (CN/CNC/CNCk against ActiTrac, DWS, agglomerative-Jaccard,
  simOutrank). Copy failed repeatedly with a file-lock error
  ("Resource deadlock avoided") from the Google Drive mount — likely the
  file is open elsewhere or still syncing. Retry the copy, or open and
  re-save it once, then retry.

- The per-method clustered `.xes` exports in
  `Robustness enhancements/Datasets/` (`ActiTrac*`, `DWS_cl*`,
  `Agglo_jaccard_cl*`, `simOutrank_cl*`, `simOutrank_1_cl*`,
  `global_Log2_n10_ord.xes`) — these are the process-mined outputs fed into
  external tools (ProM/Disco) to compute the Table 4 metrics for the
  competing methods. Not needed to reproduce the R package's own
  computations; some are tens of MB. Not fetched to avoid an unrequested
  bulk download; say the word if you want them pulled in too.

## Raw source (not copied, lives outside this project folder)

`Graph matching/BPIC_2011Hospital_log.csv` (sibling of `Outranking
Similarity/` under `PaperLand/`) — the original BPIC 2011 hospital log
before the case-splitting preprocessing. Needed only if you want to
regenerate `similarity_ord.rds` / `global_Log2_n10_ord.csv` from scratch
rather than use the fixtures above.
