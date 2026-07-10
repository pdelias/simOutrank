# Robustness: constraints and trimming

A decision maker rarely accepts a clustering as-is. `simOutrank` lets
them inject domain knowledge through **pairwise constraints** and remove
uninformative cases by **trimming**. This vignette follows Runs 2 and 3
of Delias et al. (2023) on the bundled `illustrative_log`.

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

Each Run-1 cluster already contains a single tier: with these criteria
and the corrected normalisation, `simOutrank` separates `GOLD` from
`NORMAL` without any constraint. (The paper’s original Run 1, under a
different normalisation, mixed some long-path GOLD customers with NORMAL
ones.)

``` r

tier <- illustrative_log$status[match(names(run1), illustrative_log$case_id)]
table(cluster = run1, tier = tier)
#>        tier
#> cluster GOLD NORMAL
#>       1    0      8
#>       2    6      0
#>       3    5      0
#>       4    0      6
```

## Run 2: cannot-link the tiers

Even when the base clustering separates the tiers, a decision maker may
want to *guarantee* it.
[`cannot_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md)
severs the credibility of every mixed-tier pair (`S <- S * (1 - M)`);
passing an attribute name applies the constraint to all pairs whose
values differ.

``` r

sim$S["1", "11"]                     # a GOLD-NORMAL pair, before
#> [1] 0
sim2 <- cannot_link(sim, "status")
sim2$S["1", "11"]                    # severed to 0
#> [1] 0
run2 <- cluster_traces(sim2, k = 4, seed = 42)$memberships
table(cluster = run2,
      tier = illustrative_log$status[match(names(run2), illustrative_log$case_id)])
#>        tier
#> cluster GOLD NORMAL
#>       1    0      8
#>       2    6      0
#>       3    5      0
#>       4    0      6
```

The complementary operation,
[`must_link()`](https://pdelias.github.io/simOutrank/reference/constraints.md),
rewards pairs that should stay together (`S <- min(S + reward * M, 1)`),
and likewise accepts either a matrix of case-id pairs or an attribute
name.

``` r

sim_ml <- must_link(sim, cbind("24", "25"), reward = 2)   # the two outliers
sim_ml$S["24", "25"]
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
#> [1] "24"
```

Case `24`, whose `A, B, E` flow matches neither tier, has the lowest
connectivity and is removed. (The paper additionally trims case `25` by
domain judgement; under this weighting `25` shares its tier and
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
#> [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "25"
#> 
#> $`2`
#> [1] "16" "17" "18" "19" "20" "21"
#> 
#> $`3`
#> [1] "9"  "10" "22" "23"
#> 
#> $`4`
#> [1] "11" "12" "13" "14" "15"
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

Delias, P., Doumpos, M., Grigoroudis, E. and Matsatsinis, N. (2023).
Improving the non-compensatory trace-clustering decision process.
*International Transactions in Operational Research*, 30(3), 1387–1406.
<doi:10.1111/itor.13062> \`\`\`
