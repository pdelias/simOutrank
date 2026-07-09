# Illustrative customer-service event log

The synthetic event log of Table 1 in Delias et al. (2021), used to
illustrate outranking-based trace clustering. It describes 25 fictitious
customers of a service desk with two tiers ("Gold" and "Blue"); two
cases (`B14`, `G11`) are deliberate outliers whose flow does not match
the process logic.

## Usage

``` r
illustrative_log
```

## Format

A data frame with 117 rows (events) and 5 columns:

- case_id:

  Customer identifier (25 distinct cases).

- activity:

  Activity performed (`A`–`E`), in chronological order.

- timestamp:

  Event time (`POSIXct`); events are one minute apart.

- status:

  Customer tier, `"Gold"` or `"Blue"`.

- satisfaction:

  Registered satisfaction, `"HIGH"` or `"LOW"`.

## Source

Delias, P., Doumpos, M., Manthou, V. and Grigoroudis, E. (2021).
Improving the non-compensatory trace clustering. *International
Transactions in Operational Research*, Table 1.
