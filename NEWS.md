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
