#!/usr/bin/env sh
# Regenerate every analysis table in the paper from the shipped result files.
# No solver is run: this reads results/*.csv.gz only. Runtime: five to ten minutes.
#
#   sh code/reproduce.sh [python]        (default python: python3)
#
# Output goes to results/reproduced/. Compare it with results/analysis/, using
# the table -> file map this script prints at the end as the list of what it
# covers. results/analysis/ also holds files this script does NOT regenerate:
# two come from Julia (armijo_stall_trace.md, sensitivity_eta_m.md -- run
# code/trace_armijo_stall.jl / sensitivity_eta_m.jl to reproduce those), and
# the rest are working files from earlier analysis passes, kept for
# provenance but not cited by any table or number in the paper.
set -e
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
PY=${1:-python3}
work="$root/results/reproduced"
mkdir -p "$work"

echo "unpacking result files"
for f in "$root"/results/*.csv.gz; do
  base=$(basename "$f" .gz)
  gunzip -c "$f" > "$work/$base"
done

echo "n=100 ranking study  -> kkt270_analysis.md"
"$PY" "$here/analyze_ranking.py" \
    "$work/ranking_kkt270_v2.csv" "$work/ranking_kkt270_anderson.csv" \
    "$work/kkt270_analysis.md" > /dev/null

echo "n=500 ranking study  -> n500_analysis.md"
"$PY" "$here/analyze_ranking.py" \
    "$work/ranking_n500.csv" "$work/ranking_n500_anderson.csv" \
    "$work/n500_analysis.md" > /dev/null

echo "n=500 high rank      -> highrank_analysis.txt"
"$PY" "$here/analyze_highrank.py" "$work/ranking_highrank_n500.csv" > "$work/highrank_analysis.txt"
"$PY" "$here/analyze_by_rank.py" "$work/highrank_by_rank.md" \
    "$work/ranking_highrank_n500.csv" "$work/ranking_highrank_proj.csv" \
    SBB-Dual:AGD-SDAJ-BH Anderson-APM:AGD-SDAJ-BH > /dev/null

echo "equity n=550 KKT     -> thesis_kkt_analysis.md"
"$PY" "$here/analyze_ranking.py" \
    "$work/ranking_thesis_kkt.csv" "$work/ranking_thesis_kkt_anderson.csv" \
    "$work/thesis_kkt_analysis.md" > /dev/null

echo "equity n=550 perturbed -> thesis_pert_analysis.md"
"$PY" "$here/analyze_ranking.py" \
    "$work/ranking_thesis.csv" "$work/ranking_thesis_anderson.csv" \
    "$work/thesis_pert_analysis.md" > /dev/null

echo "literature matrices -> real_per_instance.md"
"$PY" "$here/analyze_per_instance.py" "$work/real_per_instance.md" \
    "$work/ranking_real.csv" "$work/ranking_real_anderson_small.csv" \
    "$work/ranking_real_anderson_large.csv" > /dev/null

echo "equity n=550 KKT by rank -> thesis_kkt_by_rank.md"
"$PY" "$here/analyze_by_rank.py" "$work/thesis_kkt_by_rank.md" \
    "$work/ranking_thesis_kkt.csv" "$work/ranking_thesis_kkt_anderson.csv" \
    SBB-Dual:AGD-SDAJ-BH Anderson-APM:AGD-SDAJ-BH > /dev/null

echo "figure data         -> figure_data/"
mkdir -p "$work/figure_data"
"$PY" "$here/make_figure_data.py" "$work" "$work/figure_data" > /dev/null

echo "timing, n=100 and n=500 -> timing_n100.md, timing_n500.md"
"$PY" "$here/analyze_timing.py" "$here/../results/timing_kkt270_native.csv" \
    "$here/../results/timing_kkt270_matched.csv" "$work/timing_n100.md" > /dev/null
"$PY" "$here/analyze_timing.py" "$here/../results/timing_n500_native.csv" \
    "$here/../results/timing_n500_matched.csv" "$work/timing_n500.md" > /dev/null

echo "timing repeats, Sec. 3.6 -> timing_repeats.md"
"$PY" "$here/analyze_timing_repeats.py" \
    "$here/../results/timing_kkt270_matched.csv" \
    "$here/../results/timing_kkt270_matched_rep1.csv" \
    "$here/../results/timing_kkt270_matched_rep2.csv" \
    "$here/../results/timing_kkt270_matched_rep3.csv" \
    "$here/../results/timing_kkt270_matched_rep4.csv" -- \
    "$here/../results/timing_n500_matched.csv" \
    "$here/../results/timing_n500_matched_rep1.csv" \
    "$here/../results/timing_n500_matched_rep2.csv" \
    "$here/../results/timing_n500_matched_rep3.csv" \
    "$here/../results/timing_n500_matched_rep4.csv" \
    "$work/timing_repeats.md" > /dev/null

echo "stopping rule, Sec. 6 -> stopping_rule.txt"
"$PY" "$here/analyze_stopping_rule.py" "$here/../results/timing_kkt270_native.csv" \
    "$here/../results/timing_n500_native.csv" > "$work/stopping_rule.txt"

echo "equity n=2105       -> us2105_analysis.txt"
"$PY" "$here/analyze_us2105.py" "$work" > "$work/us2105_analysis.txt"

echo "scoring-column check -> scoring_column_check.txt"
"$PY" "$here/check_scoring_column.py" "$work/ranking_kkt270_v2.csv" "$work/ranking_n500.csv" \
      "$work/ranking_highrank_n500.csv" "$work/ranking_thesis_kkt.csv" > "$work/scoring_column_check.txt"

echo "bulk-level pilot, Sec. 5.10 -> confound_mu_bulk_analysis.txt"
"$PY" "$here/analyze_confound.py" "$work" > "$work/confound_mu_bulk_analysis.txt"

echo
echo "done. table -> file map:"
cat <<'MAP'
  Tab. fwd, cells, feas; Sec. 5.11 numbers  kkt270_analysis.md
  Tab. n500                                 n500_analysis.md
  Tab. highrank                             highrank_analysis.txt, highrank_by_rank.md
  Tab. thesiskkt                            thesis_kkt_analysis.md, thesis_kkt_by_rank.md
  Tab. thesispert                           thesis_pert_analysis.md
  Tab. real                                 real_per_instance.md
  Sec. accounting sensitivity               scoring_column_check.txt
  Tab. us2105, us2105pert                   us2105_analysis.txt
  Sec. 6 cross-dimension comparison         stopping_rule.txt
  Tab. primitive, perevd, native            timing_n100.md (and timing_n500.md)
  Sec. 3.6 session-to-session repeats       timing_repeats.md
  Sec. 5.10 bulk-level pilot (48 instances)  confound_mu_bulk_analysis.txt
  Figure data                               figure_data/ (compare paper/figures/data/)
MAP
