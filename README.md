# simOutrank

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/simOutrank)](https://CRAN.R-project.org/package=simOutrank)
[![R-CMD-check](https://github.com/pdelias/simOutrank/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pdelias/simOutrank/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**Outranking-based trace clustering for process mining.**

`simOutrank` clusters the traces of an event log by an *outranking* model of
similarity. Instead of collapsing every perspective into one distance, it scores
each pair of traces on several problem-specific criteria — activities,
transitions, duration, case attributes — and aggregates them with
ELECTRE-III-style concordance and discordance (indifference, similarity and veto
thresholds). The resulting credibility matrix is partitioned by normalized
spectral or hierarchical clustering, with optional outlier trimming and
must-link / cannot-link constraints.

## Installation

Install the released version from CRAN:

```r
install.packages("simOutrank")
```

Or the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("pdelias/simOutrank")
```

## A 20-line example

```r
library(simOutrank)

# 1. An event log -> a traces object (bundled illustrative log, 25 cases).
traces <- as_traces(illustrative_log,
                    case_id = "case_id", activity = "activity",
                    timestamp = "timestamp")

# 2. Criteria over several perspectives (weights normalised internally).
criteria <- list(
  crit_activity_profile(weight = 0.2, indifference = 0.7, similarity = 0.8,
                        veto = 0.4),
  crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3, veto = 6),
  crit_nominal("status", weight = 0.3),
  crit_nominal("satisfaction", weight = 0.3)
)

# 3. Aggregate to a credibility matrix, choose k, and cluster.
sim   <- outrank_similarity(traces, criteria)
eigengap(sim, k_max = 8)                       # how many clusters?
clust <- cluster_traces(sim, k = 4, seed = 42)
split(names(clust$memberships), clust$memberships)
```

## Learn more

* **Getting started** — the full pipeline, step by step.
* **Reproducing the illustrative example** and **Robustness** — reproduce the
  published results, then inject domain knowledge and trim outliers.
* **Parameter tuning** — thresholds, weights and `k`, with sensitivity sweeps.

See `browseVignettes("simOutrank")` or the [package
website](https://pdelias.github.io/simOutrank/) for these, plus website-only
articles that reproduce the emergency-room study and cluster a large log.

## Reference

* Delias, P., Doumpos, M., Grigoroudis, E. and Matsatsinis, N. (2019). A
  non-compensatory approach for trace clustering. *International Transactions in
  Operational Research*, 26(5), 1828–1846.
  doi:10.1111/itor.12395
* Delias, P., Doumpos, M., Grigoroudis, E. and Matsatsinis, N. (2023). Improving
  the non-compensatory trace-clustering decision process. *International
  Transactions in Operational Research*, 30(3), 1387–1406.
  doi:10.1111/itor.13062

Design and roadmap:
[`design/DESIGN.md`](https://github.com/pdelias/simOutrank/blob/main/design/DESIGN.md).
