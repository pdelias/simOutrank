# Illustrative customer-service event log

The synthetic event log of Table 1 in Delias et al. (2023), used to
illustrate outranking-based trace clustering. It describes 25 fictitious
customers of a service desk with two tiers, `"GOLD"` and `"NORMAL"` (the
latter is the "Blue" tier of the paper's narrative). Cases are numbered
in Table 1's order; the last two (case ids `"24"` and `"25"`) are
deliberate outliers whose flow matches neither tier.

## Usage

``` r
illustrative_log
```

## Format

A data frame with 117 rows (events) and 5 columns:

- case_id:

  Customer identifier, `"1"`–`"25"` (character).

- activity:

  Activity performed (`A`–`E`), in chronological order.

- timestamp:

  Event time (`POSIXct`); events are one minute apart.

- status:

  Customer tier, `"GOLD"` or `"NORMAL"`.

- satisfaction:

  Registered satisfaction, `"High"` or `"Low"`.

## Source

Delias, P., Doumpos, M., Grigoroudis, E. and Matsatsinis, N. (2023).
Improving the non-compensatory trace-clustering decision process.
*International Transactions in Operational Research*, 30(3), 1387-1406.
[doi:10.1111/itor.13062](https://doi.org/10.1111/itor.13062) (Table 1).
