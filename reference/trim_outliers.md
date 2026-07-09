# Trim outlier cases

`trim_outliers()` removes a fraction of the least-connected cases from
an
[`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md)
result, before clustering.

## Usage

``` r
trim_outliers(sim, prop = 0.05, method = c("greedy", "lp"), lp_max = 150L)
```

## Arguments

- sim:

  An `outrank_sim` object from
  [`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md).

- prop:

  Fraction of cases to remove (in `[0, 1)`).

- method:

  `"greedy"` (default) or `"lp"`.

- lp_max:

  Size above which the `"lp"` method warns about its cost.

## Value

A trimmed `outrank_sim`, with a `trimmed` attribute giving the removed
case ids.

## Details

Let `k = floor(prop * n)`. The `"greedy"` method removes the `k` cases
with the smallest total similarity to the others (row sums of `S` with
the diagonal excluded). The `"lp"` method solves the integer linear
program of Delias et al. (2021), \$\$\min\_{o, r} \sum\_{i,j} s\_{ij}
r\_{ij} \quad \text{s.t.} \quad \sum_i o_i = k,\\ o_i \le r\_{ij},\\ o_i
\le r\_{ji},\\ o, r \in \\0, 1\\,\$\$ which selects the `k` cases whose
incident edges carry the least similarity. A small constant is added to
`S` so that zero entries do not leave `r` unconstrained. The LP has
`n + n^2` binary variables and is intended for small `n`; it warns above
`lp_max`.

## References

Delias, P. et al. (2021). Improving the non-compensatory trace
clustering. *International Transactions in Operational Research*.

## Examples

``` r
m <- matrix(0.8, 5, 5); m[5, ] <- 0.05; m[, 5] <- 0.05; diag(m) <- 1
dimnames(m) <- list(1:5, 1:5)
crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.9)
tr <- as_traces(data.frame(case = as.character(1:5), act = "x",
                           ts = as.POSIXct("2020-01-01")),
                "case", "act", "ts")
sim <- outrank_similarity(tr, crit)
trim_outliers(sim, prop = 0.2)
#> <outrank_sim>: 4 cases, 1 criteria
#>   S in [0.833, 1.000], symmetric = TRUE
```
