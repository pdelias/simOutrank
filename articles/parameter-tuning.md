# Parameter tuning and sensitivity

An outranking model has three tuning surfaces: the **thresholds** of
each criterion, the **weights** between criteria, and the **number of
clusters** `k`. A good analysis checks that its conclusions are not an
artefact of a single arbitrary choice. This vignette shows how, using
`illustrative_log`.

``` r

traces <- as_traces(illustrative_log, "case_id", "activity", "timestamp")

criteria <- function(activity_sim = 0.8, activity_indiff = 0.7,
                     w_activity = 0.2) {
  list(
    crit_activity_profile(weight = w_activity, indifference = activity_indiff,
                          similarity = activity_sim, veto = 0.4),
    crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3,
                       veto = 6),
    crit_nominal("status", weight = 0.3),
    crit_nominal("satisfaction", weight = 0.3)
  )
}
```

We compare clusterings with the Rand index (the fraction of case pairs
that two partitions agree to keep together or apart):

``` r

rand_index <- function(a, b) {
  agree <- 0L; n <- length(a)
  for (i in seq_len(n - 1L)) for (j in (i + 1L):n) {
    agree <- agree + ((a[i] == a[j]) == (b[i] == b[j]))
  }
  agree / choose(n, 2)
}

baseline <- cluster_traces(outrank_similarity(traces, criteria()),
                           k = 4, seed = 42)$memberships
```

## Fixed vs quantile thresholds

A threshold can be a fixed number or a quantile of the criterion’s own
value distribution, written `q(p)`. Quantiles adapt to the data, which
is useful when you do not have a natural scale.

``` r

crit_fixed    <- crit_activity_profile(0.2, indifference = 0.7, similarity = 0.8)
crit_quantile <- crit_activity_profile(0.2, indifference = q(0.5),
                                       similarity = q(0.8))
crit_quantile
#> <criterion 'activity_profile'>: direction = similarity, weight = 0.2
#>   indifference = q(0.5), similarity = q(0.8), veto = none
```

## Threshold sensitivity

Sweep the activity-similarity threshold and measure both the average
credibility and the agreement of the resulting clustering with the
baseline.

``` r

grid <- seq(0.75, 0.95, by = 0.05)  # kept above the indifference of 0.70
sens <- t(vapply(grid, function(s) {
  sim <- outrank_similarity(traces, criteria(activity_sim = s))
  memb <- cluster_traces(sim, k = 4, seed = 42)$memberships
  c(mean_S = mean(sim$S[upper.tri(sim$S)]),
    rand   = rand_index(memb, baseline))
}, numeric(2)))
data.frame(similarity = grid, sens)
#>   similarity    mean_S   rand.G1
#> 1       0.75 0.4959126 0.9633333
#> 2       0.80 0.4885674 1.0000000
#> 3       0.85 0.4765922 1.0000000
#> 4       0.90 0.4643035 1.0000000
#> 5       0.95 0.4566253 1.0000000
```

The Rand index stays high across the sweep: the four-cluster solution is
not an artefact of one threshold choice.

## Weight sensitivity

Do the same for the weight of the activities criterion, from negligible
to dominant (weights are renormalised internally).

``` r

weights <- c(0.05, 0.2, 0.5, 1)
w_sens <- vapply(weights, function(w) {
  sim <- suppressMessages(outrank_similarity(traces,
                                             criteria(w_activity = w)))
  rand_index(cluster_traces(sim, k = 4, seed = 42)$memberships, baseline)
}, numeric(1))
data.frame(w_activity = weights, rand = w_sens)
#>   w_activity      rand
#> 1       0.05 0.9633333
#> 2       0.20 1.0000000
#> 3       0.50 0.8666667
#> 4       1.00 0.8666667
```

## Choosing k

[`eigengap()`](https://pdelias.github.io/simOutrank/reference/eigengap.md)
guides `k` from the spectrum of the normalized Laplacian; the gap after
the k-th eigenvalue marks a natural cut.

``` r

sim <- outrank_similarity(traces, criteria())
gaps <- eigengap(sim, k_max = 8)
```

![](parameter-tuning_files/figure-html/eigengap-1.png)

``` r

gaps[which.max(gaps$gap), ]
#>   index eigenvalue       gap
#> 2     2  0.3620242 0.5170718
```

Pair the diagnostic with a validity index across candidate `k` when is
available:

``` r

if (requireNamespace("clValid", quietly = TRUE)) {
  t(vapply(2:6, function(k) {
    cl <- cluster_traces(sim, k = k, seed = 42)
    c(k = k, validate_clusters(cl))
  }, numeric(3)))
}
#>      k connectivity      dunn
#> [1,] 2     1.317857 0.3881421
#> [2,] 3     9.033730 0.4285714
#> [3,] 4    20.276190 0.4891980
#> [4,] 5    25.589683 0.4000000
#> [5,] 6    29.134127 0.0000000
```

## Takeaway

Report the sweep, not a point estimate. When the Rand index stays high
and a validity index agrees with the eigengap, the clustering is robust
to the inevitable arbitrariness of the parameters. \`\`\`
