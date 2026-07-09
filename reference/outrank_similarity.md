# Outranking credibility matrix

`outrank_similarity()` aggregates a set of criteria into the ELECTRE-III
credibility matrix `S`, the pairwise similarity used for clustering.

## Usage

``` r
outrank_similarity(traces, criteria, keep_partials = FALSE)
```

## Arguments

- traces:

  A `traces` object (see
  [`as_traces()`](https://pdelias.github.io/simOutrank/reference/as_traces.md));
  defines the case set and their order.

- criteria:

  A
  [`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)
  object, or a non-empty list of them.

- keep_partials:

  If `TRUE`, retain the per-criterion measure, concordance and
  discordance matrices for inspection.

## Value

An object of class `outrank_sim`: a list with the credibility matrix
`S`, the aggregate concordance `C` and discordance `D`, the case ids,
the resolved criteria with normalised weights, and (optionally) the
partial matrices.

## Details

Each criterion contributes a partial concordance `c_j` and discordance
`d_j` (see
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)).
With weights `w_j` normalised to sum to one, the aggregation is \$\$C(a,
b) = \sum_j w_j\\ c_j(a, b),\$\$ \$\$D(a, b) = 1 - \prod\_{j \in J(a,b)}
\frac{1 - d_j}{1 - c_j}, \quad J(a,b) = \\ j : d_j(a,b) \> c_j(a,b)
\\,\$\$ \$\$S(a, b) = \min\bigl(C(a, b),\\ 1 - D(a, b)\bigr).\$\$ A
criterion with `c_j = 1` is never in `J` (concordance is already
maximal), which also avoids the division by `1 - c_j`.

Quantile thresholds
([`q()`](https://pdelias.github.io/simOutrank/reference/q.md)) are
resolved against the off-diagonal distribution of each criterion's own
measure matrix before the indices are computed. Weights are normalised
to sum to one, with a message when they did not already.

## Examples

``` r
log <- data.frame(
  case = rep(c("a", "b", "c"), each = 2),
  act  = c("x", "y", "x", "y", "x", "x"),
  ts   = as.POSIXct("2020-01-01") + c(0, 1, 0, 1, 0, 1) * 60
)
tr <- as_traces(log, "case", "act", "ts")
# A criterion on a precomputed similarity matrix (crit_* helpers wrap this).
m <- matrix(c(1, 0.8, 0.2, 0.8, 1, 0.3, 0.2, 0.3, 1), 3, 3,
            dimnames = list(c("a", "b", "c"), c("a", "b", "c")))
crit <- criterion(m, direction = "similarity",
                  indifference = 0.4, similarity = 0.9, veto = 0.1)
outrank_similarity(tr, crit)
#> <outrank_sim>: 3 cases, 1 criteria
#>   S in [0.000, 1.000], symmetric = TRUE
```
