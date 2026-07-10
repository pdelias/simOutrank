# Reproducing the emergency-room study (foundations paper)

> **Data note.** The foundations paper (Delias et al., 2019, *A
> non-compensatory approach for trace clustering*) uses a real
> emergency-room (ER) log that is not redistributable. This article
> reproduces the *modelling recipe* on a synthetic ER-like log with the
> same structure, and shows exactly how to swap in the real data. It is
> a pkgdown article, not a CRAN vignette, so it may use heavier data
> than the built vignettes.

## A synthetic ER log

The study clusters emergency-room patient traces on multiple
perspectives: which activities occur, their order, the triage colour
(ordinal), the case type and shift (nominal), and the duration. We
synthesise three archetypes – a fast track, a moderate path, and a
critical path – with noise.

``` r

archetypes <- list(
  fast     = c("Arrival", "Triage", "Exam", "Discharge"),
  moderate = c("Arrival", "Triage", "Exam", "BloodTest", "BloodResult",
               "Decision", "Discharge"),
  critical = c("Arrival", "Triage", "Exam", "XRay", "XRayResult", "BloodTest",
               "BloodResult", "RoomEntrance", "RoomExit", "Discharge")
)
triage_of <- c(fast = "green", moderate = "yellow", critical = "red")

make_case <- function(id, kind) {
  acts <- archetypes[[kind]]
  if (runif(1) < 0.2 && length(acts) > 4)         # a little structural noise
    acts <- acts[-sample(seq(3, length(acts) - 1), 1)]
  n <- length(acts)
  step <- switch(kind, fast = 15, moderate = 40, critical = 90)
  data.frame(
    case_id   = id,
    activity  = acts,
    timestamp = as.POSIXct("2017-01-01", tz = "UTC") +
                cumsum(c(0, round(rexp(n - 1, 1 / step)))) * 60,
    triage    = unname(triage_of[kind]),
    type      = sample(c("medical", "surgical"), 1),
    shift     = sample(c("day", "night"), 1),
    stringsAsFactors = FALSE
  )
}

kinds <- rep(c("fast", "moderate", "critical"), times = c(18, 15, 12))
er_log <- do.call(rbind, Map(make_case, sprintf("P%02d", seq_along(kinds)),
                             kinds))
traces <- as_traces(er_log, "case_id", "activity", "timestamp")
#> Warning: Tied timestamps within a case were ordered by original row order.
traces
#> <traces>: 45 cases, 11 distinct activities
#>   trace length: min 4, median 6, max 10
#>   case attributes: triage, type, shift
```

## Criteria across perspectives

The `crit_*` helpers cover every scale the study uses. Triage is ordinal
(green \< yellow \< red); type and shift are nominal; duration is
quantitative.

``` r

criteria <- list(
  crit_activity_profile(weight = 21),
  crit_edit_distance(weight = 23, similarity = 2, indifference = 4, veto = 8),
  crit_ordinal("triage", levels = c("green", "yellow", "red"), weight = 16,
               similarity = 0, indifference = 1.5, veto = 2.5),
  crit_nominal("type", weight = 3),
  crit_nominal("shift", weight = 16),
  crit_duration("mins", weight = 12, similarity = as_quantile(0.2),
                indifference = as_quantile(0.6))
)
sim <- outrank_similarity(traces, criteria)
#> Criterion weights normalised to sum to 1 (were 91).
sim
#> <outrank_sim>: 45 cases, 6 criteria
#>   S in [0.000, 1.000], symmetric = TRUE
```

Composite criteria from the paper (for example *Flow = Levenshtein - 14
x transition similarity*) are expressed with
[`crit_custom()`](https://pdelias.github.io/simOutrank/reference/crit_custom.md)
and a user function of `traces`; here we keep the perspectives separate
for clarity.

## Three clusters

The paper reports a three-cluster solution. Spectral clustering recovers
the archetypes:

``` r

clust <- cluster_traces(sim, k = 3, seed = 100)
table(cluster = clust$memberships,
      triage  = er_log$triage[match(names(clust$memberships), er_log$case_id)])
#>        triage
#> cluster green red yellow
#>       1    18   0      0
#>       2     0  12      0
#>       3     0   0     15
```

Each cluster is dominated by one triage colour – the
fast/moderate/critical structure the synthetic log was built from,
recovered without ever telling the algorithm the triage.

## Swapping in the real ER log

With the real CSV, only the ingestion changes; the criteria and
clustering are identical.

``` r

raw <- read.csv("Filter1_MergedPatientsLog.csv")
traces <- as_traces(raw,
                    case_id   = "Case.ID",
                    activity  = "Activity",
                    timestamp = "Complete.Timestamp")
# ...then the same `criteria` and `cluster_traces(sim, k = 3)` as above.
```

## Reference

Delias, P., Doumpos, M., Grigoroudis, E. and Matsatsinis, N. (2019). A
non-compensatory approach for trace clustering. *International
Transactions in Operational Research*, 26(5), 1828–1846.
<doi:10.1111/itor.12395> \`\`\`
