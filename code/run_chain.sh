#!/usr/bin/env bash
# Paper 2 gaps run: sequential chain after the n=500 ranking pass. Strictly one
# CPU-heavy job at a time; timing jobs never overlap anything.
cd "C:/Users/ibrah/Documents/Codex/NCM-research/spid-dual-ncm-main/outputs/SPID-Dual-NCM/experiments/bench" || exit 1
CH=run_chain.log
stamp() { echo "$(date '+%F %T') $*" >> "$CH"; }

# The ranking harness ends with "wrote <path>", never an "end " line (the
# original condition waited forever). Also stop waiting if the n=500 julia
# process disappears without writing, so a crash cannot hang the chain.
N500_PID=20224
until grep -q "^wrote .*ranking_n500.csv" ranking_n500.log; do
    if ! tasklist 2>/dev/null | grep -q " $N500_PID "; then
        stamp "ABORT: n500 julia ($N500_PID) exited without 'wrote' line"
        stamp "$(tail -3 ranking_n500.log)"
        exit 1
    fi
    sleep 30
done
stamp "n500 ranking finished: $(tail -1 ranking_n500.log)"

# --- real-matrix ranking (standalone; computed reference; target 1e-9) ------
stamp "real ranking part1 (Rocky, cor1399) start"
NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl --suite real_suite \
  --only "Rocky_Mountain_Region_CORR,cor1399" --ranking ranking_real_part1.csv \
  --ranking-tol 1e-9 --sbb-maxit 500 --apm-maxit 500 --max-evds 500 \
  --ref-sbb-maxit 300 --blas-threads 4 > ranking_real_part1.log 2>&1
stamp "real ranking part1 exit $?"

stamp "real ranking part2 (bccd16) start"
NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl --suite real_suite \
  --only "bccd16" --ranking ranking_real_part2.csv \
  --ranking-tol 1e-9 --sbb-maxit 100 --apm-maxit 100 --max-evds 100 \
  --ref-sbb-maxit 100 --blas-threads 4 > ranking_real_part2.log 2>&1
stamp "real ranking part2 exit $?"

{ cat ranking_real_part1.csv; tail -n +2 ranking_real_part2.csv; } > ranking_real.csv
stamp "ranking_real.csv rows: $(wc -l < ranking_real.csv)"

# --- n=500 timing subset (18 instances), matched then native ---------------
stamp "timing n500 matched start"
NCM_STANDALONE=0 julia --pkgimages=no --project=. bench_sbb_dual.jl \
  --suite degen_instances_n500_paired --only "$(cat n500_timing_subset.txt)" \
  --out timing_n500_matched.csv --tol-mode matched --matched-tol 1e-11 \
  --dykstra-maxit 800 > timing_n500_matched.log 2>&1
stamp "timing n500 matched exit $?"

stamp "timing n500 native start"
NCM_STANDALONE=0 julia --pkgimages=no --project=. bench_sbb_dual.jl \
  --suite degen_instances_n500_paired --only "$(cat n500_timing_subset.txt)" \
  --out timing_n500_native.csv --tol-mode native \
  --dykstra-maxit 800 > timing_n500_native.log 2>&1
stamp "timing n500 native exit $?"

# --- real-matrix timing at matched 1e-9 (Rocky, cor1399; warmup kept) ------
stamp "timing real matched start"
NCM_STANDALONE=0 julia --pkgimages=no --project=. bench_sbb_dual.jl \
  --suite real_suite --only "Rocky_Mountain_Region_CORR,cor1399" \
  --out timing_real_matched.csv --tol-mode matched --matched-tol 1e-9 \
  --evd-budget 300 --dykstra-maxit 300 --sbb-maxit 300 --ref-sbb-maxit 300 \
  --cap-naive-newton > timing_real_matched.log 2>&1
stamp "timing real matched exit $?"
stamp "CHAIN DONE"
