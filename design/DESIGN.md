# simOutrank: Package Design Document

Version 1.0 (design freeze candidate) — 2026-07-08

## 1. Purpose and scope

`simOutrank` implements outranking-based trace clustering for process mining.
Pairwise similarity between traces is assessed on multiple, problem-specific
criteria using ELECTRE-III-style partial concordance and discordance indices
with indifference, similarity and veto thresholds. The aggregated credibility
matrix S is then clustered (normalized spectral clustering or hierarchical
clustering). Version 1 also includes outlier trimming, must-link /
cannot-link adjustments, validation indices and diagnostic plots.

Reference publications: the two papers in the repo (`/papers`), the
foundations paper and the robustness/extensions paper. The regression test
suite reproduces their reported results.

Distribution: GitHub first (`remotes::install_github`), CRAN once the API
stabilises. All CRAN policies respected from the start (no `setwd`, no
writing outside tempdir, examples < 5s, clean `R CMD check`).

## 2. Mathematical core

For each criterion g_j with weight w_j (weights normalised internally so that
sum(w_j) = 1), and each pair of traces (a, b) with pairwise value
v = g_j(a, b):

Partial concordance c_j(a,b), for a similarity-direction criterion with
indifference threshold q_j and similarity threshold s_j (q_j < s_j):

    c_j = 1                     if v >= s_j
    c_j = (v - q_j)/(s_j - q_j) if q_j <= v < s_j
    c_j = 0                     if v < q_j

Partial discordance d_j(a,b), with veto threshold t_j (t_j < q_j):

    d_j = 1                     if v <= t_j
    d_j = (q_j - v)/(q_j - t_j) if t_j < v <= q_j
    d_j = 0                     if v > q_j

For dissimilarity-direction criteria the inequalities reverse (as in the
existing scripts' `increasing = FALSE` branch). A criterion with `veto = NULL`
contributes no discordance (d_j identically 0).

Aggregation:

    C(a,b) = sum_j w_j * c_j(a,b)
    D(a,b) = 1 - prod_{j in J(a,b)} (1 - d_j)/(1 - c_j),
             where J(a,b) = { j : d_j(a,b) > c_j(a,b) }
    S(a,b) = min( C(a,b), 1 - D(a,b) )

Implementation note: all partial indices are computed with vectorised
matrix operations (`pmin`, `pmax`, logical indexing), never
`apply(X, 1:2, f)`. Division by (1 - c_j) requires guarding c_j = 1;
when c_j = 1 the pair is excluded from J (concordance is already maximal,
consistent with the ELECTRE-III convention).

Spectral clustering: normalized spectral clustering after Ng, Jordan and
Weiss (2002). D = diag(rowSums(S)), L_sym = D^{-1/2} (D - S) D^{-1/2},
take the eigenvectors of the k smallest eigenvalues, row-normalise, k-means
with `nstart` >= 100 and a user-settable seed. (Note: the foundations-paper
script used the largest eigenvalues of D^{-1/2} S D^{-1/2}, which is
equivalent; the package standardises on the L_sym formulation from the
enhancements script.)

## 3. Public API

### 3.1 Trace representation

```r
as_traces(x, case_id, activity, timestamp, ...)
```

Generic with methods for `data.frame` and (if bupaR is installed) bupaR
`eventlog` / `activitylog`; the bupaR method reads the mapping from the
object so no column arguments are needed. Returns a `traces` object: a list
with the ordered activity sequence per case, case ids, and the case-level
attribute table (one row per case, first value per case for constant
attributes). Events are ordered by timestamp within case; ties broken by
original row order with a warning. Print and summary methods included.

bupaR sits in `Suggests`; its method is registered conditionally.

### 3.2 Criteria

Core constructor (users rarely call it directly):

```r
criterion(measure, direction = c("similarity", "dissimilarity"),
          weight = 1, indifference, similarity, veto = NULL,
          name = NULL)
```

`measure` is either a `function(traces) -> symmetric numeric matrix` or a
precomputed matrix with dimnames matching case ids. Thresholds accept either
a numeric value or a quantile specification `q(p)` evaluated on the empirical
distribution of the off-diagonal pairwise values of that criterion's matrix.
The validator checks threshold ordering per direction (similarity direction:
veto < indifference < similarity; dissimilarity direction reversed).

Process-aware helpers (measure computed from the traces object):

```r
crit_activity_profile(weight, indifference = q(.5), similarity = q(.8),
                      veto = NULL, ...)      # cosine similarity of activity count vectors
crit_transitions(weight, ...)                # cosine similarity of distance-weighted
                                             # transition profiles (1/gap weighting,
                                             # as in the foundations paper)
crit_edit_distance(weight, method = "osa", ...)   # stringdist on encoded traces
crit_trace_length(weight, ...)               # |n_a - n_b|, dissimilarity
crit_distinct_activities(weight, ...)        # |#unique_a - #unique_b|, dissimilarity
crit_duration(weight, units = "mins", ...)   # |dur_a - dur_b|, dissimilarity
```

Attribute-based scale templates (measure computed from a case attribute):

```r
crit_nominal(attribute, weight, ...)   # 1 if equal, 0 otherwise; thresholds preset
crit_ordinal(attribute, levels, weight, ...)  # |rank_a - rank_b|, dissimilarity;
                                              # covers likert scales
crit_numeric(attribute, weight, transform = identity, ...)  # |x_a - x_b| after
                                              # transform; covers quantitative,
                                              # interval and percentage scales
```

Escape hatch:

```r
crit_custom(x, direction, weight, indifference, similarity, veto = NULL,
            name)   # x: matrix or function(traces) -> matrix
```

Composite criteria (e.g. Flow = Levenshtein - 14 * transition_similarity in
the ER case study) are expressed through `crit_custom` with a user function;
no special composite machinery in v1.

Default thresholds: every helper ships quantile defaults appropriate to its
direction, documented per helper, and always overridable. The vignette shows
a sensitivity check across quantile choices.

### 3.3 Similarity and clustering

```r
outrank_similarity(traces, criteria, keep_partials = FALSE)
```

Returns an `outrank_sim` object wrapping S (and, if requested, the per-
criterion partial index matrices for inspection). Weights are normalised to
sum to one with a message if they do not already.

```r
trim_outliers(sim, prop = 0.05, method = c("greedy", "lp"))
```

Greedy: drop the `prop` fraction of cases with the lowest row sums of S.
LP: the binary program from the extensions paper (via `lpSolve`), documented
as suitable only for small n; the function warns above a size threshold.

```r
must_link(sim, pairs_or_attribute, reward = 2)      # S <- S + reward * M, capped at 1
cannot_link(sim, pairs_or_attribute)                # S <- S * (1 - M) style masking
```

Both accept either a two-column matrix of case-id pairs or the name of a
case attribute whose equality (must-link) or inequality (cannot-link)
defines the constraint set. Exact algebra follows the extensions paper.

```r
cluster_traces(sim, k, method = c("spectral", "hierarchical"),
               nstart = 100, seed = NULL, hclust_method = "ward.D2")
```

Returns `outrank_clust`: memberships, the sim object, method metadata, and
for spectral the Laplacian eigenvalues. Hierarchical uses
`as.dist(1 - S)`.

### 3.4 Diagnostics, validation, plots

```r
eigengap(sim, k_max = 30)          # eigenvalue plot to guide k
validate_clusters(clust)           # connectivity (clValid) and Dunn index
plot(clust, type = c("dendrogram", "eigenvalues", "profile"), attribute = NULL)
augment_log(clust, log)            # join memberships back onto the event log
```

`clValid` in Suggests; validation degrades gracefully with an informative
message if it is absent.

## 4. Package structure

```
simOutrank/
├── DESCRIPTION            # Imports: stringdist, lpSolve; Suggests: bupaR,
│                          # clValid, ggplot2, testthat, knitr, rmarkdown
├── R/
│   ├── traces.R           # as_traces + methods, print/summary
│   ├── criterion.R        # criterion(), q(), validators, threshold resolution
│   ├── crit_process.R     # process-aware helpers
│   ├── crit_attribute.R   # scale-type templates, crit_custom
│   ├── measures.R         # matrix computations (activity profile, transitions,
│   │                      # edit distance, ...) — internal, vectorised
│   ├── outranking.R       # partial indices, aggregation, outrank_similarity
│   ├── outliers.R         # greedy + LP trimming
│   ├── constraints.R      # must_link, cannot_link
│   ├── clustering.R       # spectral + hierarchical, eigengap
│   ├── validation.R       # validate_clusters, augment_log
│   └── plots.R
├── data/                  # small bundled example log (anonymised or synthetic,
│                          # the illustrative log from the extensions paper)
├── tests/testthat/        # see section 5
├── vignettes/
│   ├── getting-started.Rmd
│   └── reproducing-the-paper.Rmd
├── papers/                # the two PDFs (not shipped to CRAN; .Rbuildignore)
└── .github/workflows/     # R CMD check matrix (ubuntu/mac/windows, release+devel)
```

S3 throughout. Every exported function documented with roxygen2, with the
mathematical definitions in the details sections. pkgdown site from the
repo. License: choose at repo creation (MIT or GPL-3; GPL-3 is common for
research method packages).

## 5. Testing plan

Unit tests, hand-computed expectations:

- partial concordance and discordance at, below, between and above each
  threshold, both directions, boundary values exactly at thresholds
- quantile threshold resolution
- aggregation on a 3-trace toy example computed by hand, including the
  J-set exclusion when d_j <= c_j and the c_j = 1 guard
- each measure on tiny traces with known answers (e.g. identical traces give
  cosine 1 and edit distance 0)
- nominal/ordinal/numeric templates on a toy attribute table
- must_link / cannot_link algebra; trim_outliers greedy on a known matrix
- symmetry, dimnames and range invariants of S

Regression tests:

- the illustrative log from the extensions paper: full pipeline reproduces
  the published memberships (fixed seed)
- if the ER dataset can be shipped or downloaded: reproduce the 3-cluster
  solution of the foundations paper; otherwise pin S on a stored fixture

Performance guard: outrank_similarity on a synthetic 500-case log completes
within a set budget, protecting against reintroducing per-cell `apply`.

## 6. Implementation notes for the refactor

The existing scripts (`docs/*.R`) are the semantic reference, not the code
to copy. Specific rewrites:

- transition-profile construction: replace the row loop with per-trace
  computation via `combn`-free index arithmetic on integer-encoded
  activities, accumulating into a sparse triplet (i, j, value) structure;
  the current loop writes into a data frame cell by cell
- activity encoding: never single letters (breaks beyond 26 activities and
  with multi-character labels); use integer codes internally and map back
  for display; edit distance operates on integer sequences via
  `stringdist::seq_dist` (method "osa")
- partial indices: pure matrix algebra, no `apply(X, 1:2, f)`
- drop `lsa`, `gtools`, `caTools`, `plyr`, `reshape2` dependencies; base R
  or dedicated small packages only
- no `setwd`, no absolute paths, no `print(i)` progress (use optional
  `progress` message hooks)
- durations computed with `difftime(..., units =)` explicitly, never
  relying on the default unit

## 7. Milestones

Working directory:
`/Users/pavlos/Library/CloudStorage/GoogleDrive-pdelias@af.duth.gr/My Drive/Academy/PaperLand/Outranking Similarity/R package/`
The package root is `simOutrank/` inside it; the reference material (papers,
legacy scripts, this document) lives beside it and gets copied into the repo
under `papers/`, `dev/legacy/` and `design/DESIGN.md` respectively.

Caution: this folder is Google Drive synced. Drive sync and git repositories
interact badly (sync conflicts inside `.git/` can corrupt the repository, and
`R CMD check` churns many temporary files). Prefer keeping the git working
copy in a plain local folder (e.g. `~/dev/simOutrank`) with GitHub as the
backup and this Drive folder for the reference material only. If the repo
must stay here, pause Drive sync during heavy work sessions.

1. Repo + skeleton (`usethis::create_package`, git, CI) and this document
   committed as `design/DESIGN.md`
2. traces + measures + criterion object, with unit tests
3. outranking core + aggregation, with hand-computed tests
4. clustering + diagnostics; regression test on the illustrative log
5. outliers, constraints, validation, plots
6. vignettes, pkgdown, README with a 20-line worked example
7. v0.1.0 GitHub release; CRAN submission after external feedback
