#!/bin/sh
# Repeat the matched-tolerance timing measurements several times, to put a
# spread on the per-EVD costs of tab:perevd (n=100) and the analogous n=500
# comparison, instead of the single @elapsed each currently rests on.
#
# Requires NCM_STANDALONE=0 (real TimerOutputs and MAT), the same as
# timing_rerun.sh: NCM_STANDALONE=1's dummy TimerOutput measurably inflates
# @elapsed itself (about 2.2x on SBB-Dual in a spot check), not only the
# internal breakdown, so it is NOT a valid stand-in for repeat variance on
# tab:perevd -- do not "fix" this script to use it. Native-tolerance timing
# is not repeated here since it is not what feeds tab:perevd/tab:primitive.
#
# On this development machine, `using TimerOutputs` itself currently fails
# (a Windows Application Control policy blocks loading its compiled package
# cache, and MAT's separately); this is an environment issue, not a code
# issue -- see docs/repeat-timing-attempt.md. Run this on a machine where
# `julia --project=. -e "using TimerOutputs, MAT"` succeeds.
#
# Usage: sh repeat_timing.sh <n_repeats> <out_dir>
cd "$(dirname "$0")"
NREP=${1:-4}
OUT=${2:-repeat_timing_out}
mkdir -p "$OUT"
export NCM_STANDALONE=0
J="julia --pkgimages=no --project=. bench_sbb_dual.jl"
stamp() { echo "$(date '+%F %T') $*"; }

for i in $(seq 1 "$NREP"); do
  stamp "repeat $i: n=100 matched start"
  $J --suite degen_instances_paired --out "$OUT/timing_kkt270_matched_rep$i.csv" \
     --tol-mode matched --matched-tol 1e-11 \
     > "$OUT/timing_n100_matched_rep$i.log" 2>&1
  stamp "repeat $i: n=100 matched exit $?"

  stamp "repeat $i: n=500 matched start"
  $J --suite degen_instances_n500_paired --only "$(cat n500_timing_subset.txt)" \
     --out "$OUT/timing_n500_matched_rep$i.csv" \
     --tol-mode matched --matched-tol 1e-11 --dykstra-maxit 800 \
     > "$OUT/timing_n500_matched_rep$i.log" 2>&1
  stamp "repeat $i: n=500 matched exit $?"
done
stamp "REPEAT TIMING DONE"
