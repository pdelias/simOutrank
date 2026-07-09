# Cluster traces from a credibility matrix

`cluster_traces()` partitions the cases of an
[`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md)
result into `k` groups, by normalized spectral clustering or
hierarchical clustering.

## Usage

``` r
cluster_traces(
  sim,
  k,
  method = c("spectral", "hierarchical"),
  nstart = 100,
  seed = NULL,
  hclust_method = "ward.D2"
)
```

## Arguments

- sim:

  An `outrank_sim` object from
  [`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md).

- k:

  Number of clusters (an integer, `2 <= k <= n`).

- method:

  `"spectral"` (default) or `"hierarchical"`.

- nstart:

  Number of k-means restarts for the spectral method.

- seed:

  Optional integer seed for the k-means randomness; set it for
  reproducible spectral memberships. The global RNG state is restored on
  exit.

- hclust_method:

  Linkage for the hierarchical method; passed to
  [`stats::hclust()`](https://rdrr.io/r/stats/hclust.html). Defaults to
  `"ward.D2"`.

## Value

An object of class `outrank_clust`: a list with the integer
`memberships` (named by case id), `k`, `method`, the `sim` object, the
Laplacian `eigenvalues` (spectral only), and the `hclust` tree
(hierarchical only).

## Details

Spectral clustering follows Ng, Jordan and Weiss (2002). With the
affinity `S` (diagonal zeroed) and `D = diag(rowSums(S))`, it forms the
symmetric normalized Laplacian \\L\_{sym} = I - D^{-1/2} S D^{-1/2}\\,
takes the eigenvectors of its `k` smallest eigenvalues, normalises each
row to unit length, and runs k-means (with `nstart` restarts) on the
result.

Hierarchical clustering runs
[`stats::hclust()`](https://rdrr.io/r/stats/hclust.html) on the
dissimilarity `as.dist(1 - S)` and cuts the tree at `k` groups.

## References

Ng, A., Jordan, M. and Weiss, Y. (2002). On spectral clustering:
analysis and an algorithm. *NIPS*.

## Examples

``` r
m <- matrix(c(1, 0.9, 0.1, 0.1,
              0.9, 1, 0.1, 0.1,
              0.1, 0.1, 1, 0.9,
              0.1, 0.1, 0.9, 1), 4, 4,
            dimnames = list(1:4, 1:4))
crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
tr <- as_traces(
  data.frame(case = as.character(1:4), act = "x",
             ts = as.POSIXct("2020-01-01")),
  "case", "act", "ts"
)
sim <- outrank_similarity(tr, crit)
cluster_traces(sim, k = 2, seed = 1)
#> <outrank_clust>: 4 cases in 2 clusters (spectral)
#>   cluster sizes: 1=2, 2=2 
```
