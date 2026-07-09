# Clustering a large event log

The credibility matrix `S` is dense and `n x n`, so `simOutrank` is
designed for logs of hundreds to a few thousand cases – the regime of
most trace clustering studies. This article measures the pipeline on a
synthetic 500-case log and points at a real large log (BPIC’11).

## A synthetic 500-case log

``` r

templates <- list(
  a = c("register", "triage", "consult", "discharge"),
  b = c("register", "triage", "consult", "lab", "result", "discharge"),
  c = c("register", "triage", "consult", "imaging", "result", "admit",
        "discharge"),
  d = c("register", "consult", "discharge")
)
urgency_of <- c(a = "low", b = "medium", c = "high", d = "low")

make_case <- function(id) {
  kind <- sample(names(templates), 1, prob = c(0.35, 0.3, 0.2, 0.15))
  acts <- templates[[kind]]
  if (runif(1) < 0.25) acts <- c(acts, sample(acts, 1))  # a repeated step
  n <- length(acts)
  data.frame(
    case_id   = id,
    activity  = acts,
    timestamp = as.POSIXct("2011-01-01", tz = "UTC") +
                cumsum(c(0, round(rexp(n - 1, 1 / 30)))) * 60,
    urgency   = unname(urgency_of[kind]),
    stringsAsFactors = FALSE
  )
}

big_log <- do.call(rbind, lapply(sprintf("c%04d", 1:500), make_case))
nrow(big_log)
#> [1] 2606
traces <- as_traces(big_log, "case_id", "activity", "timestamp")
#> Warning: Tied timestamps within a case were ordered by original row order.
traces
#> <traces>: 500 cases, 8 distinct activities
#>   trace length: min 3, median 5, max 8
#>   case attributes: urgency
```

## Timing the pipeline

``` r

criteria <- list(
  crit_activity_profile(weight = 0.4),
  crit_edit_distance(weight = 0.3, similarity = q(0.2), indifference = q(0.5)),
  crit_nominal("urgency", weight = 0.3)
)

t_sim <- system.time(sim <- outrank_similarity(traces, criteria))
t_cl  <- system.time(clust <- cluster_traces(sim, k = 4, seed = 1))
rbind(similarity = t_sim[["elapsed"]], clustering = t_cl[["elapsed"]])
#>             [,1]
#> similarity 0.088
#> clustering 0.104
```

The measures are fully vectorised (no per-pair
[`apply()`](https://rdrr.io/r/base/apply.html)), so 500 cases build `S`
in well under a second on a laptop. Memory, not time, is the practical
ceiling: `S` for `n` cases is `8 * n^2` bytes (about 2 MB at n = 500,
200 MB at n = 5000).

``` r

table(clust$memberships)
#> 
#>   1   2   3   4 
#> 193 145  91  71
eigengap(sim, k_max = 8)
```

![](large-log_files/figure-html/result-1.png)

## Trimming before clustering at scale

On real logs a few disconnected cases can distort the spectrum. Greedy
trimming is `O(n^2)` and always available; the exact integer program is
only advisable for small `n`.

``` r

trimmed <- trim_outliers(sim, prop = 0.05)      # drop the 5% least connected
length(attr(trimmed, "trimmed"))
#> [1] 25
```

## A real large log: BPIC’11

The Business Process Intelligence Challenge 2011 log (a Dutch hospital,
~1150 cases) is the large real dataset of the papers. With it maps
straight into
[`as_traces()`](https://pdelias.github.io/simOutrank/reference/as_traces.md):

``` r

library(bupaR)
# install the data package once: install.packages("eventdataR")
log <- eventdataR::hospital_log            # or read your own XES/CSV
traces <- as_traces(log)                   # bupaR mapping read from the object
sim <- outrank_similarity(traces, list(
  crit_activity_profile(weight = 0.4),
  crit_edit_distance(weight = 0.3),
  crit_trace_length(weight = 0.3)
))
clust <- cluster_traces(sim, k = 7, seed = 1)   # the papers fix k = 7 here
```

For logs beyond a few thousand cases, cluster a representative sample or
pre-aggregate identical traces before building `S`. \`\`\`
