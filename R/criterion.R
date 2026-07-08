`%||%` <- function(a, b) if (is.null(a)) b else a

#' Quantile threshold specification
#'
#' `q()` marks a criterion threshold as a quantile of the empirical
#' distribution of that criterion's off-diagonal pairwise values, rather than
#' a fixed number. It is resolved to a numeric value when the criterion's
#' measure matrix is available (see [criterion()]).
#'
#' @param p A single probability in `[0, 1]`.
#' @return An object of class `outrank_quantile`.
#' @examples
#' q(0.8)
#' @export
q <- function(p) {
  if (!is.numeric(p) || length(p) != 1L || is.na(p) || p < 0 || p > 1) {
    stop("`p` must be a single number in [0, 1].", call. = FALSE)
  }
  structure(list(p = p), class = "outrank_quantile")
}

is_quantile <- function(x) inherits(x, "outrank_quantile")

#' @export
print.outrank_quantile <- function(x, ...) {
  cat(sprintf("q(%g)\n", x$p))
  invisible(x)
}

#' Define an outranking criterion
#'
#' `criterion()` is the core constructor behind the `crit_*` helpers; users
#' rarely call it directly. It bundles a pairwise measure with its direction,
#' weight and ELECTRE-III-style thresholds.
#'
#' @details
#' For a criterion with indifference threshold \eqn{q}, similarity threshold
#' \eqn{s} and (optional) veto threshold \eqn{t}, and a pairwise value
#' \eqn{v = g(a, b)}, the partial concordance and discordance of a
#' `"similarity"`-direction criterion are
#' \deqn{c = 1 \ \mathrm{if}\ v \ge s, \quad
#'       c = \frac{v - q}{s - q} \ \mathrm{if}\ q \le v < s, \quad
#'       c = 0 \ \mathrm{if}\ v < q,}
#' \deqn{d = 1 \ \mathrm{if}\ v \le t, \quad
#'       d = \frac{q - v}{q - t} \ \mathrm{if}\ t < v \le q, \quad
#'       d = 0 \ \mathrm{if}\ v > q.}
#' For a `"dissimilarity"`-direction criterion the inequalities reverse. This
#' imposes an ordering on the thresholds, which the constructor validates:
#' \eqn{t < q < s} for the similarity direction and \eqn{s < q < t} for the
#' dissimilarity direction. A `veto = NULL` criterion contributes no
#' discordance.
#'
#' Thresholds may be given as plain numbers or as a quantile specification
#' [q()]. Numeric thresholds are validated immediately; quantile thresholds
#' are resolved and validated once the measure matrix is known.
#'
#' @param measure Either a `function(traces)` returning a symmetric numeric
#'   matrix, or a precomputed numeric matrix with dimnames matching the case
#'   ids.
#' @param direction One of `"similarity"` (larger values mean more alike) or
#'   `"dissimilarity"` (smaller values mean more alike).
#' @param weight A single positive number. Weights are normalised to sum to
#'   one when the credibility matrix is built.
#' @param indifference,similarity Required thresholds; each a single number or
#'   a [q()] quantile specification.
#' @param veto Optional veto threshold; a number, a [q()] specification, or
#'   `NULL` for no discordance.
#' @param name Optional label used in printing and diagnostics.
#' @return An object of class `criterion`.
#' @examples
#' # A similarity criterion on a precomputed matrix.
#' m <- matrix(c(1, 0.4, 0.4, 1), 2, dimnames = list(c("a", "b"), c("a", "b")))
#' criterion(m, direction = "similarity", weight = 2,
#'           indifference = 0.5, similarity = 0.8, veto = 0.2)
#' @export
criterion <- function(measure,
                      direction = c("similarity", "dissimilarity"),
                      weight = 1,
                      indifference,
                      similarity,
                      veto = NULL,
                      name = NULL) {
  direction <- match.arg(direction)

  if (!is.function(measure) && !is.matrix(measure)) {
    stop("`measure` must be a function(traces) or a numeric matrix.",
         call. = FALSE)
  }
  if (is.matrix(measure) && !is.numeric(measure)) {
    stop("`measure` matrix must be numeric.", call. = FALSE)
  }
  if (!is.numeric(weight) || length(weight) != 1L || is.na(weight) ||
      weight <= 0) {
    stop("`weight` must be a single positive number.", call. = FALSE)
  }
  if (missing(indifference) || missing(similarity)) {
    stop("`indifference` and `similarity` thresholds are required.",
         call. = FALSE)
  }
  check_threshold(indifference, "indifference")
  check_threshold(similarity, "similarity")
  if (!is.null(veto)) check_threshold(veto, "veto")
  if (!is.null(name) && !(is.character(name) && length(name) == 1L)) {
    stop("`name` must be NULL or a single string.", call. = FALSE)
  }

  crit <- structure(
    list(
      measure      = measure,
      direction    = direction,
      weight       = weight,
      indifference = indifference,
      similarity   = similarity,
      veto         = veto,
      name         = name %||% NA_character_
    ),
    class = "criterion"
  )

  ## Validate the ordering now if every threshold is already numeric;
  ## otherwise defer to resolution time (see resolve_thresholds()).
  if (all_numeric_thresholds(crit)) {
    validate_thresholds(crit$veto, crit$indifference, crit$similarity,
                        direction)
  }
  crit
}

check_threshold <- function(z, what) {
  if (is_quantile(z)) return(invisible())
  if (!is.numeric(z) || length(z) != 1L || is.na(z)) {
    stop(sprintf("`%s` must be a single number or a q() specification.", what),
         call. = FALSE)
  }
}

all_numeric_thresholds <- function(crit) {
  !is_quantile(crit$indifference) &&
    !is_quantile(crit$similarity) &&
    (is.null(crit$veto) || !is_quantile(crit$veto))
}

## Validate the threshold ordering imposed by the criterion direction.
## Errors on violation; returns TRUE invisibly otherwise.
validate_thresholds <- function(veto, indifference, similarity, direction) {
  if (direction == "similarity") {
    if (!(indifference < similarity)) {
      stop("For a similarity criterion, indifference < similarity is required.",
           call. = FALSE)
    }
    if (!is.null(veto) && !(veto < indifference)) {
      stop("For a similarity criterion, veto < indifference is required.",
           call. = FALSE)
    }
  } else {
    if (!(similarity < indifference)) {
      stop("For a dissimilarity criterion, similarity < indifference is required.",
           call. = FALSE)
    }
    if (!is.null(veto) && !(indifference < veto)) {
      stop("For a dissimilarity criterion, indifference < veto is required.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

## Resolve any q() thresholds of `crit` against the off-diagonal values of the
## measure matrix `mat`, then validate the resulting ordering. Returns the
## criterion with numeric thresholds.
resolve_thresholds <- function(crit, mat) {
  vals <- mat[upper.tri(mat)]
  res <- function(z) {
    if (is_quantile(z)) {
      unname(stats::quantile(vals, probs = z$p, na.rm = TRUE))
    } else {
      z
    }
  }
  crit$indifference <- res(crit$indifference)
  crit$similarity   <- res(crit$similarity)
  if (!is.null(crit$veto)) crit$veto <- res(crit$veto)
  validate_thresholds(crit$veto, crit$indifference, crit$similarity,
                      crit$direction)
  crit
}

#' @export
print.criterion <- function(x, ...) {
  fmt <- function(z) if (is_quantile(z)) sprintf("q(%g)", z$p) else format(z)
  label <- if (!is.na(x$name)) sprintf(" '%s'", x$name) else ""
  cat(sprintf("<criterion%s>: direction = %s, weight = %g\n",
              label, x$direction, x$weight))
  cat(sprintf("  indifference = %s, similarity = %s, veto = %s\n",
              fmt(x$indifference), fmt(x$similarity),
              if (is.null(x$veto)) "none" else fmt(x$veto)))
  invisible(x)
}
