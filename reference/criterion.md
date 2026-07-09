# Define an outranking criterion

`criterion()` is the core constructor behind the `crit_*` helpers; users
rarely call it directly. It bundles a pairwise measure with its
direction, weight and ELECTRE-III-style thresholds.

## Usage

``` r
criterion(
  measure,
  direction = c("similarity", "dissimilarity"),
  weight = 1,
  indifference,
  similarity,
  veto = NULL,
  name = NULL
)
```

## Arguments

- measure:

  Either a `function(traces)` returning a symmetric numeric matrix, or a
  precomputed numeric matrix with dimnames matching the case ids.

- direction:

  One of `"similarity"` (larger values mean more alike) or
  `"dissimilarity"` (smaller values mean more alike).

- weight:

  A single positive number. Weights are normalised to sum to one when
  the credibility matrix is built.

- indifference, similarity:

  Required thresholds; each a single number or a
  [`q()`](https://pdelias.github.io/simOutrank/reference/q.md) quantile
  specification.

- veto:

  Optional veto threshold; a number, a
  [`q()`](https://pdelias.github.io/simOutrank/reference/q.md)
  specification, or `NULL` for no discordance.

- name:

  Optional label used in printing and diagnostics.

## Value

An object of class `criterion`.

## Details

For a criterion with indifference threshold \\q\\, similarity threshold
\\s\\ and (optional) veto threshold \\t\\, and a pairwise value \\v =
g(a, b)\\, the partial concordance and discordance of a
`"similarity"`-direction criterion are \$\$c = 1 \\ \mathrm{if}\\ v \ge
s, \quad c = \frac{v - q}{s - q} \\ \mathrm{if}\\ q \le v \< s, \quad c
= 0 \\ \mathrm{if}\\ v \< q,\$\$ \$\$d = 1 \\ \mathrm{if}\\ v \le t,
\quad d = \frac{q - v}{q - t} \\ \mathrm{if}\\ t \< v \le q, \quad d = 0
\\ \mathrm{if}\\ v \> q.\$\$ For a `"dissimilarity"`-direction criterion
the inequalities reverse. This imposes an ordering on the thresholds,
which the constructor validates: \\t \< q \< s\\ for the similarity
direction and \\s \< q \< t\\ for the dissimilarity direction. A
`veto = NULL` criterion contributes no discordance.

Thresholds may be given as plain numbers or as a quantile specification
[`q()`](https://pdelias.github.io/simOutrank/reference/q.md). Numeric
thresholds are validated immediately; quantile thresholds are resolved
and validated once the measure matrix is known.

## Examples

``` r
# A similarity criterion on a precomputed matrix.
m <- matrix(c(1, 0.4, 0.4, 1), 2, dimnames = list(c("a", "b"), c("a", "b")))
criterion(m, direction = "similarity", weight = 2,
          indifference = 0.5, similarity = 0.8, veto = 0.2)
#> <criterion>: direction = similarity, weight = 2
#>   indifference = 0.5, similarity = 0.8, veto = 0.2
```
