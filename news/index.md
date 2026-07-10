# Changelog

## simOutrank 0.2.0

### Data

- `illustrative_log` now ships the authoritative CSV from Delias et
  al. (2023) rather than a reconstruction of Table 1. **Breaking:** case
  ids are now `"1"`–`"25"` (previously `G1`/`B1`…), the lower tier is
  `"NORMAL"` (previously `"Blue"`), and `satisfaction` is
  `"High"`/`"Low"` (previously upper case). The credibility matrix `S`
  is unchanged in value.

### Vignettes

- The reproduction vignettes use the real illustrative log. The
  large-log article now reproduces the BPIC’11 case study of Delias et
  al. (2023), including Figures 2 and 3 from bundled aggregate tables.

### Internal

- Added gated (`skip_on_cran`) regression tests on the BPIC’11
  similarity matrix. That matrix and the preprocessed BPIC’11 log are
  kept local-only under the 4TU General Terms of Use and are not
  redistributed with the package.

## simOutrank 0.1.0

First public release. `simOutrank` implements outranking-based trace
clustering for process mining.

### Pipeline

- [`as_traces()`](https://pdelias.github.io/simOutrank/reference/as_traces.md)
  turns a `data.frame` event log (or, with , an
  `eventlog`/`activitylog`) into a `traces` object.
- Criterion helpers build the pairwise measures: process-aware
  ([`crit_activity_profile()`](https://pdelias.github.io/simOutrank/reference/crit_process.md),
  [`crit_transitions()`](https://pdelias.github.io/simOutrank/reference/crit_process.md),
  [`crit_edit_distance()`](https://pdelias.github.io/simOutrank/reference/crit_process.md),
  [`crit_trace_length()`](https://pdelias.github.io/simOutrank/reference/crit_process.md),
  [`crit_distinct_activities()`](https://pdelias.github.io/simOutrank/reference/crit_process.md),
  [`crit_duration()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)),
  attribute templates
  ([`crit_nominal()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md),
  [`crit_ordinal()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md),
  [`crit_numeric()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md))
  and the
  [`crit_custom()`](https://pdelias.github.io/simOutrank/reference/crit_custom.md)
  escape hatch, all built on
  [`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
  with fixed-number or quantile
  ([`q()`](https://pdelias.github.io/simOutrank/reference/q.md))
  thresholds.
- [`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md)
  aggregates the criteria into the ELECTRE-III credibility matrix `S`.
- [`cluster_traces()`](https://pdelias.github.io/simOutrank/reference/cluster_traces.md)
  partitions `S` by normalized spectral clustering (Ng–Jordan–Weiss) or
  hierarchical clustering;
  [`eigengap()`](https://pdelias.github.io/simOutrank/reference/eigengap.md)
  helps choose `k`.

### Robustness and diagnostics

- [`trim_outliers()`](https://pdelias.github.io/simOutrank/reference/trim_outliers.md)
  (greedy and exact integer-program methods).
- [`must_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md)
  /
  [`cannot_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md)
  pairwise constraints.
- [`validate_clusters()`](https://pdelias.github.io/simOutrank/reference/validate_clusters.md)
  (connectivity and Dunn index via ),
  [`augment_log()`](https://pdelias.github.io/simOutrank/reference/augment_log.md)
  and [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods.

### Data and documentation

- Bundled `illustrative_log` dataset (Delias et al., 2023, Table 1).
- Vignettes: getting started, reproducing the illustrative example,
  robustness, and parameter tuning; plus website articles reproducing
  the emergency-room study and clustering a large log.
