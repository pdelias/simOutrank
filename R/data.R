#' Illustrative customer-service event log
#'
#' The synthetic event log of Table 1 in Delias et al. (2021), used to
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
#' @source Delias, P., Doumpos, M., Manthou, V. and Grigoroudis, E. (2021).
#'   Improving the non-compensatory trace clustering. *International
#'   Transactions in Operational Research*, Table 1.
"illustrative_log"
