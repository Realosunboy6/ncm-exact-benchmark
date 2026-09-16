#!/usr/bin/env sh
# Regenerate every analysis table in the paper from the shipped result files.
# No solver is run: this reads results/*.csv.gz only. Runtime: about 3 minutes.
#
#   sh code/reproduce.sh [python]        (default python: python3)
#
# Output goes to results/reproduced/. Compare it with results/analysis/.
set -e
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
PY=${1:-python3}
work="$root/results/reproduced"
mkdir -p "$work"

echo "unpacking result files"
for f in "$root"/results/*.csv.gz; do
  base=$(basename "$f" .gz)
  [ -f "$work/$base" ] || gunzip -c "$f" > "$work/$base"
done

echo "n=100 ranking study  -> kkt270_analysis.md"
"$PY" "$here/analyze_ranking.py" "$work/ranking_kkt270_v2.csv" "$work/kkt270_analysis.md" > /dev/null

echo "n=500 ranking study  -> n500_analysis.md"
"$PY" "$here/analyze_ranking.py" "$work/ranking_n500.csv" "$work/n500_analysis.md" > /dev/null

echo "n=500 high rank      -> highrank_analysis.txt"
"$PY" "$here/analyze_highrank.py" "$work/ranking_highrank_n500.csv" > "$work/highrank_analysis.txt"

echo "equity n=550 KKT     -> thesis_kkt_analysis.md"
"$PY" "$here/analyze_ranking.py" "$work/ranking_thesis_kkt.csv" "$work/thesis_kkt_analysis.md" > /dev/null

echo "equity n=550 perturbed -> thesis_pert_analysis.md"
"$PY" "$here/analyze_ranking.py" "$work/ranking_thesis.csv" "$work/thesis_pert_analysis.md" > /dev/null

echo "equity n=2105       -> us2105_analysis.txt"
"$PY" "$here/analyze_us2105.py" "$work" > "$work/us2105_analysis.txt"

echo "scoring-column check -> scoring_column_check.txt"
"$PY" "$here/check_scoring_column.py" "$work/ranking_kkt270_v2.csv" "$work/ranking_n500.csv" \
      "$work/ranking_highrank_n500.csv" "$work/ranking_thesis_kkt.csv" > "$work/scoring_column_check.txt"

echo
echo "done. table -> file map:"
cat <<'MAP'
  Tab. fwd, res, cells, acct, feas, exits   kkt270_analysis.md
  Tab. n500                                 n500_analysis.md
  Tab. highrank                             highrank_analysis.txt
  Tab. thesiskkt                            thesis_kkt_analysis.md
  Tab. thesispert                           thesis_pert_analysis.md
  Sec. accounting sensitivity               scoring_column_check.txt
  Tab. us2105, us2105pert                   us2105_analysis.txt
MAP
