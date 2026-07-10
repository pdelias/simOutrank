# Attribute-based criterion templates and the crit_custom() escape hatch. The
# measures read a case attribute from the traces object, so these criteria can
# only be used with a traces object that carries the named attribute.

## Fetch a case attribute vector, erroring clearly if it is absent.
get_case_attribute <- function(traces, attribute) {
  attrs <- traces$case_attributes
  if (is.null(attrs) || !(attribute %in% names(attrs))) {
    stop("Case attribute '", attribute, "' not found on the traces object.",
         call. = FALSE)
  }
  attrs[[attribute]]
}

nominal_matrix <- function(traces, attribute) {
  v <- get_case_attribute(traces, attribute)
  m <- outer(v, v, "==") * 1
  dimnames(m) <- list(traces$case_ids, traces$case_ids)
  m
}

ordinal_matrix <- function(traces, attribute, levels) {
  v <- as.character(get_case_attribute(traces, attribute))
  r <- match(v, levels)
  if (anyNA(r)) {
    stop("Attribute '", attribute, "' has values outside `levels`.",
         call. = FALSE)
  }
  m <- abs(outer(r, r, "-"))
  dimnames(m) <- list(traces$case_ids, traces$case_ids)
  m
}

numeric_matrix <- function(traces, attribute, transform) {
  v <- transform(as.numeric(get_case_attribute(traces, attribute)))
  m <- abs(outer(v, v, "-"))
  dimnames(m) <- list(traces$case_ids, traces$case_ids)
  m
}

#' Attribute-based criterion templates
#'
#' Criterion constructors for case-level attributes, covering the common
#' measurement scales. Each builds a measure from a named attribute of the
#' `traces` object.
#'
#' @details
#' * `crit_nominal()` scores a pair 1 when the attribute is equal and 0
#'   otherwise (similarity direction; thresholds preset, no veto).
#' * `crit_ordinal()` uses the absolute rank difference `|rank_a - rank_b|`
#'   over the ordered `levels` (dissimilarity direction); it covers Likert
#'   scales.
#' * `crit_numeric()` uses `|x_a - x_b|` after an optional `transform`
#'   (dissimilarity direction); it covers quantitative, interval and
#'   percentage scales.
#'
#' @param attribute Name of a case attribute carried by the `traces` object.
#' @param levels For `crit_ordinal()`, the attribute values from lowest to
#'   highest rank.
#' @param transform For `crit_numeric()`, a function applied to the numeric
#'   attribute before differencing (e.g. `log`); defaults to [identity()].
#' @param weight A single positive weight.
#' @param indifference,similarity,veto Thresholds; a number or a [as_quantile()]
#'   specification. Defaults suit the direction and are overridable.
#' @param name Criterion label; defaults to the attribute name.
#' @return A [criterion()] object.
#' @seealso [crit_activity_profile()] and the other process-aware helpers.
#' @name crit_attribute
#' @examples
#' crit_nominal("status", weight = 0.3)
#' crit_ordinal("triage", levels = c("green", "yellow", "red"), weight = 0.2)
#' crit_numeric("age", weight = 0.2, transform = identity)
NULL

#' @rdname crit_attribute
#' @export
crit_nominal <- function(attribute, weight = 1, name = attribute) {
  criterion(function(traces) nominal_matrix(traces, attribute),
            "similarity", weight, indifference = 0, similarity = 1,
            veto = NULL, name = name)
}

#' @rdname crit_attribute
#' @export
crit_ordinal <- function(attribute, levels, weight = 1,
                         indifference = as_quantile(0.5), similarity = as_quantile(0.2),
                         veto = NULL, name = attribute) {
  criterion(function(traces) ordinal_matrix(traces, attribute, levels),
            "dissimilarity", weight, indifference, similarity, veto, name)
}

#' @rdname crit_attribute
#' @export
crit_numeric <- function(attribute, weight = 1, transform = identity,
                         indifference = as_quantile(0.5), similarity = as_quantile(0.2),
                         veto = NULL, name = attribute) {
  criterion(function(traces) numeric_matrix(traces, attribute, transform),
            "dissimilarity", weight, indifference, similarity, veto, name)
}

#' Custom criterion
#'
#' The escape hatch for criteria that the templates do not cover, including
#' composite measures (e.g. a linear combination of others). Wraps
#' [criterion()] directly.
#'
#' @param x A `function(traces)` returning a symmetric numeric matrix, or a
#'   precomputed numeric matrix with case-id dimnames.
#' @param direction `"similarity"` or `"dissimilarity"`.
#' @param weight A single positive weight.
#' @param indifference,similarity Required thresholds (number or [as_quantile()]).
#' @param veto Optional veto threshold.
#' @param name Criterion label.
#' @return A [criterion()] object.
#' @examples
#' # A criterion on a precomputed similarity matrix.
#' m <- matrix(c(1, 0.7, 0.7, 1), 2, dimnames = list(c("a", "b"), c("a", "b")))
#' crit_custom(m, direction = "similarity", weight = 1,
#'             indifference = 0.4, similarity = 0.9)
#' @export
crit_custom <- function(x, direction, weight = 1, indifference, similarity,
                        veto = NULL, name = "custom") {
  criterion(x, direction, weight, indifference, similarity, veto, name)
}
