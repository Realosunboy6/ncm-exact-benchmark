"""Paper 2 Sec. 5: does the convention change the ranking, or only the ratios?

Reads a ranking-study trajectory CSV (one row per EVD per solver per instance)
and recomputes solver rankings under four families of convention:

  native      each solver's own exit point, the way a paper that reports
              "iterations to convergence" would compare them
  forward     common forward error ||X_k - X*||_F <= eps against the EXACT X*
  residual    common dual residual ||grad theta(y_k)||_2 <= tau
  accounting  accepted-only vs all-trial credit for rejected line-search trials

The distinction that matters is between a convention that changes the WINNER and
one that changes only the cost ratio. Both are reported; only the former is a
ranking reversal, and the paper must not claim reversals it did not observe.

Two honesty rules carried over from analyze_trajectory.py:
  * a target is only "reached" if it holds for the rest of the run (a method that
    dips below and comes back out has not reached it);
  * rejected trials cost EVDs always, but under accepted-only accounting they can
    never be credited with reaching a target.

Usage: python analyze_ranking.py ranking_kkt270.csv[,more.csv...] [out.md]

Several comma-separated CSVs are read as one study, so a solver run later (and
written to its own file) joins the tables of the run it extends. The solver
list is taken from the data.
"""
import csv
import re
import sys
from collections import defaultdict

paths = (sys.argv[1] if len(sys.argv) > 1 else "ranking_kkt270.csv").split(",")
outpath = sys.argv[2] if len(sys.argv) > 2 else None

SOLVER_ORDER = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual",
                "Dykstra-APM", "Anderson-APM"]
FWD_EPS = [1e-2, 1e-4, 1e-6, 1e-8, 1e-10]
RES_TAU = [1e-2, 1e-4, 1e-6, 1e-8, 1e-10]

curves = defaultdict(list)
ns, exits, feas = {}, {}, {}
for path in paths:
  with open(path.strip()) as f:
    for r in csv.DictReader(f):
          key = (r["instance"], r["solver"])
          curves[key].append((
              int(r["evds"]),
              float(r["err_raw_fro"]),
              float(r["grad_2"]),
              r["accepted"].strip().lower() == "true",
          ))
          ns[r["instance"]] = int(r["n"])
          exits[key] = r["solver_exit"]
          feas[key] = (float(r["lambda_min_X"]), float(r["diag_err_inf"]))
for k in curves:
    curves[k].sort()

instances = sorted({i for i, _ in curves})
SOLVERS = [s for s in SOLVER_ORDER if any((i, s) in curves for i in instances)]

L = []


def emit(line=""):
    L.append(line)
    print(line)


def cost_to(curve, target, col, accepted_only=True):
    """EVDs at the first qualifying iterate whose target holds for the rest."""
    for idx, pt in enumerate(curve):
        if accepted_only and not pt[3]:
            continue
        if pt[col] <= target:
            tail = curve[idx:] if not accepted_only else [p for p in curve[idx:] if p[3]]
            return pt[0] if all(p[col] <= target for p in tail) else None
    return None


def rank(costs):
    have = {s: c for s, c in costs.items() if c is not None}
    return [s for s, _ in sorted(have.items(), key=lambda kv: kv[1])]


def median(v):
    v = sorted(v)
    if not v:
        return None
    m = len(v) // 2
    return v[m] if len(v) % 2 else 0.5 * (v[m - 1] + v[m])


emit("# Paper 2 Sec. 5 - ranking under different conventions")
emit("")
emit(f"Instances: {len(instances)} (n={ns[instances[0]]}). "
     f"Solvers: {', '.join(SOLVERS)}.")
emit("")

# ---------------------------------------------------------------- native
emit("## 1. Native stopping rules")
emit("")
emit("Each solver run to its own exit. This is the comparison a paper reporting")
emit('"iterations to convergence" would make, and it credits a solver for')
emit("stopping early rather than for being accurate.")
emit("")
emit("| solver | median EVDs | min | max | median final err |")
emit("|---|---:|---:|---:|---:|")
native_costs = defaultdict(list)
native_err = defaultdict(list)
for inst in instances:
    for s in SOLVERS:
        c = curves.get((inst, s))
        if not c:
            continue
        native_costs[s].append(c[-1][0])
        acc = [p for p in c if p[3]]
        if acc:
            native_err[s].append(acc[-1][1])
for s in SOLVERS:
    if native_costs[s]:
        emit(f"| {s} | {median(native_costs[s]):.0f} | {min(native_costs[s])} | "
             f"{max(native_costs[s])} | {median(native_err[s]):.2e} |")
emit("")
emit("Achieved accuracy differs across solvers at their native exits, so these")
emit("costs are NOT comparable; that is what the remaining sections correct for.")
emit("")


def convention_table(title, col, targets, label):
    emit(f"## {title}")
    emit("")
    emit(f"| {label} | " + " | ".join(SOLVERS) + " | winner | n reached |")
    emit("|---|" + "---:|" * len(SOLVERS) + "---|---|")
    table = {}
    for tg in targets:
        med, nreach = {}, {}
        for s in SOLVERS:
            cs = [cost_to(curves[(i, s)], tg, col) for i in instances
                  if (i, s) in curves]
            good = [c for c in cs if c is not None]
            med[s] = median(good) if good else None
            nreach[s] = len(good)
        order = rank(med)
        table[tg] = (med, order)
        cells = [f"{med[s]:.0f}" if med[s] is not None else "--" for s in SOLVERS]
        win = order[0] if order else "--"
        reach = " ".join(f"{s.split('-')[0]}:{nreach[s]}" for s in SOLVERS)
        emit(f"| {tg:.0e} | " + " | ".join(cells) + f" | **{win}** | {reach} |")
    emit("")
    return table


fwd = convention_table("2. Common forward error ||X-X*||_F <= eps (exact X*)",
                       1, FWD_EPS, "eps")
res = convention_table("3. Common dual residual ||grad theta||_2 <= tau",
                       2, RES_TAU, "tau")

# --------------------------------------------------------- accounting
emit("## 4. Accepted-only vs all-trial accounting")
emit("")
emit("Under all-trial accounting a REJECTED line-search trial may be credited with")
emit("reaching the target. Rejected trials cost EVDs under both rules; the question")
emit("is only whether they earn accuracy credit. Rows shown only where the median")
emit("changed.")
emit("")
emit("| eps | solver | accepted-only | all-trial | delta |")
emit("|---|---|---:|---:|---:|")
acct_changed = []
for tg in FWD_EPS:
    for s in SOLVERS:
        a = [cost_to(curves[(i, s)], tg, 1, True) for i in instances if (i, s) in curves]
        b = [cost_to(curves[(i, s)], tg, 1, False) for i in instances if (i, s) in curves]
        a = [x for x in a if x is not None]
        b = [x for x in b if x is not None]
        if not a or not b:
            continue
        ma, mb = median(a), median(b)
        if ma != mb:
            acct_changed.append((tg, s, ma, mb))
            emit(f"| {tg:.0e} | {s} | {ma:.1f} | {mb:.1f} | {mb - ma:+.1f} |")
if not acct_changed:
    emit("| - | *(no solver's median cost changed)* | | | |")
emit("")

# ----------------------------------------------------- reversal summary
emit("## 5. Did the ranking actually reverse?")
emit("")
orders = {}
for tg, (med, order) in fwd.items():
    orders[f"forward {tg:.0e}"] = order
for tg, (med, order) in res.items():
    orders[f"residual {tg:.0e}"] = order
orders["native"] = rank({s: median(native_costs[s]) for s in SOLVERS
                         if native_costs[s]})

distinct = {}
for k, v in orders.items():
    distinct.setdefault(tuple(v), []).append(k)
emit(f"Observed **{len(distinct)}** distinct orderings across {len(orders)} "
     "conventions.")
emit("")
emit("| ordering (cheapest first) | conventions producing it |")
emit("|---|---|")
for order, keys in sorted(distinct.items(), key=lambda kv: -len(kv[1])):
    emit(f"| {' < '.join(order)} | {', '.join(keys)} |")
emit("")
winners = {o[0] for o in distinct if o}
if len(winners) == 1:
    w = list(winners)[0]
    emit(f"**The winner is invariant: {w} is cheapest under every convention")
    emit("tested.** The conventions change cost RATIOS, not the ranking at the top.")
    emit("This must be reported as a null result for winner-reversal, quantifying")
    emit("the ratio spread instead of claiming a reversal that was not observed.")
else:
    emit(f"**The winner changes across conventions: {sorted(winners)}.**")
    emit("This is a genuine ranking reversal.")
emit("")

# ------------------------------------------------------- feasibility
emit("## 6. What each solver actually returns")
emit("")
emit("Feasibility of the returned iterate. A solver returning a PSD half-iterate")
emit("and one returning a unit-diagonal half-iterate are not interchangeable.")
emit("")
emit("| solver | median lambda_min(X) | worst lambda_min | median diag err | worst diag err |")
emit("|---|---:|---:|---:|---:|")
for s in SOLVERS:
    lm = [feas[(i, s)][0] for i in instances if (i, s) in feas]
    de = [feas[(i, s)][1] for i in instances if (i, s) in feas]
    if lm:
        emit(f"| {s} | {median(lm):.2e} | {min(lm):.2e} | "
             f"{median(de):.2e} | {max(de):.2e} |")
emit("")

# ------------------------------------------- per-cell (degeneracy regime)
emit("## 7. Ranking by degeneracy cell")
emit("")
emit("Aggregate medians can hide a regime-dependent reversal. The KKT family")
emit("controls rank r, near-zero multiplicity m and separation delta exactly so")
emit("this can be checked: if any ordering flips, it should flip in the degenerate")
emit("corner (small delta, large m), not on average. Target: forward 1e-08.")
emit("")


CELL_RE = re.compile(r"^degen-r(\d+)-m(\d+)-d([0-9.eE+-]+?)-p(\d+)$")


def cell_of(name):
    """degen-r{r}-m{m}-d{delta}-p{pair}; delta may itself contain '-' (1e-06)."""
    mo = CELL_RE.match(name)
    return (mo.group(1), mo.group(2), mo.group(3)) if mo else None


cells = defaultdict(list)
for i in instances:
    c = cell_of(i)
    if c:
        cells[c].append(i)

cell_orders = {}
TG = 1e-8
for c, insts in sorted(cells.items(), key=lambda kv: (int(kv[0][0]), int(kv[0][1]),
                                                      float(kv[0][2]))):
    med = {}
    for s in SOLVERS:
        cs = [cost_to(curves[(i, s)], TG, 1) for i in insts if (i, s) in curves]
        good = [x for x in cs if x is not None]
        med[s] = median(good) if good else None
    cell_orders[c] = tuple(rank(med))

by_order = defaultdict(list)
for c, o in cell_orders.items():
    by_order[o].append(c)

emit(f"{len(cells)} cells, **{len(by_order)}** distinct orderings.")
emit("")
emit("| ordering (cheapest first) | cells | example |")
emit("|---|---:|---|")
for o, cs in sorted(by_order.items(), key=lambda kv: -len(kv[1])):
    ex = cs[0]
    emit(f"| {' < '.join(o) if o else '(none reached)'} | {len(cs)} | "
         f"r={ex[0]} m={ex[1]} d={ex[2]} |")
emit("")
if len(by_order) > 1:
    emit("Orderings DO differ by regime. The cells that differ from the majority")
    emit("ordering are the paper's exhibit; report them with their (r, m, delta).")
else:
    emit("No cell departs from the global ordering: the ranking is invariant across")
    emit("the whole degeneracy grid, not merely on average.")
emit("")

# ------------------------------------------------------------- exits
emit("## 8. Exit reasons")
emit("")
emit("| solver | exit | count |")
emit("|---|---|---:|")
ec = defaultdict(int)
for (i, s), e in exits.items():
    ec[(s, e)] += 1
for s in SOLVERS:
    for (ss, e), c in sorted(ec.items()):
        if ss == s:
            emit(f"| {s} | {e} | {c} |")

emit("")

# =====================================================================
# Gap 3 additions (2026-09-11): uncertainty quantification. Sections 1-8
# above are unchanged. Everything below uses accepted-only accounting and
# the forward-error criterion, with the CORRECTED reach rule (cost_to_fixed).
# =====================================================================
import numpy as np


def cost_to_fixed(curve, target, col=1):
    """Accepted-only EVDs at the first accepted iterate from which the target holds
    to the end of the run. cost_to (Sec. 2-7, kept verbatim for reproducibility)
    returns None at the FIRST dip below target if that dip is not held, even when
    the run later settles below target; see audit_cost_to.py."""
    acc = [p for p in curve if p[3]]
    if not acc or acc[-1][col] > target:
        return None
    k = len(acc) - 1
    while k > 0 and acc[k - 1][col] <= target:
        k -= 1
    return acc[k][0]


emit("## 12. Sections 2 and 7 recomputed with the corrected reach rule")
emit("")
emit("`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is")
emit("not held, even if it later settles below eps. Corrected: cost = EVDs at the")
emit("start of the final sub-eps suffix. Sections 9-11 below also use this rule.")
emit("")
emit("| eps | " + " | ".join(SOLVERS) + " | ordering (cheapest first) |")
emit("|---|" + "---:|" * len(SOLVERS) + "---|")
for tg in FWD_EPS:
    med, cells_ = {}, []
    for s in SOLVERS:
        cs = [cost_to_fixed(curves[(i, s)], tg) for i in instances if (i, s) in curves]
        good = [c for c in cs if c is not None]
        med[s] = median(good) if good else None
        cells_.append(f"{med[s]:.1f} ({len(good)}/{len(cs)})" if good else f"-- (0/{len(cs)})")
    emit(f"| {tg:.0e} | " + " | ".join(cells_) + f" | {' < '.join(rank(med))} |")
emit("")
if cells:
    fo = {}
    for c, insts in cells.items():
        med = {}
        for s in SOLVERS:
            cs = [cost_to_fixed(curves[(i, s)], TG) for i in insts if (i, s) in curves]
            good = [x for x in cs if x is not None]
            med[s] = median(good) if good else None
        fo[c] = tuple(rank(med))
    bo = defaultdict(list)
    for c, o in fo.items():
        bo[o].append(c)
    emit(f"Per-cell at forward 1e-08, corrected rule: {len(cells)} cells, "
         f"**{len(bo)}** distinct orderings (Sec. 7: {len(by_order)}); "
         f"cells whose ordering changed: {sum(fo[c] != cell_orders[c] for c in cells)}.")
    emit("")
    ranks = sorted({c[0] for c in cells}, key=int)
    emit("| ordering (cheapest first) | cells | "
         + " | ".join(f"r={r}" for r in ranks) + " | example |")
    emit("|---|---:|" + "---:|" * len(ranks) + "---|")
    for o, cs in sorted(bo.items(), key=lambda kv: -len(kv[1])):
        ex = cs[0]
        per = " | ".join(str(sum(c[0] == r for c in cs)) for r in ranks)
        emit(f"| {' < '.join(o)} | {len(cs)} | {per} | r={ex[0]} m={ex[1]} d={ex[2]} |")
    emit("")
    cell_orders = fo  # Sec. 11 'observed ordering' = corrected-rule ordering

B = 2000
SEED = 20260911
PAIR_RE = re.compile(r"^degen-r(\d+)-m(\d+)-d([0-9.eE+-]+?)-p(\d+)$")
inst_idx = {i: k for k, i in enumerate(instances)}
parsed = {i: PAIR_RE.match(i) for i in instances}
M = {}  # M[(s, eps)] -> array of EVDs-to-target, nan = not reached / not run
for s in SOLVERS:
    for tg in FWD_EPS:
        a = np.full(len(instances), np.nan)
        for i in instances:
            if (i, s) in curves:
                c = cost_to_fixed(curves[(i, s)], tg)
                if c is not None:
                    a[inst_idx[i]] = c
        M[(s, tg)] = a


def nanmed(x):
    x = x[~np.isnan(x)]
    return float(np.median(x)) if x.size else np.nan


def fmt(x, p=0):
    return "--" if x is None or (isinstance(x, float) and np.isnan(x)) else f"{x:.{p}f}"


have_pairs = all(parsed[i] for i in instances)
if not have_pairs:
    emit("## 9-11. Bootstrap sections")
    emit("")
    emit("Instance names carry no paired-seed structure (real matrices), so no")
    emit("bootstrap is possible. Per-matrix EVDs to each forward target instead")
    emit("(`--` = not reached and held; forward error is against the COMPUTED")
    emit("reference, not an exact X*):")
    emit("")
    emit("| matrix | n | eps | " + " | ".join(SOLVERS) + " |")
    emit("|---|---:|---|" + "---:|" * len(SOLVERS))
    for i in instances:
        for tg in FWD_EPS:
            emit(f"| {i} | {ns[i]} | {tg:.0e} | " +
                 " | ".join(fmt(M[(s, tg)][inst_idx[i]]) for s in SOLVERS) + " |")
    emit("")
    emit("| matrix | " + " | ".join(SOLVERS) + " |")
    emit("|---|" + "---|" * len(SOLVERS))
    for i in instances:
        cells_ = []
        for s in SOLVERS:
            c = curves.get((i, s))
            if not c:
                cells_.append("--"); continue
            acc = [p for p in c if p[3]]
            cells_.append(f"{c[-1][0]} EVDs, {exits[(i, s)]}, err {acc[-1][1]:.1e}"
                          if acc else f"{c[-1][0]} EVDs, {exits[(i, s)]}")
        emit(f"| {i} | " + " | ".join(cells_) + " |")
    emit("")
else:
    rng = np.random.default_rng(SEED)
    rank_of = np.array([int(parsed[i].group(1)) for i in instances])
    pair_of = np.array([int(parsed[i].group(4)) for i in instances])
    groups = {}  # rank -> {pair -> index array}
    for r in sorted(set(rank_of)):
        groups[r] = {p: np.where((rank_of == r) & (pair_of == p))[0]
                     for p in sorted(set(pair_of[rank_of == r]))}

    def draw():
        parts = []
        for r, g in groups.items():
            keys = list(g.keys())
            for p in rng.choice(keys, size=len(keys), replace=True):
                parts.append(g[p])
        return np.concatenate(parts)

    draws = [draw() for _ in range(B)]

    # ------------------------------------------------ 9. medians with CIs
    emit("## 9. Cluster-bootstrap CIs on median EVDs to forward target")
    emit("")
    emit(f"B={B}, seed={SEED}. Resampling unit: the paired seed within rank (all")
    emit("18 (m, delta) cells of a drawn pair come together), which respects the")
    emit("pairing of the design. Percentile 95% intervals. Medians are over the")
    emit("instances that reached and held the target (as in Sec. 2), so they are")
    emit("conditioned on the reached subset wherever reach < total.")
    emit("")
    emit("| eps | " + " | ".join(SOLVERS) + " |")
    emit("|---|" + "---|" * len(SOLVERS))
    for tg in FWD_EPS:
        row = []
        for s in SOLVERS:
            a = M[(s, tg)]
            obs = nanmed(a)
            bs = np.array([nanmed(a[d]) for d in draws])
            bs = bs[~np.isnan(bs)]
            reach = int((~np.isnan(a)).sum())
            if bs.size:
                lo, hi = np.percentile(bs, [2.5, 97.5])
                row.append(f"{fmt(obs,1)} [{lo:.1f}, {hi:.1f}] ({reach}/{len(a)})")
            else:
                row.append(f"-- ({reach}/{len(a)})")
        emit(f"| {tg:.0e} | " + " | ".join(row) + " |")
    emit("")

    # -------------------------------------------- 10. paired SBB vs AGD
    from scipy.stats import binomtest

    emit("## 10. Paired per-instance comparison: SBB-Dual vs AGD")
    emit("")
    emit("d = EVDs(SBB-Dual) - EVDs(AGD) on the SAME instance; d < 0 means SBB is")
    emit("cheaper. 'both' = instances where both reached and held the target; the")
    emit("median, CI, fraction and sign test use only these. Instances where only one")
    emit("reached are counted, not dropped: the 'fail-as-loss' sign test counts a")
    emit("solver that failed while the other reached as the more expensive one.")
    emit("Ties (d = 0) are excluded from sign tests. CI: cluster bootstrap as Sec. 9.")
    emit("")
    for agd in ("AGD-SDAJ-BH", "AGD-SDAJ"):
        emit(f"### SBB-Dual vs {agd}")
        emit("")
        emit("| eps | both | SBB only | AGD only | neither | median d [95% CI] | "
             "frac SBB cheaper (both) | ties | sign test p (both) | "
             "SBB wins / losses incl. failures | sign test p (fail-as-loss) |")
        emit("|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|")
        for tg in FWD_EPS:
            a, b = M[("SBB-Dual", tg)], M[(agd, tg)]
            ra, rb = ~np.isnan(a), ~np.isnan(b)
            both = ra & rb
            d = a - b  # nan unless both reached
            obs = nanmed(d)
            bs = np.array([nanmed(d[x]) for x in draws])
            bs = bs[~np.isnan(bs)]
            ci = (f"[{np.percentile(bs, 2.5):.1f}, {np.percentile(bs, 97.5):.1f}]"
                  if bs.size else "--")
            db = d[both]
            wins, losses, ties = int((db < 0).sum()), int((db > 0).sum()), int((db == 0).sum())
            p1 = binomtest(wins, wins + losses, 0.5).pvalue if wins + losses else np.nan
            w2 = wins + int((ra & ~rb).sum())
            l2 = losses + int((~ra & rb).sum())
            p2 = binomtest(w2, w2 + l2, 0.5).pvalue if w2 + l2 else np.nan
            frac = wins / both.sum() if both.sum() else np.nan
            emit(f"| {tg:.0e} | {int(both.sum())} | {int((ra & ~rb).sum())} | "
                 f"{int((~ra & rb).sum())} | {int((~ra & ~rb).sum())} | "
                 f"{fmt(obs,1)} {ci} | {frac:.3f} | {ties} | {p1:.2e} | "
                 f"{w2} / {l2} | {p2:.2e} |")
        emit("")
        # by rank, at each eps: this is what the 'r >= 20' claim rests on
        emit(f"By rank (SBB-Dual vs {agd}): median d over 'both' and frac SBB cheaper")
        emit("")
        emit("| eps | " + " | ".join(f"r={r}" for r in groups) + " |")
        emit("|---|" + "---|" * len(groups))
        for tg in FWD_EPS:
            a, b = M[("SBB-Dual", tg)], M[(agd, tg)]
            d = a - b
            row = []
            for r in groups:
                msk = (rank_of == r) & ~np.isnan(d)
                if msk.sum():
                    row.append(f"{np.median(d[msk]):+.1f} ({(d[msk] < 0).mean():.2f}, n={int(msk.sum())})")
                else:
                    row.append("--")
            emit(f"| {tg:.0e} | " + " | ".join(row) + " |")
        emit("")

    # ------------------------------------------ 11. per-cell stability
    emit("## 11. Per-cell ordering stability (target forward 1e-08)")
    emit("")
    emit(f"Each (r, m, delta) cell has 5 paired seeds. Its 5 instances are resampled")
    emit(f"with replacement (B={B}); the ordering is recomputed exactly as in Sec. 7")
    emit("(median over instances that reached; a solver reaching on none is omitted).")
    emit("'reproduce' = fraction of resamples giving the observed Sec. 7 ordering.")
    emit("A pairwise order is RESOLVED only if the 95% bootstrap CI of the median")
    emit("paired difference excludes 0; for these paired differences a solver that")
    emit("failed to reach the target on an instance is given cost +inf (so failing is")
    emit("worse than any finite cost; inf-inf counts as a tie). Unresolved adjacent")
    emit("pairs in the observed ordering are shown as '='.")
    emit("")
    TG11 = 1e-8
    SHORT = {"Newton-SIN-BH": "N", "AGD-SDAJ-BH": "Abh", "AGD-SDAJ": "A",
             "SBB-Dual": "S", "Dykstra-APM": "D", "Anderson-APM": "AA"}
    cell_idx = defaultdict(list)
    for i in instances:
        mo = parsed[i]
        cell_idx[(mo.group(1), mo.group(2), mo.group(3))].append(inst_idx[i])
    Minf = {s: np.where(np.isnan(M[(s, TG11)]), np.inf, M[(s, TG11)]) for s in SOLVERS}

    def order_of(ix):
        med = {}
        for s in SOLVERS:
            v = nanmed(M[(s, TG11)][ix])
            med[s] = None if np.isnan(v) else v
        return tuple(rank(med))

    emit("| cell (r,m,d) | observed ordering | reproduce | resolved pairs /10 | tie-aware ordering |")
    emit("|---|---|---:|---:|---|")
    obs_orders, tie_orders, repro_all, full_resolved = {}, {}, [], 0
    for c in sorted(cell_idx, key=lambda k: (int(k[0]), int(k[1]), float(k[2]))):
        ix = np.array(cell_idx[c])
        obs = order_of(ix)
        bsd = [rng.choice(ix, size=ix.size, replace=True) for _ in range(B)]
        repro = np.mean([order_of(x) == obs for x in bsd])
        resolved = {}
        for ai in range(len(SOLVERS)):
            for bi in range(ai + 1, len(SOLVERS)):
                sa, sb = SOLVERS[ai], SOLVERS[bi]
                d = Minf[sa] - Minf[sb]
                d = np.where(np.isnan(d), 0.0, d)
                meds = np.array([np.median(d[x]) for x in bsd])
                lo, hi = np.percentile(meds, [2.5, 97.5])
                resolved[frozenset((sa, sb))] = bool(lo > 0 or hi < 0)
        nres = sum(resolved.values())
        if nres == 10:
            full_resolved += 1
        tie = SHORT[obs[0]] if obs else ""
        for u, v in zip(obs, obs[1:]):
            tie += (" < " if resolved[frozenset((u, v))] else " = ") + SHORT[v]
        obs_orders[c], tie_orders[c] = obs, tie
        repro_all.append(repro)
        emit(f"| r={c[0]} m={c[1]} d={c[2]} | {' < '.join(SHORT[s] for s in obs)} | "
             f"{repro:.3f} | {nres} | {tie} |")
    emit("")
    emit("N=Newton-SIN-BH, Abh=AGD-SDAJ-BH, A=AGD-SDAJ, S=SBB-Dual, D=Dykstra-APM.")
    emit("")
    from collections import Counter
    oc = Counter(obs_orders.values())
    tc = Counter(tie_orders.values())
    robust = {o for c, o in obs_orders.items() if "=" not in tie_orders[c]}
    emit(f"- Observed distinct orderings (Sec. 7): **{len(oc)}** over {len(obs_orders)} cells.")
    emit(f"- Median reproduce fraction across cells: **{np.median(repro_all):.3f}**; "
         f"cells with reproduce >= 0.5: {sum(r >= 0.5 for r in repro_all)}; "
         f">= 0.8: {sum(r >= 0.8 for r in repro_all)}.")
    emit(f"- Cells whose full 5-solver ordering is resolved (all adjacent pairs): "
         f"**{sum('=' not in t for t in tie_orders.values())}**; all 10 pairs resolved: "
         f"{full_resolved}.")
    emit(f"- Distinct observed orderings realised by at least one fully-resolved cell: "
         f"**{len(robust)}** of {len(oc)}.")
    emit(f"- Distinct tie-aware orderings: **{len(tc)}**.")
    emit("")
    emit("| tie-aware ordering | cells |")
    emit("|---|---:|")
    for o, k in tc.most_common():
        emit(f"| {o} | {k} |")
    emit("")
    # the specific pairwise orders the Sec. 7 narrative uses
    emit("Resolved status of the pairwise orders the narrative relies on (cells where")
    emit("the pair is resolved in each direction / unresolved):")
    emit("")
    emit("| pair | first cheaper (resolved) | second cheaper (resolved) | unresolved |")
    emit("|---|---:|---:|---:|")
    for sa, sb in (("SBB-Dual", "AGD-SDAJ-BH"), ("SBB-Dual", "AGD-SDAJ"),
                   ("AGD-SDAJ-BH", "Dykstra-APM"), ("AGD-SDAJ", "Dykstra-APM"),
                   ("AGD-SDAJ-BH", "AGD-SDAJ"), ("Newton-SIN-BH", "SBB-Dual")):
        fa = fb = un = 0
        for c, ix in cell_idx.items():
            ix = np.array(ix)
            d = Minf[sa][ix] - Minf[sb][ix]
            d = np.where(np.isnan(d), 0.0, d)
            meds = np.array([np.median(d[rng.choice(ix.size, ix.size)]) for _ in range(B)])
            lo, hi = np.percentile(meds, [2.5, 97.5])
            if hi < 0:
                fa += 1
            elif lo > 0:
                fb += 1
            else:
                un += 1
        emit(f"| {sa} vs {sb} | {fa} | {fb} | {un} |")
    emit("")

if outpath:
    with open(outpath, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    print(f"\nwrote {outpath}")
