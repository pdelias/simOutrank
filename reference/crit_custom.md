# Custom criterion

The escape hatch for criteria that the templates do not cover, including
composite measures (e.g. a linear combination of others). Wraps
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
directly.

## Usage

``` r
crit_custom(
  x,
  direction,
  weight = 1,
  indifference,
  similarity,
  veto = NULL,
  name = "custom"
)
```

## Arguments

- x:

  A `function(traces)` returning a symmetric numeric matrix, or a
  precomputed numeric matrix with case-id dimnames.

- direction:

  `"similarity"` or `"dissimilarity"`.

- weight:

  A single positive weight.

- indifference, similarity:

  Required thresholds (number or
  [`q()`](https://pdelias.github.io/simOutrank/reference/q.md)).

- veto:

  Optional veto threshold.

- name:

  Criterion label.

## Value

A
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
object.

## Examples

``` r
# A criterion on a precomputed similarity matrix.
m <- matrix(c(1, 0.7, 0.7, 1), 2, dimnames = list(c("a", "b"), c("a", "b")))
crit_custom(m, direction = "similarity", weight = 1,
            indifference = 0.4, similarity = 0.9)
#> <criterion 'custom'>: direction = similarity, weight = 1
#>   indifference = 0.4, similarity = 0.9, veto = none
```
