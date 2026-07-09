#' Illustrative customer-service event log
#'
#' The synthetic event log of Table 1 in Delias et al. (2023), used to
#' illustrate outranking-based trace clustering. It describes 25 fictitious
#' customers of a service desk with two tiers ("Gold" and "Blue"); two cases
#' (`B14`, `G11`) are deliberate outliers whose flow does not match the process
#' logic.
#'
#' @format A data frame with 117 rows (events) and 5 columns:
#' \describe{
#'   \item{case_id}{Customer identifier (25 distinct cases).}
#'   \item{activity}{Activity performed (`A`--`E`), in chronological order.}
#'   \item{timestamp}{Event time (`POSIXct`); events are one minute apart.}
#'   \item{status}{Customer tier, `"Gold"` or `"Blue"`.}
#'   \item{satisfaction}{Registered satisfaction, `"HIGH"` or `"LOW"`.}
#' }
#' @source Delias, P., Doumpos, M., Grigoroudis, E. and Matsatsinis, N. (2023).
#'   Improving the non-compensatory trace-clustering decision process.
#'   *International Transactions in Operational Research*, 30(3), 1387-1406.
#'   \doi{10.1111/itor.13062} (Table 1).
"illustrative_log"
