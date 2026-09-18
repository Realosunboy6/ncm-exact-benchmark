# Is rebuilding the PSD projection from the positive eigenpairs bit-identical to
# rebuilding it from all eigenpairs, over whole runs of Dykstra-APM and
# Anderson-APM? The full rebuild is what the ranking studies used (and what
# Higham's MATLAB does); the positive rebuild is what the dual methods use and
# is cheaper by one O(n^3) product per EVD. If every per-step forward error, EVD
# count, exit and returned matrix agree exactly, switching changes no result in
# the paper, only the timings.
#
# Usage (from code/):  NCM_STANDALONE=1 julia --project=. validation/check_projection_rebuild.jl
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(1)

function run_both(solver, G, Xref, tol)
    out = Dict{Symbol,Any}()
    for mode in (:full, :positive)
        HS_REBUILD[] = mode; DYKSTRA_REBUILD[] = mode
        t = Traj(Xref)
        r = solver == :dykstra ? dykstra_apm(G; tol=tol, maxit=2000, traj=t) :
                                 anderson_apm_fast(G; tol=tol, maxit=2000, traj=t)
        out[mode] = (r, [row.err_raw_fro for row in t.rows])
    end
    HS_REBUILD[] = :positive; DYKSTRA_REBUILD[] = :positive
    (ra, ea), (rb, eb) = out[:full], out[:positive]
    return ra.evds == rb.evds && ra.exit == rb.exit && ea == eb && ra.X == rb.X
end

sets = [("degen_instances_paired", nothing),
        ("degen_instances_n500_paired", ["degen-r5-m1-d0-p0", "degen-r5-m20-d1e-08-p0",
                                          "degen-r20-m5-d0-p0", "degen-r20-m20-d0.0001-p0",
                                          "degen-r50-m1-d1e-06-p0", "degen-r50-m20-d0-p0"])]
total = 0; identical = 0; bad = String[]
for (dir, only) in sets
    S = Dict(load_suite(dir)); XS = load_xstars(dir)
    names = only === nothing ? sort(collect(keys(S))) : only
    for nm in names, solver in (:dykstra, :anderson), tol in (1e-7 * size(S[nm], 1), 1e-11)
        global total += 1
        if run_both(solver, S[nm], XS[nm], tol)
            global identical += 1
        else
            push!(bad, "$nm $solver tol=$tol")
        end
    end
    @printf("%s: %d of %d runs bit-identical so far\n", dir, identical, total); flush(stdout)
end
@printf("\n%d of %d runs bit-identical (per-step errors, EVD counts, exits and returned matrices)\n", identical, total)
foreach(println, bad)
println("REBUILD CHECK DONE")
