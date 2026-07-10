## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Test environments

* local: macOS, R 4.5.1 (`R CMD check --as-cran`)
* GitHub Actions: ubuntu-latest / macOS / windows, R release and devel
* win-builder: R-devel (pending)
* R-hub: (pending)

## Notes

* The only NOTE on the local and CI checks is the standard "New submission"
  note from the CRAN incoming-feasibility check.
* A local check can additionally emit a transient
  "checking for future file timestamps ... unable to verify current time"
  NOTE. This is an environment/network artefact (an unreachable
  time-verification service), not a package issue, and does not appear on the
  CI runners.

## Reverse dependencies

* None (new package).
