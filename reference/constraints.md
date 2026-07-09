# Must-link and cannot-link constraints

Inject domain knowledge into the credibility matrix by rewarding pairs
that should share a cluster (`must_link()`) or severing pairs that
should not (`cannot_link()`), following Delias et al. (2023).

## Usage

``` r
must_link(sim, pairs_or_attribute, reward = 2)

cannot_link(sim, pairs_or_attribute)
```

## Arguments

- sim:

  An `outrank_sim` object from
  [`outrank_similarity()`](https://pdelias.github.io/simOutrank/reference/outrank_similarity.md).

- pairs_or_attribute:

  A two-column matrix of case-id pairs, or a length-one attribute name
  (requires that `sim` carries case attributes).

- reward:

  Positive amount added to `S` for each must-linked pair.

## Value

The `outrank_sim` with an updated `S`.

## Details

With a symmetric 0/1 constraint mask `M` (zero diagonal),
\$\$\text{must\\link:}\quad S \leftarrow \min(S + \text{reward}\cdot
M,\\ 1),\$\$ \$\$\text{cannot\\link:}\quad S \leftarrow S \odot (1 -
M).\$\$ The constraint set is given either as a two-column matrix of
case-id pairs, or as the name of a case attribute: `must_link()` then
links cases with an equal attribute value, and `cannot_link()` severs
cases whose values differ.

## Examples

``` r
m <- matrix(0.2, 4, 4); diag(m) <- 1; dimnames(m) <- list(1:4, 1:4)
crit <- criterion(m, "similarity", indifference = 0.1, similarity = 0.9)
tr <- as_traces(data.frame(case = as.character(1:4), act = "x",
                           ts = as.POSIXct("2020-01-01")),
                "case", "act", "ts")
sim <- outrank_similarity(tr, crit)
sim <- must_link(sim, cbind("1", "2"))
cannot_link(sim, cbind("3", "4"))$S
#>       1     2     3     4
#> 1 1.000 1.000 0.125 0.125
#> 2 1.000 1.000 0.125 0.125
#> 3 0.125 0.125 1.000 0.000
#> 4 0.125 0.125 0.000 1.000
```
