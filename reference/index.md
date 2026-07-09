# Package index

## Traces

Turn an event log into a traces object.

- [`as_traces()`](https://pdelias.github.io/simOutrank/reference/as_traces.md)
  : Represent an event log as traces

- [`summary(`*`<traces>`*`)`](https://pdelias.github.io/simOutrank/reference/summary.traces.md)
  :

  Per-case summary of a `traces` object

## Criteria

Build the criteria that define pairwise similarity.

- [`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
  : Define an outranking criterion
- [`q()`](https://pdelias.github.io/simOutrank/reference/q.md) :
  Quantile threshold specification
- [`crit_nominal()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md)
  [`crit_ordinal()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md)
  [`crit_numeric()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md)
  : Attribute-based criterion templates
- [`crit_custom()`](https://pdelias.github.io/simOutrank/reference/crit_custom.md)
  : Custom criterion
- [`crit_activity_profile()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
  [`crit_transitions()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
  [`crit_edit_distance()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
  [`crit_trace_length()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
  [`crit_distinct_activities()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
  [`crit_duration()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
  : Process-aware criteria

## Similarity and clustering

- [`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md)
  : Outranking credibility matrix
- [`cluster_traces()`](https://pdelias.github.io/simOutrank/reference/cluster_traces.md)
  : Cluster traces from a credibility matrix
- [`eigengap()`](https://pdelias.github.io/simOutrank/reference/eigengap.md)
  : Eigenvalue gap diagnostic

## Robustness

Trim outliers and inject domain knowledge.

- [`trim_outliers()`](https://pdelias.github.io/simOutrank/reference/trim_outliers.md)
  : Trim outlier cases
- [`must_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md)
  [`cannot_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md)
  : Must-link and cannot-link constraints

## Validation and output

- [`validate_clusters()`](https://pdelias.github.io/simOutrank/reference/validate_clusters.md)
  : Internal cluster validity indices
- [`augment_log()`](https://pdelias.github.io/simOutrank/reference/augment_log.md)
  : Join cluster memberships onto an event log
- [`plot(`*`<outrank_clust>`*`)`](https://pdelias.github.io/simOutrank/reference/plot.outrank_clust.md)
  : Plot a trace clustering

## Data

- [`illustrative_log`](https://pdelias.github.io/simOutrank/reference/illustrative_log.md)
  : Illustrative customer-service event log
