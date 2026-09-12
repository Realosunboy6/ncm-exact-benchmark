# Paper 2: literature and novelty audit (Gap 4)

Date: 2026-09-11. Scope: contributions (a)–(e) of Paper 2 ("Exact and reproducible benchmarking
for NCM solvers"). Method: web research only, no computation. Every bibliographic record marked
VERIFIED was checked against its Crossref DOI record (title, authors, venue, volume, pages, year).
Content claims are marked by how they were checked: read directly (full text / abstract), or
secondary (search snippets or third-party docs only).

## 0. Summary table

| # | Contribution | Verdict | Closest prior work | Key risk |
|---|---|---|---|---|
| (a) | KKT-constructed exact-solution NCM family (prescribed rank, beta-multiplicity, separation; paired seeds; `\|G_ij\|<=1` propositions) | **INCREMENTAL** (NCM specialisation is new as far as searched; the construction principle is not) | Wei & Wolkowicz 2010 (SDP instances with prescribed complementarity nullity via optimality conditions); Calamai–Vicente–Júdice 1993, Lenard–Minkoff 1984, Moré–Garbow–Hillstrom 1981 (known-solution generators) | Presenting "construct G from a chosen KKT pair" as a new idea. It is the standard reverse-KKT generator technique. |
| (b) | Protocol: EVD-atom work–accuracy trajectories, accepted-only accounting, matched forward error vs exact X*, primitive-work table, timing protocol | **INCREMENTAL** | Moré & Wild 2009 (data profiles, cost measured in function evaluations, convergence test relative to best-found value); Dolan & Moré 2002; Dolan, Moré & Munson 2006; Beiranvand, Hare & Lucet 2017; Hansen et al. 2021 (COCO: runtime-to-target, anytime ECDFs); Hairer & Wanner 1996 (work–precision diagrams) | Each ingredient has a precedent. What's new is combining them for NCM with an *exact* reference, which is what makes the forward-error axis possible. |
| (c) | Naive objective-value Armijo stalls in finite precision near the solution; replicated in semismooth Newton and in Huynh–Hwang AGD-SDAJ; fixed by BH line search | **KNOWN phenomenon; the replication is new** | Borsdorf 2007 MSc thesis §4.7.1 (derives exactly this: stagnation once `\|\|grad theta\|\|^2` is about `sqrt(A)`, A ~ ULP of theta, so tol < ~1e-8 is unreachable, and notes it is general to Armijo); Borsdorf & Higham 2010 (the published fix); Hager & Zhang 2005 (approximate Wolfe, designed for this cancellation in general) | Must not be called a discovery. Borsdorf 2007 even predicts the threshold. |
| (d) | Dimension-scaled stopping rule `\|\|grad theta\|\| <= 1e-7 n`: native-exit accuracy spans 383x; zero-update exits | **INCREMENTAL** (the NCM-specific quantification is new) | Dolan, Moré & Munson 2006 (solver-specific stopping tests bias performance profiles; they propose a common optimality measure); Beiranvand et al. 2017 | The general point that native stopping rules confound comparisons is well established. Frame it as a documented NCM instance of that point. |
| (e) | Ranking reversals: winner invariant; 2nd/3rd swap with target; 9 orderings over 54 degeneracy cells | **INCREMENTAL / empirical** | Moré & Wild 2009 and COCO (rankings depend on accuracy level tau / target); Gould & Scott 2016 (profile rankings are unstable when solvers are added or removed) | Accuracy-dependent ranking is expected in principle. The new part is that controlled degeneracy isolates *which* instance axis (rank r) drives the ordering, which no NCM test set could do. |

**Novelty threat to (a).** No prior work found that builds NCM instances with an exact known
nearest correlation matrix by the KKT route. NCM test sets in the papers examined are all random or
real-data, with references computed approximately:
- Higham 2002;
- Qi & Sun 2006, experiments 5.5–5.8, `randcorr + noise` and similar, reused by Armijo, Bello-Cruz & Haeser 2025;
- Borsdorf 2007, Examples 1–3;
- Borsdorf & Higham 2010;
- Higham & Strabić 2016;
- Huynh & Hwang 2025, Anymatrix CORRINV real-data matrices.

However, **Wei & Wolkowicz (2010)** is a direct methodological precedent for general SDP. They
generate instances from chosen primal–dual optimal pairs with a prescribed *complementarity
nullity*, which is the same idea as Paper 2's beta-multiplicity (`#{j: mu_j = 0}`), and show it
correlates with iteration counts. The reverse-KKT idea also goes back to QP generators
(Calamai–Vicente–Júdice 1993; Lenard–Minkoff 1984). Contribution (a) must therefore be framed as:
*the specialisation of the known-solution/prescribed-complementarity construction to the NCM
problem*. The genuinely new elements are the NCM-specific structure:
- the projection identity `Pi_{S+}(G + Diag y*) = X*`;
- the independent control of rank, beta-multiplicity and separation rho;
- the paired-seed design;
- the `|G_ij| <= 1` feasibility propositions with fixed-rank saturation (Prop. 2.3b);
- the released instance set.

Degeneracy vocabulary: Qi & Sun 2006 show constraint nondegeneracy always holds for NCM. The
degeneracy Paper 2 controls is failure of **strict complementarity** (zero eigenvalues of
`C(y*)`), not constraint degeneracy. State this explicitly, or referees will object.

## 1. Benchmarking methodology: what (b), (d), (e) add

**Dolan & Moré 2002 (performance profiles).** Performance ratios against the best solver per
problem. Solver cost comes from native termination, so the solver's own stopping test implicitly
defines accuracy.
- **Paper 2 adds:** accuracy fixed externally, by forward error against exact X*. The native-exit
  confound that performance profiles inherit is measured directly (383x).

**Dolan, Moré & Munson 2006 (optimality measures for performance profiles).** They state
explicitly that differing stopping criteria bias profiles, and propose rerunning under a common
optimality/feasibility measure. This is the closest precedent for (d) and for the "matched
tolerance" half of (b).
- **Paper 2 adds:** a common *forward-error* criterion (only possible with a known solution)
  alongside the common residual. Paper 2 finds the two give the same orderings here; that is
  worth reporting.

**Moré & Wild 2009 (data profiles).** Cost is counted in a problem-independent unit (function
evaluations, normalised by n+1). Convergence is tested as reduction to within tau of the best
value found by any solver. Rankings are shown across several tau.
- This is the template for EVD-as-cost-atom and for accuracy-dependent ranking (e).
- **Paper 2 adds:** the reference is exact rather than "best found". Accepted-only accounting
  (charge rejected trials, never credit them) is a rule Moré–Wild do not need, because every
  evaluation there is a sample. Also new are a validation that the unit preserves rank
  (per-EVD cost spread 1.37x; ranking by wall clock identical to ranking by EVDs) and a primitive
  table exposing Krylov work hidden inside an "EVD".

**Beiranvand, Hare & Lucet 2017.** A best-practice survey covering test-set selection,
known-solution test problems, stopping criteria, performance measures, profiles, and
reproducibility.
- **Paper 2 adds:** a worked, domain-specific instantiation; nothing methodologically foreign to
  their checklist. Cite them as the framework Paper 2 follows.

**Gould & Scott 2016.** Performance-profile rankings beyond the leading solver change when the
solver set changes. Relevant to (e).
- Paper 2's 2nd/3rd reversals come from the accuracy target and instance regime, with a fixed
  solver set, so they are a different mechanism. Say so.

**Hansen et al. 2021 (COCO).** Fixed-target runtimes, ECDFs over a range of targets, and an
anytime view, all against functions with known optimum `f_opt`. COCO already uses known optima
and a target ladder.
- **Paper 2 adds** the same philosophy for a structured matrix problem with a *matrix*
  forward-error target, where known optima previously did not exist.

**Hairer & Wanner 1996 (work–precision diagrams).** Standard in ODE solver comparison: error
against a reference solution plotted against work, across tolerances. Paper 2's trajectories
are work–precision diagrams.
- Cite this and adopt the name, rather than presenting trajectories as new.

**Bottom line for (b)/(d)/(e).** The individual principles are established. The contribution is
(i) making the exact-reference versions possible for NCM through (a), and (ii) quantifying the
specific NCM confounds:
- 383x native-exit spread;
- zero-update exits under `1e-7 n`;
- hidden Krylov work;
- rejected-trial crediting producing spurious crossings.

## 2. Test problems with known solutions / prescribed degeneracy

Checked in full or in part:
- **Wei & Wolkowicz 2010**: see §0. They generate SDP instances whose optimal primal–dual pair
  is known by construction, with a chosen complementarity nullity. Closest precedent. VERIFIED
  bibliographically; abstract confirmed via Optimization Online / search.
- **Calamai, Vicente & Júdice 1993**: generates QP test problems with known global/local minima
  (reverse construction from optimality conditions). VERIFIED.
- **Lenard & Minkoff 1984**: randomly generated positive-definite QPs with known solution and
  controllable conditioning/degeneracy. VERIFIED.
- **Moré, Garbow & Hillstrom 1981**: classic unconstrained test set with known minimisers.
  VERIFIED.
- **NCM test sets**:
  - Higham 2002: random/finance data, no known solution.
  - Qi–Sun 2006: randcorr-plus-noise and similar random families (confirmed by reading their
    reuse in Armijo–Bello-Cruz–Haeser 2025, Sec. 5, which states they follow [Qi–Sun]).
  - Borsdorf 2007: Examples 1–3, randcorr + uniform noise, random symmetric with unit diagonal,
    and block combinations. Read directly; none has an exact known solution.
  - Higham & Mikaitis 2022 (Anymatrix), used by Huynh–Hwang 2025 via CORRINV: real invalid
    correlation matrices, no known solution.
- **Other**: no NCM paper found (2002–2026 searches) that constructs `G` from a chosen `X*` and
  multiplier `y*`. Limitation: the Qi–Sun 2006 and Borsdorf–Higham 2010 full texts were not read
  directly (paywalled); test descriptions are inferred from secondary reuse and the Borsdorf
  thesis.

**Required reframing of (a):** "Following the standard practice of generating instances from
prescribed optimality conditions [Calamai et al. 1993; Lenard–Minkoff 1984], and in particular
Wei and Wolkowicz's generator of SDP instances with prescribed complementarity nullity [2010], we
construct NCM instances whose nearest correlation matrix, dual solution and strict-complementarity
gap are known exactly." Then list the NCM-specific results as the contribution.

## 3. NCM algorithms and the finite-precision Armijo issue (c)

Context references (all VERIFIED bibliographically):
- Higham 2002 (alternating projections / Dykstra);
- Malick 2004 (dual approach, quasi-Newton on the dual);
- Boyd & Xiao 2005 (dual, projected gradient / quasi-Newton);
- Qi & Sun 2006 (semismooth Newton, quadratic convergence, constraint nondegeneracy);
- Borsdorf & Higham 2010 (preconditioned Newton, MINRES + Jacobi, line-search refinements;
  basis of NAG g02aa, per NAG docs);
- Borsdorf, Higham & Raydan 2010 (factor structure);
- Higham & Strabić 2016a (Anderson acceleration of alternating projections, Numer. Algorithms);
- Higham & Strabić 2016b (distance bounds, SIMAX);
- Li & Fukushima 2000 (derivative-free nonmonotone line search; the form used in Huynh–Hwang
  eq. (6));
- Andrei 2006 (acceleration of gradient descent with backtracking; the acceleration factor);
- Huynh & Hwang 2025 (AGD-SDAJ);
- Armijo, Bello-Cruz & Haeser 2025 (semismooth Newton for general projection equations, NCM
  experiments with Dolan–Moré profiles).

NAG g02aa documentation (read): an inexact Newton method on the dual "with improvements
suggested by Borsdorf and Higham (2010)". Default `errtol` = n × machine precision. The docs give
no line-search detail. Note: the NAG page gives Qi–Sun as volume 29; Crossref says **28(2)**,
which is the value used in the .bib.

**Prior reports of finite-precision Armijo stagnation (read directly):**
- **Borsdorf (2007), MSc thesis, Manchester, MIMS EPrint 1085, §4.7.1 "Armijo Backtracking
  Rule".**
  - He shows that when `theta(y_{k+1})` and `theta(y_k)` coincide in floating point, the
    left-hand side of the Armijo test becomes numerically zero, backtracking hits its cap, and
    the outer loop stalls.
  - He derives the approximate bound `||grad theta||_2 ≳ sqrt(A)`, with A about the ULP of theta.
    With A ~ 1e-16 the rule fails once `||grad theta||` reaches ~1e-8, so tolerances below 1e-8
    cannot be expected to work.
  - He notes it is "a general problem of the Armijo backtracking rule".
  - He proposes alternatives (skip Armijo and take the unit Newton step, or use a
    gradient-norm-based acceptance test). This is the origin of the BH 2010 modification.
  - Borsdorf & Higham 2010 lists "Armijo line search conditions" and "rounding error" among its
    keywords (publisher page).
- **General optimisation:** Hager & Zhang 2005 introduce *approximate Wolfe* conditions because
  the standard sufficient-decrease test cannot be evaluated accurately near a minimiser. The
  function-value difference suffers cancellation, limiting accuracy to about the square root of
  machine epsilon. They replace it with a derivative-based test. Bibliography VERIFIED; the
  motivation was confirmed via secondary sources (the TensorFlow Probability `hager_zhang` docs
  and search excerpts quoting the paper). Also relevant: Nocedal & Wright discuss rounding in line
  searches (not added to .bib, edition/DOI not checked).
- **No other NCM/SDP-dual paper was found reporting this stall**, and none was found reporting it
  in AGD-SDAJ. The Huynh–Hwang stopping rule `1e-7 n` stops well above the floor, which is
  consistent with the local finding that their published results are unaffected.

**Framing for (c):** "The failure of objective-value sufficient-decrease tests in floating point
near a minimiser is well known [Hager–Zhang 2005], and was analysed for the NCM dual by Borsdorf
[2007, §4.7.1], motivating the modified step selection of Borsdorf and Higham [2010]. We show that
the defect is not confined to Newton implementations: it recurs in a separately published
first-order method [Huynh–Hwang 2025] that uses a naive Armijo test. On the exact-solution family
it causes 56/270 and 18/270 stalls respectively, and the Borsdorf–Higham correction removes both.
Its onset is predicted by the ULP margin (AUC 0.934)."

## 4. Verdicts and framing sentences

- **(a) INCREMENTAL.** *"We specialise the prescribed-optimality-condition generator [Wei &
  Wolkowicz 2010; Calamai et al. 1993] to the nearest correlation matrix problem. This gives
  instances with exact `X*`, `y*`, prescribed rank, strict-complementarity defect and eigenvalue
  separation, together with sufficient conditions for the input to be a valid invalid-correlation
  input (`|G_ij| <= 1`) and a proof that no fixed-rank uniform-mu bound survives `n -> infinity`."*
- **(b) INCREMENTAL.** *"Our protocol adapts data profiles [Moré & Wild 2009], fixed-target
  evaluation [Hansen et al. 2021] and work–precision diagrams [Hairer & Wanner 1996] to spectral
  solvers. Its cost unit is one EVD, validated against wall clock, and it follows two accounting
  rules that exact references make enforceable: accepted-only credit and matched forward error."*
- **(c) KNOWN + new replication.** Use the sentence at the end of §3. Never use "we discover".
- **(d) INCREMENTAL.** *"As Dolan, Moré & Munson [2006] warned for general solvers, native stopping
  tests confound comparisons. For NCM, the widely used dimension-scaled rule `||grad theta|| <= 1e-7 n`
  produces native-exit forward errors spanning 383x across solvers, and exits with zero updates at
  n = 500."*
- **(e) INCREMENTAL (empirical).** *"Consistent with the accuracy dependence built into data
  profiles, the leading solver is invariant but second and third place reverse between loose and
  tight targets. Across the controlled degeneracy grid, 54 cells yield 9 orderings, with rank the
  dominant covariate; this is attributable only because the family varies one spectral axis at a
  time."* Report the winner-invariance null result prominently.

## 5. Venues

1. **Mathematical Programming Computation (Springer).** Its remit is computational methodology
   and software. It requires code submission, and a technical editor attempts to reproduce the
   results. Best fit if the released instance set, generator and solvers are packaged cleanly. The
   reproducibility bar is the highest of the options listed.
2. **Optimization Methods and Software (Taylor & Francis).** Published COCO (Hansen et al. 2021)
   and Li–Fukushima. It welcomes benchmarking/methodology papers, and is a natural home for
   protocol plus implementation-trap findings. No mandatory artifact review.
3. **Numerical Linear Algebra with Applications (Wiley).** Huynh–Hwang 2025 appeared there, so
   the audience includes the method authors and NCM users. It fits the matrix-structured family.
   Data/code availability statement expected; no artifact review.
4. **ACM Transactions on Mathematical Software.** Suits a software/test-collection framing
   (Anymatrix-like instance release, Gould–Scott appeared there). It has a Replicated Computational
   Results (RCR) option for artifact certification. Choose this if the generator and instance
   collection become the headline.

SIAM J. Sci. Comput. (Software and High-Performance Computing section) is possible but less
natural for a benchmarking-methodology paper. The venue policies above are from general knowledge
of these journals and were not re-checked against the current author guidelines, so confirm them
before submission.

## 6. Source list and verification status

VERIFIED = Crossref DOI record matched. All VERIFIED items are in `paper2-lit.bib`.

| Key | Source | Status |
|---|---|---|
| higham2002nearest | Higham, IMA J Numer Anal 22(3):329–343, 2002, 10.1093/imanum/22.3.329 | VERIFIED |
| malick2004dual | Malick, SIMAX 26(1):272–284, 2004, 10.1137/S0895479802413856 | VERIFIED |
| boyd2005least | Boyd & Xiao, SIMAX 27(2):532–546, 2005, 10.1137/040609902 | VERIFIED |
| qisun2006quadratically | Qi & Sun, SIMAX 28(2):360–385, 2006, 10.1137/050624509 | VERIFIED |
| borsdorf2007newton | Borsdorf, MSc thesis, Univ. Manchester, 2007, MIMS EPrint 1085 (no DOI) | VERIFIED (eprint page + full text read) |
| borsdorf2010preconditioned | Borsdorf & Higham, IMA J Numer Anal 30(1):94–107, 2010, 10.1093/imanum/drn085 | VERIFIED |
| borsdorf2010factor | Borsdorf, Higham & Raydan, SIMAX 31(5):2603–2622, 2010, 10.1137/090776718 | VERIFIED |
| higham2016anderson | Higham & Strabić, Numer Algorithms 72:1021–1042, 2016, 10.1007/s11075-015-0078-3 | VERIFIED |
| higham2016bounds | Higham & Strabić, SIMAX 37(3):1088–1102, 2016, 10.1137/15M1052007 | VERIFIED |
| higham2022anymatrix | Higham & Mikaitis, Numer Algorithms 90:1175–1196, 2022, 10.1007/s11075-021-01226-2 | VERIFIED |
| huynh2025accelerated | Huynh & Hwang, NLA 32(6):e70045, 2025, 10.1002/nla.70045 | VERIFIED |
| armijo2025semismooth | Armijo, Bello-Cruz & Haeser, Optimization 75:2293–2315, 2025/26, 10.1080/02331934.2025.2547716 | VERIFIED |
| li2000derivative | Li & Fukushima, OMS 13(3):181–201, 2000, 10.1080/10556780008805782 | VERIFIED |
| andrei2006acceleration | Andrei, Numer Algorithms 42:63–73, 2006, 10.1007/s11075-006-9023-9 | VERIFIED |
| hager2005new | Hager & Zhang, SIOPT 16(1):170–192, 2005, 10.1137/030601880 | VERIFIED (motivation via secondary sources) |
| dolan2002benchmarking | Dolan & Moré, Math Program 91(2):201–213, 2002, 10.1007/s101070100263 | VERIFIED |
| dolan2006optimality | Dolan, Moré & Munson, SIOPT 16(3):891–909, 2006, 10.1137/040608015 | VERIFIED |
| more2009benchmarking | Moré & Wild, SIOPT 20(1):172–191, 2009, 10.1137/080724083 | VERIFIED |
| beiranvand2017best | Beiranvand, Hare & Lucet, Optim Eng 18(4):815–848, 2017, 10.1007/s11081-017-9366-1 | VERIFIED |
| gould2016note | Gould & Scott, ACM TOMS 43(2), art. 15, 2016, 10.1145/2950048 | VERIFIED |
| hansen2021coco | Hansen et al., OMS 36(1):114–144, 2021, 10.1080/10556788.2020.1808977 | VERIFIED |
| hairer1996solving | Hairer & Wanner, Solving ODEs II, Springer, 2nd ed. 1996, 10.1007/978-3-642-05221-7 | VERIFIED |
| wei2010generating | Wei & Wolkowicz, Math Program 125(1):31–45, 2010, 10.1007/s10107-008-0256-3 | VERIFIED |
| calamai1993new | Calamai, Vicente & Júdice, Math Program 61:215–231, 1993, 10.1007/BF01582148 | VERIFIED |
| lenard1984randomly | Lenard & Minkoff, ACM TOMS 10(1):86–96, 1984, 10.1145/356068.356075 | VERIFIED |
| more1981testing | Moré, Garbow & Hillstrom, ACM TOMS 7(1):17–41, 1981, 10.1145/355934.355936 | VERIFIED |
| — | NAG Library g02aa documentation (web page, read) | VERIFIED as a web source; cite as software doc, not in .bib |
| — | Nocedal & Wright, *Numerical Optimization* (rounding in line searches) | UNVERIFIED (edition/DOI not checked). Not in .bib |
| — | Ball 1997 / Vershynin 2018, cited in outline §2.3c for concentration | UNVERIFIED here (out of scope). Not in .bib |
| — | Calamai–Vicente "bilevel QP generator" (ACM TOMS) | UNVERIFIED (DOI not confirmed). Not in .bib; the 1993 Math Program paper with Júdice is used instead |

Not read in full (paywalled): Qi & Sun 2006, Borsdorf & Higham 2010, Wei & Wolkowicz 2010. Claims
about them rest on abstracts, publisher metadata, and the Borsdorf thesis. Before submission,
confirm (i) the exact wording of BH 2010 §3.3 and (ii) that Wei–Wolkowicz's construction does not
already cover least-squares SDPs (their paper targets linear SDPs).
