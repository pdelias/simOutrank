# Join cluster memberships onto an event log

`augment_log()` adds a `.cluster` column to an event log, mapping every
event to the cluster of its case.

## Usage

``` r
augment_log(clust, log)
```

## Arguments

- clust:

  An `outrank_clust` object from
  [`cluster_traces()`](https://pdelias.github.io/simOutrank/reference/cluster_traces.md).

- log:

  The event-log `data.frame` the clustering came from.

## Value

`log` with an added integer `.cluster` column (`NA` for cases absent
from the clustering, e.g. trimmed outliers).

## Details

The case-id column is detected as the column of `log` whose values cover
all clustered case ids; a message reports which column was used.

## Examples

``` r
log <- data.frame(case = rep(c("a", "b", "c", "d"), each = 2),
                  act = rep(c("x", "y"), 4),
                  ts = as.POSIXct("2020-01-01") + (0:7) * 60)
m <- matrix(0.1, 4, 4); m[1:2, 1:2] <- 0.9; m[3:4, 3:4] <- 0.9
diag(m) <- 1; dimnames(m) <- list(c("a", "b", "c", "d"), c("a", "b", "c", "d"))
crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
tr <- as_traces(log, "case", "act", "ts")
clust <- cluster_traces(outrank_similarity(tr, crit), k = 2, seed = 1)
augment_log(clust, log)
#> Joining on case-id column 'case'.
#>   case act                  ts .cluster
#> 1    a   x 2020-01-01 00:00:00        1
#> 2    a   y 2020-01-01 00:01:00        1
#> 3    b   x 2020-01-01 00:02:00        1
#> 4    b   y 2020-01-01 00:03:00        1
#> 5    c   x 2020-01-01 00:04:00        2
#> 6    c   y 2020-01-01 00:05:00        2
#> 7    d   x 2020-01-01 00:06:00        2
#> 8    d   y 2020-01-01 00:07:00        2
```
