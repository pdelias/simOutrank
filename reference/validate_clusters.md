# Internal cluster validity indices

`validate_clusters()` reports the connectivity and Dunn index of a
clustering, computed on the dissimilarity `as.dist(1 - S)`.

## Usage

``` r
validate_clusters(clust)
```

## Arguments

- clust:

  An `outrank_clust` object from
  [`cluster_traces()`](https://pdelias.github.io/simOutrank/reference/cluster_traces.md).

## Value

A named numeric vector with `connectivity` and `dunn`.

## Details

Connectivity (to be minimised) and the Dunn index (to be maximised) are
obtained from the clValid package. If clValid is not installed, the
function returns `NA` values with an informative message.

## Examples

``` r
m <- matrix(0.1, 6, 6); m[1:3, 1:3] <- 0.9; m[4:6, 4:6] <- 0.9
diag(m) <- 1; dimnames(m) <- list(1:6, 1:6)
crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
tr <- as_traces(data.frame(case = as.character(1:6), act = "x",
                           ts = as.POSIXct("2020-01-01")),
                "case", "act", "ts")
clust <- cluster_traces(outrank_similarity(tr, crit), k = 2, seed = 1)
validate_clusters(clust)
#> connectivity         dunn 
#>           NA           13 
```
