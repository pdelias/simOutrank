# Quantile threshold specification

`as_quantile()` marks a criterion threshold as a quantile of the
empirical distribution of that criterion's off-diagonal pairwise values,
rather than a fixed number. It is resolved to a numeric value when the
criterion's measure matrix is available (see
[`criterion()`](https://pdelias.github.io/simOutrank/reference/criterion.md)).

## Usage

``` r
as_quantile(p)
```

## Arguments

- p:

  A single probability in `[0, 1]`.

## Value

An object of class `outrank_quantile`.

## Examples

``` r
as_quantile(0.8)
#> as_quantile(0.8)
```
