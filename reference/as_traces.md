# Represent an event log as traces

`as_traces()` converts an event log into a `traces` object: the
time-ordered activity sequence of every case together with the
case-level attribute table. Activities are encoded as integers
internally (never as single letters) so that logs with more than 26
activities or with multi-character labels are handled correctly; the
original labels are kept for display and decoding.

## Usage

``` r
as_traces(x, ...)

# S3 method for class 'data.frame'
as_traces(x, case_id, activity, timestamp, ...)

# S3 method for class 'eventlog'
as_traces(x, ...)

# S3 method for class 'activitylog'
as_traces(x, ...)
```

## Arguments

- x:

  An event log. A `data.frame` in which each row is an event, or – when
  the bupaR package is installed – a bupaR `eventlog` or `activitylog`.

- ...:

  Passed on to methods.

- case_id, activity, timestamp:

  Length-one character strings naming the columns that hold the case
  identifier, the activity label and the event timestamp. For the bupaR
  methods the mapping is read from the object and these arguments must
  not be supplied.

## Value

An object of class `traces`, a list with elements:

- `case_ids`:

  character vector of case identifiers, in order.

- `sequences`:

  named list of integer vectors; each entry is the time-ordered activity
  sequence of a case, encoded against `activities`.

- `activities`:

  character vector of distinct activity labels; the integer code `i` in
  `sequences` refers to `activities[i]`.

- `times`:

  named list of the ordered event timestamps per case.

- `case_attributes`:

  data frame of case-level attributes, one row per case, row names equal
  to the case identifiers.

## Details

Events are ordered by `timestamp` within each case. Ties (two events of
the same case sharing a timestamp) are broken by the original row order
and raise a warning. Cases keep their order of first appearance in `x`.

Every column other than `case_id`, `activity` and `timestamp` is treated
as a case-level attribute and summarised by its first value within the
ordered case, matching the convention that such attributes are constant
per case.

## Examples

``` r
log <- data.frame(
  case = c("c1", "c1", "c2", "c2"),
  act  = c("register", "decide", "register", "reject"),
  ts   = as.POSIXct("2020-01-01") + c(0, 60, 0, 90),
  status = c("open", "open", "closed", "closed")
)
as_traces(log, case_id = "case", activity = "act", timestamp = "ts")
#> <traces>: 2 cases, 3 distinct activities
#>   trace length: min 2, median 2, max 2
#>   case attributes: status
```
