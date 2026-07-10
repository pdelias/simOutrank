# simOutrank 0.2.0

## Data

* `illustrative_log` now ships the authoritative CSV from Delias et al. (2023)
  rather than a reconstruction of Table 1. **Breaking:** case ids are now
  `"1"`--`"25"` (previously `G1`/`B1`...), the lower tier is `"NORMAL"`
  (previously `"Blue"`), and `satisfaction` is `"High"`/`"Low"` (previously
  upper case). The credibility matrix `S` is unchanged in value.

## Vignettes

* The reproduction vignettes use the real illustrative log. The large-log
  article now reproduces the BPIC'11 case study of Delias et al. (2023),
  including Figures 2 and 3 from bundled aggregate tables.

## Internal

* Added gated (`skip_on_cran`) regression tests on the BPIC'11 similarity
  matrix. That matrix and the preprocessed BPIC'11 log are kept local-only
  under the 4TU General Terms of Use and are not redistributed with the
  package.


# simOutrank 0.1.0

First public release. `simOutrank` implements outranking-based trace clustering
for process mining.

## Pipeline

* `as_traces()` turns a `data.frame` event log (or, with \pkg{bupaR}, an
  `eventlog`/`activitylog`) into a `traces` object.
* Criterion helpers build the pairwise measures: process-aware
  (`crit_activity_profile()`, `crit_transitions()`, `crit_edit_distance()`,
  `crit_trace_length()`, `crit_distinct_activities()`, `crit_duration()`),
  attribute templates (`crit_nominal()`, `crit_ordinal()`, `crit_numeric()`)
  and the `crit_custom()` escape hatch, all built on `criterion()` with
  fixed-number or quantile (`q()`) thresholds.
* `outrank_similarity()` aggregates the criteria into the ELECTRE-III
  credibility matrix `S`.
* `cluster_traces()` partitions `S` by normalized spectral clustering
  (Ng–Jordan–Weiss) or hierarchical clustering; `eigengap()` helps choose `k`.

## Robustness and diagnostics

* `trim_outliers()` (greedy and exact integer-program methods).
* `must_link()` / `cannot_link()` pairwise constraints.
* `validate_clusters()` (connectivity and Dunn index via \pkg{clValid}),
  `augment_log()` and `plot()` methods.

## Data and documentation

* Bundled `illustrative_log` dataset (Delias et al., 2023, Table 1).
* Vignettes: getting started, reproducing the illustrative example, robustness,
  and parameter tuning; plus website articles reproducing the emergency-room
  study and clustering a large log.
