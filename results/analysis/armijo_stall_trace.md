# Sec. 4.2 naive-Armijo Newton stall, traced

270 n=100 instances, Newton-SIN (naive Armijo, cached=false), tol=1e-11, uncapped EVDs.

Stalled instances (exit = max_iter): 56 / 270
Total backtracks (all outer iterations, all instances): 151471
  (cross-checked against the solver's own `backtracks` return value: match)
Full-step (trial 1) rejections: 5677
Affected iterations (full-step rejection that would have reduced both
  the gradient norm and the exact forward error): 5677
  of which on stalled instances only: 5407 / 5407 full-step rejections
  on non-stalled instances: 270 / 270

ULP-margin predictor (defined in the script docstring), evaluated on the
5677 full-step rejections (5677 affected, 0 not):
AUC = NaN

Same predictor over EVERY rejected trial (any trial number), all 151471:
  115211 affected, 36260 not affected
  AUC = 0.526

