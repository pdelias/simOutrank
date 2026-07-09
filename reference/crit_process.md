# Process-aware criteria

Convenience constructors that build a
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
from a trace measure, with sensible, overridable quantile-threshold
defaults. The similarity measures (`crit_activity_profile()`,
`crit_transitions()`) point in the `"similarity"` direction; the
distance measures point in the `"dissimilarity"` direction.

## Usage

``` r
crit_activity_profile(
  weight = 1,
  indifference = q(0.5),
  similarity = q(0.8),
  veto = NULL,
  name = "activity_profile"
)

crit_transitions(
  weight = 1,
  indifference = q(0.5),
  similarity = q(0.8),
  veto = NULL,
  name = "transitions"
)

crit_edit_distance(
  weight = 1,
  method = "osa",
  indifference = q(0.5),
  similarity = q(0.2),
  veto = NULL,
  name = "edit_distance"
)

crit_trace_length(
  weight = 1,
  indifference = q(0.5),
  similarity = q(0.2),
  veto = NULL,
  name = "trace_length"
)

crit_distinct_activities(
  weight = 1,
  indifference = q(0.5),
  similarity = q(0.2),
  veto = NULL,
  name = "distinct_activities"
)

crit_duration(
  weight = 1,
  units = "mins",
  indifference = q(0.5),
  similarity = q(0.2),
  veto = NULL,
  name = "duration"
)
```

## Arguments

- weight:

  A single positive weight (normalised later, when the similarity matrix
  is built).

- indifference, similarity, veto:

  Thresholds, each a number or a
  [`q()`](https://pdelias.github.io/simOutrank/reference/q.md) quantile
  specification. The defaults differ by direction and are documented in
  the argument defaults.

- name:

  Criterion label.

- method:

  Edit-distance method passed to
  [`stringdist::seq_distmatrix()`](https://rdrr.io/pkg/stringdist/man/seq_dist.html).

- units:

  Time unit for durations, passed to
  [`base::difftime()`](https://rdrr.io/r/base/difftime.html).

## Value

A
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
object.

## Details

- `crit_activity_profile()` – cosine similarity of activity count
  vectors.

- `crit_transitions()` – cosine similarity of distance-weighted
  transition profiles (weight `1 / gap`), as in the foundations paper.

- `crit_edit_distance()` – OSA edit distance on the integer-encoded
  traces.

- `crit_trace_length()` – `|n_a - n_b|`, the difference in event counts.

- `crit_distinct_activities()` – difference in the number of distinct
  activities.

- `crit_duration()` – difference in case duration.

## See also

[`crit_nominal()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md),
[`crit_ordinal()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md),
[`crit_numeric()`](https://pdelias.github.io/simOutrank/reference/crit_attribute.md),
[`crit_custom()`](https://pdelias.github.io/simOutrank/reference/crit_custom.md)
for attribute-based criteria.

## Examples

``` r
crit_activity_profile(weight = 0.2)
#> <criterion 'activity_profile'>: direction = similarity, weight = 0.2
#>   indifference = q(0.5), similarity = q(0.8), veto = none
crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3, veto = 6)
#> <criterion 'edit_distance'>: direction = dissimilarity, weight = 0.2
#>   indifference = 3, similarity = 2, veto = 6
```
