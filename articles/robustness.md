# Robustness: constraints and trimming

A decision maker rarely accepts a clustering as-is. `simOutrank` lets
them inject domain knowledge through **pairwise constraints** and remove
uninformative cases by **trimming**. This vignette follows Runs 2 and 3
of Delias et al. (2021) on the bundled `illustrative_log`.

``` r

traces <- as_traces(illustrative_log, "case_id", "activity", "timestamp")
criteria <- list(
  crit_activity_profile(weight = 0.2, indifference = 0.7, similarity = 0.8,
                        veto = 0.4),
  crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3, veto = 6),
  crit_nominal("status", weight = 0.3),
  crit_nominal("satisfaction", weight = 0.3)
)
sim <- outrank_similarity(traces, criteria)
run1 <- cluster_traces(sim, k = 4, seed = 42)$memberships
```

In Run 1, some Gold customers who follow the long path share a cluster
with Blue customers:

``` r

split(names(run1), run1)
#> $`1`
#> [1] "B6"  "B7"  "B8"  "B9"  "B10" "B11" "B12" "B13"
#> 
#> $`2`
#> [1] "G1"  "G2"  "G3"  "G4"  "G5"  "G11"
#> 
#> $`3`
#> [1] "G6"  "G7"  "G8"  "G9"  "G10"
#> 
#> $`4`
#> [1] "B1"  "B2"  "B3"  "B4"  "B5"  "B14"
```

## Run 2: cannot-link the tiers

The DM decides that “Gold” and “Blue” customers should never share a
cluster.
[`cannot_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md)
severs the credibility of every mixed-tier pair (`S <- S * (1 - M)`).
Passing an attribute name applies the constraint to all pairs whose
values differ.

``` r

sim2 <- cannot_link(sim, "status")
run2 <- cluster_traces(sim2, k = 4, seed = 42)$memberships
split(names(run2), run2)
#> $`1`
#> [1] "B6"  "B7"  "B8"  "B9"  "B10" "B11" "B12" "B13"
#> 
#> $`2`
#> [1] "G1"  "G2"  "G3"  "G4"  "G5"  "G11"
#> 
#> $`3`
#> [1] "G6"  "G7"  "G8"  "G9"  "G10"
#> 
#> $`4`
#> [1] "B1"  "B2"  "B3"  "B4"  "B5"  "B14"
```

Now no cluster mixes tiers:

``` r

status <- illustrative_log$status[match(names(run2), illustrative_log$case_id)]
table(cluster = run2, status = status)
#>        status
#> cluster Blue Gold
#>       1    8    0
#>       2    0    6
#>       3    0    5
#>       4    6    0
```

The complementary operation,
[`must_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md),
rewards pairs that should stay together (`S <- min(S + reward * M, 1)`),
and likewise accepts either a matrix of case-id pairs or an attribute
name.

``` r

sim_ml <- must_link(sim, cbind("B14", "G11"), reward = 2)
sim_ml$S["B14", "G11"]
#> [1] 1
```

## Run 3: trim outliers

The two outliers dilute the clustering.
[`trim_outliers()`](https://pdelias.github.io/simOutrank/reference/trim_outliers.md)
scores each case by its total similarity to the others and removes the
least-connected ones. The genuine low-similarity case is flagged first:

``` r

trimmed <- trim_outliers(sim, prop = 0.04)   # remove floor(0.04 * 25) = 1 case
attr(trimmed, "trimmed")
#> [1] "B14"
```

`B14`, whose `A, B, E` flow matches neither tier, has the lowest
connectivity and is removed. (The paper additionally trims `G11` by
domain judgement; under this weighting `G11` shares its tier and
satisfaction with many cases and is not flagged automatically – a good
illustration of why trimming is offered as a tool, not an oracle.) For
small logs the exact integer program is also available:

``` r

identical(attr(trim_outliers(sim, prop = 0.04, method = "lp"), "trimmed"),
          attr(trim_outliers(sim, prop = 0.04, method = "greedy"), "trimmed"))
#> [1] TRUE
```

Clustering the trimmed matrix gives cleaner groups:

``` r

run3 <- cluster_traces(trimmed, k = 4, seed = 42)$memberships
split(names(run3), run3)
#> $`1`
#> [1] "G1"  "G2"  "G3"  "G4"  "G5"  "G6"  "G7"  "G8"  "G11"
#> 
#> $`2`
#> [1] "B6"  "B7"  "B8"  "B9"  "B10" "B11"
#> 
#> $`3`
#> [1] "G9"  "G10" "B12" "B13"
#> 
#> $`4`
#> [1] "B1" "B2" "B3" "B4" "B5"
```

## Putting it together

Constraints and trimming compose: trim first, then constrain (or the
reverse), and cluster the adjusted matrix.

``` r

final <- cluster_traces(cannot_link(trimmed, "status"), k = 4, seed = 42)
if (requireNamespace("clValid", quietly = TRUE)) validate_clusters(final)
#> connectivity         dunn 
#>   17.9928571    0.6666667
```

## Reference

Delias, P., Doumpos, M., Manthou, V. and Grigoroudis, E. (2021).
Improving the non-compensatory trace clustering. *International
Transactions in Operational Research*. \`\`\`
