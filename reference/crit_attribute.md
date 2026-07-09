# Attribute-based criterion templates

Criterion constructors for case-level attributes, covering the common
measurement scales. Each builds a measure from a named attribute of the
`traces` object.

## Usage

``` r
crit_nominal(attribute, weight = 1, name = attribute)

crit_ordinal(
  attribute,
  levels,
  weight = 1,
  indifference = q(0.5),
  similarity = q(0.2),
  veto = NULL,
  name = attribute
)

crit_numeric(
  attribute,
  weight = 1,
  transform = identity,
  indifference = q(0.5),
  similarity = q(0.2),
  veto = NULL,
  name = attribute
)
```

## Arguments

- attribute:

  Name of a case attribute carried by the `traces` object.

- weight:

  A single positive weight.

- name:

  Criterion label; defaults to the attribute name.

- levels:

  For `crit_ordinal()`, the attribute values from lowest to highest
  rank.

- indifference, similarity, veto:

  Thresholds; a number or a
  [`q()`](https://pdelias.github.io/simOutrank/reference/q.md)
  specification. Defaults suit the direction and are overridable.

- transform:

  For `crit_numeric()`, a function applied to the numeric attribute
  before differencing (e.g. `log`); defaults to
  [`identity()`](https://rdrr.io/r/base/identity.html).

## Value

A
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
object.

## Details

- `crit_nominal()` scores a pair 1 when the attribute is equal and 0
  otherwise (similarity direction; thresholds preset, no veto).

- `crit_ordinal()` uses the absolute rank difference `|rank_a - rank_b|`
  over the ordered `levels` (dissimilarity direction); it covers Likert
  scales.

- `crit_numeric()` uses `|x_a - x_b|` after an optional `transform`
  (dissimilarity direction); it covers quantitative, interval and
  percentage scales.

## See also

[`crit_activity_profile()`](https://pdelias.github.io/simOutrank/reference/crit_process.md)
and the other process-aware helpers.

## Examples

``` r
crit_nominal("status", weight = 0.3)
#> <criterion 'status'>: direction = similarity, weight = 0.3
#>   indifference = 0, similarity = 1, veto = none
crit_ordinal("triage", levels = c("green", "yellow", "red"), weight = 0.2)
#> <criterion 'triage'>: direction = dissimilarity, weight = 0.2
#>   indifference = q(0.5), similarity = q(0.2), veto = none
crit_numeric("age", weight = 0.2, transform = identity)
#> <criterion 'age'>: direction = dissimilarity, weight = 0.2
#>   indifference = q(0.5), similarity = q(0.2), veto = none
```
