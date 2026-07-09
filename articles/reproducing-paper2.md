# Reproducing the illustrative example

This vignette reproduces the illustrative example of Delias et
al. (2021), “Improving the non-compensatory trace clustering”. The log
ships with the package as `illustrative_log`.

## The scenario

A service desk handles two customer tiers, “Gold” and “Blue”, each with
its own process flow, and records each customer’s satisfaction. There
are 25 fictitious customers (Table 1 of the paper); two of them, `B14`
and `G11`, are deliberate outliers whose flow does not fit either tier.

``` r

traces <- as_traces(illustrative_log, "case_id", "activity", "timestamp")
table(illustrative_log$status[!duplicated(illustrative_log$case_id)],
      illustrative_log$satisfaction[!duplicated(illustrative_log$case_id)])
#>       
#>        HIGH LOW
#>   Blue   12   2
#>   Gold    9   2
```

## The criteria (Table 2)

The paper defines four criteria with the following parameters. “Status”
and “Satisfaction” are binary criteria; a veto of -1 in the paper means
“no veto”, which we express as `veto = NULL`.

| Criterion                   | Direction     | Similarity | Indifference | Veto | Weight |
|-----------------------------|---------------|-----------:|-------------:|-----:|-------:|
| Activities                  | similarity    |        0.8 |          0.7 |  0.4 |    0.2 |
| Transitions (edit distance) | dissimilarity |          2 |            3 |    6 |    0.2 |
| Status                      | similarity    |          1 |            0 |    – |    0.3 |
| Satisfaction                | similarity    |          1 |            0 |    – |    0.3 |

``` r

criteria <- list(
  crit_activity_profile(weight = 0.2, indifference = 0.7, similarity = 0.8,
                        veto = 0.4),
  crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3, veto = 6),
  crit_nominal("status", weight = 0.3),
  crit_nominal("satisfaction", weight = 0.3)
)
sim <- outrank_similarity(traces, criteria)
sim
#> <outrank_sim>: 25 cases, 4 criteria
#>   S in [0.000, 1.000], symmetric = TRUE
```

Cases that share the same trace, tier and satisfaction are fully similar
under every criterion, so their credibility is exactly 1:

``` r

sim$S[c("G1", "G2", "G3"), c("G1", "G2", "G3")]
#>    G1 G2 G3
#> G1  1  1  1
#> G2  1  1  1
#> G3  1  1  1
```

## Run 1: clustering without domain knowledge

The paper targets four clusters (tier x satisfaction). This is the
baseline “Run 1”, with no constraints or trimming.

``` r

clust <- cluster_traces(sim, k = 4, seed = 42)
split(names(clust$memberships), clust$memberships)
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

The clusters recover the main structure of the process: cases with an
identical profile always land together, the two satisfaction levels are
largely separated, and the short-path Gold customers form their own
group.

## A note on exact reproduction

The paper reports its memberships as a shaded figure (Table 3) rather
than as a table, so they are not machine-readable here. `simOutrank`
also standardises on the corrected Ng-Jordan-Weiss row normalisation
(see
[`?cluster_traces`](https://pdelias.github.io/simOutrank/reference/cluster_traces.md)),
which can differ from the normalisation used to produce the original
figure. We therefore reproduce the *pipeline and its structural
conclusions* rather than a bit-for-bit membership vector; the
credibility matrix `S` itself is pinned as a regression fixture in the
package’s tests.

Runs 2 and 3 of the paper – separating the tiers with a cannot-link
constraint and trimming the outliers – are covered in the [robustness
vignette](https://pdelias.github.io/simOutrank/articles/robustness.md).

## Reference

Delias, P., Doumpos, M., Manthou, V. and Grigoroudis, E. (2021).
Improving the non-compensatory trace clustering. *International
Transactions in Operational Research*. \`\`\`
