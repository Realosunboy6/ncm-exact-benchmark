#!/bin/sh
# Re-time all seven variants in one session, Anderson-APM included, with the
# settings of the original timing runs. One CPU-heavy job at a time.
cd "$(dirname "$0")"
export NCM_STANDALONE=1
J="julia --project=. bench_sbb_dual.jl"
stamp() { echo "$(date '+%F %T') $*"; }
stamp "n=100 native start"
$J --suite degen_instances_paired --out timing_kkt270_native_v2.csv --tol-mode native > timing_n100_native_v2.log 2>&1
stamp "n=100 native exit $?"
stamp "n=100 matched start"
$J --suite degen_instances_paired --out timing_kkt270_matched_v2.csv --tol-mode matched --matched-tol 1e-11 > timing_n100_matched_v2.log 2>&1
stamp "n=100 matched exit $?"
stamp "n=500 matched start"
$J --suite degen_instances_n500_paired --only "$(cat n500_timing_subset.txt)" --out timing_n500_matched_v2.csv --tol-mode matched --matched-tol 1e-11 --dykstra-maxit 800 > timing_n500_matched_v2.log 2>&1
stamp "n=500 matched exit $?"
stamp "n=500 native start"
$J --suite degen_instances_n500_paired --only "$(cat n500_timing_subset.txt)" --out timing_n500_native_v2.csv --tol-mode native --dykstra-maxit 800 > timing_n500_native_v2.log 2>&1
stamp "n=500 native exit $?"
stamp "TIMING RERUN DONE"
