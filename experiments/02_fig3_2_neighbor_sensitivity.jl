#!/usr/bin/env julia
# scripts/updated/fig_3_2.jl — Paper 3, Fig 3.2 (revision)
# Updates:
#   - remove main figure title
#   - drop per-bar trajectory text annotations (repetitive — 8 of 10 bars say
#     the same thing); annotate ONLY the flipped bars with their resulting
#     trajectory
#   - move side legend to a structured bottom strip
#   - convert the grey footnote into a black, properly-sized anchor-info line

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig3_2_neighbor_sensitivity"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading summary…")
SUMMARY = load_summary()
LOOKUP = summary_lookup(SUMMARY)

# Build 10 one-step neighbours of the anchor.
const M_VALS_R = [1,2,3,4]
const C_VALS_R = [1,2,3,4,5,6]
const O_VALS_R = collect(0.0:0.1:1.0)
const R_VALS_R = O_VALS_R; const E_VALS_R = O_VALS_R

function nbr_along(axis::Symbol)
    a = PRESENT_DAY_ANCHOR; out = NamedTuple[]
    if axis == :M
        iM = findfirst(==(a.M), M_VALS_R)
        iM > 1               && push!(out, (axis="M−", M=M_VALS_R[iM-1], C=a.C, O=a.O, R=a.R, E=a.E))
        iM < length(M_VALS_R)&& push!(out, (axis="M+", M=M_VALS_R[iM+1], C=a.C, O=a.O, R=a.R, E=a.E))
    elseif axis == :C
        iC = findfirst(==(a.C), C_VALS_R)
        iC > 1              && push!(out, (axis="C−", M=a.M, C=C_VALS_R[iC-1], O=a.O, R=a.R, E=a.E))
        iC < length(C_VALS_R)&& push!(out, (axis="C+", M=a.M, C=C_VALS_R[iC+1], O=a.O, R=a.R, E=a.E))
    elseif axis == :O
        iO = findfirst(==(round(a.O; digits=1)), O_VALS_R)
        iO > 1              && push!(out, (axis="O−", M=a.M, C=a.C, O=O_VALS_R[iO-1], R=a.R, E=a.E))
        iO < length(O_VALS_R)&& push!(out, (axis="O+", M=a.M, C=a.C, O=O_VALS_R[iO+1], R=a.R, E=a.E))
    elseif axis == :R
        iR = findfirst(==(round(a.R; digits=1)), R_VALS_R)
        iR > 1              && push!(out, (axis="R−", M=a.M, C=a.C, O=a.O, R=R_VALS_R[iR-1], E=a.E))
        iR < length(R_VALS_R)&& push!(out, (axis="R+", M=a.M, C=a.C, O=a.O, R=R_VALS_R[iR+1], E=a.E))
    elseif axis == :E
        iE = findfirst(==(round(a.E; digits=1)), E_VALS_R)
        iE > 1              && push!(out, (axis="E−", M=a.M, C=a.C, O=a.O, R=a.R, E=E_VALS_R[iE-1]))
        iE < length(E_VALS_R)&& push!(out, (axis="E+", M=a.M, C=a.C, O=a.O, R=a.R, E=E_VALS_R[iE+1]))
    end
    return out
end

NBRS = vcat([nbr_along(s) for s in (:M, :C, :O, :R, :E)]...)

a = PRESENT_DAY_ANCHOR
ai = LOOKUP[(a.M, a.C, round(a.O; digits=1), round(a.R; digits=1), round(a.E; digits=1))]
const ANCHOR_TRAJ = SUMMARY.trajectory[ai]
const ANCHOR_L    = SUMMARY.final_mean_leverage[ai]

function build_figure()
    fig = Figure(size = (820, 460))
    ax = Axis(fig[1, 1];
        xlabel = "Perturbed axis",
        ylabel = "ΔL̄ = L̄(neighbour) − L̄(anchor)",
        xticks = (1:length(NBRS), [n.axis for n in NBRS]),
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 11, yticklabelsize = 10,
        limits = ((0.4, length(NBRS) + 0.6), (-0.105, 0.085)),
    )

    bar_colors = String[]
    deltas     = Float64[]
    flip_idx   = Int[]
    flip_traj  = String[]
    for (k, n) in enumerate(NBRS)
        ni = LOOKUP[(n.M, n.C, round(n.O; digits=1), round(n.R; digits=1), round(n.E; digits=1))]
        L  = SUMMARY.final_mean_leverage[ni]
        tr = SUMMARY.trajectory[ni]
        push!(deltas, L - ANCHOR_L)
        flipped = tr != ANCHOR_TRAJ
        push!(bar_colors, flipped ? "#d53e4f" : "#4393c3")
        if flipped
            push!(flip_idx, k); push!(flip_traj, tr)
        end
    end

    barplot!(ax, 1:length(NBRS), deltas;
        color = bar_colors, strokecolor = :black, strokewidth = 0.6,
        gap = 0.25)
    hlines!(ax, [0]; color = :black, linewidth = 0.7)

    # Annotate ONLY the flipped bars with their resulting trajectory.
    # Place each label just outside the bar tip, rotated 90°, reading away
    # from the y=0 axis.
    for (k, traj) in zip(flip_idx, flip_traj)
        y = deltas[k]
        if y >= 0
            text!(ax, k, y + 0.003; text = "→ $traj",
                  fontsize = 10.5, color = :firebrick, font = :bold_italic,
                  rotation = π/2, align = (:left, :center))
        else
            text!(ax, k, y - 0.003; text = "→ $traj",
                  fontsize = 10.5, color = :firebrick, font = :bold_italic,
                  rotation = π/2, align = (:right, :center))
        end
    end

    # Bottom strip: anchor info (left) + color legend (right).
    bottom = fig[2, 1] = GridLayout()
    Label(bottom[1, 1],
        @sprintf("Anchor:  M=%d, C=%d, O=%.1f, R=%.1f, E=%.1f   →   %s   (L̄ = %.3f)",
                 a.M, a.C, a.O, a.R, a.E, ANCHOR_TRAJ, ANCHOR_L);
        fontsize = 11, color = :black, halign = :left, tellwidth = false)
    Legend(bottom[1, 2],
        [PolyElement(color = "#4393c3", strokecolor = :black, strokewidth = 0.6),
         PolyElement(color = "#d53e4f", strokecolor = :black, strokewidth = 0.6)],
        ["Trajectory unchanged", "Trajectory flipped"];
        orientation = :horizontal, halign = :right, framevisible = false,
        labelsize = 10.5, patchsize = (22, 14), tellwidth = false)
    colsize!(bottom, 1, Relative(0.62))
    colsize!(bottom, 2, Relative(0.38))

    rowsize!(fig.layout, 2, Auto(0.10))
    rowgap!(fig.layout, 6)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Sensitivity to one-step parameter perturbations from the present-day anchor (M=2, C=3, O=0.6, R=0.3, E=0.2). Bars show ΔL̄; red = flipped trajectory.",

    "main_findings" =>
        "Among the ten one-step parameter neighbours of the present-day anchor, only two flip the " *
        "trajectory classification: M− (M=2 → M=1) flips to Captured Hegemony with ΔL̄ ≈ −0.042; " *
        "O− (O=0.6 → 0.5) flips to Bipolar Standoff with ΔL̄ ≈ +0.002. The other eight perturbations " *
        "preserve the Competitive Tension classification, with |ΔL̄| ranging from ≈ 0.001 (C+) to " *
        "≈ 0.054 (M+). The largest leverage gain available from any one-step move is M+ (M=2 → " *
        "M=3): ΔL̄ ≈ +0.054 while remaining within Competitive Tension. Other than M, the four " *
        "knob axes (C, O, R, E) each produce |ΔL̄| in the range 0.001–0.022 — modest effects per " *
        "single-step. The asymmetric sensitivity tells the present-day reader: (1) the trajectory " *
        "is unstable along M (multipolarity) and O (openness); (2) within the stable C/R/E " *
        "neighbours, leverage gains and losses are modest; (3) adding a third sovereign builder " *
        "state (M=2 → M=3) is the single biggest leverage-positive move available without " *
        "leaving the Competitive Tension regime.",

    "detailed_findings" =>
        "This figure quantifies how robust the present-day classification is to single-parameter " *
        "perturbations. The anchor is the calibration point identified in the project's " *
        "documentation: M=2 (US/China duopoly), C=3 (≈3 frontier firms per state), O=0.6 " *
        "(DeepSeek-era openness), R=0.3 (low-medium regulation), E=0.2 (low autonomous " *
        "enforcement deployment). The anchor classifies as Competitive Tension with L̄ ≈ 0.528.\n\n" *
        "Construction: for each of the 5 parameter axes (M, C, O, R, E), construct one-step " *
        "neighbours in both directions on the grid used by the grand sweep (M step = 1; C step " *
        "= 1; O/R/E step = 0.1). For each neighbour, look up its mean final leverage and " *
        "dominant trajectory in the summary CSV. Plot ΔL̄ = L̄(neighbour) − L̄(anchor) as bars, " *
        "coloured blue if the trajectory classification stayed (Competitive Tension) or red if " *
        "it flipped. Annotate ONLY flipped bars with their resulting trajectory name — " *
        "unchanged bars don't need redundant labels.\n\n" *
        "Detailed neighbour values (axis → ΔL̄, trajectory):\n" *
        "  M−   −0.042   Captured Hegemony   (FLIP)\n" *
        "  M+   +0.054   Competitive Tension\n" *
        "  C−   +0.012   Competitive Tension\n" *
        "  C+   +0.001   Competitive Tension\n" *
        "  O−   +0.002   Bipolar Standoff    (FLIP)\n" *
        "  O+   −0.002   Competitive Tension\n" *
        "  R−   −0.014   Competitive Tension\n" *
        "  R+   +0.014   Competitive Tension\n" *
        "  E−   +0.022   Competitive Tension\n" *
        "  E+   −0.022   Competitive Tension\n\n" *
        "For Paper 3, this figure quantifies present-day fragility: the trajectory is stable to " *
        "C, R, E perturbations but unstable to M and O. The M asymmetry is the dominant fact in " *
        "the sweep (Fig 1.2's headline finding); this figure shows it as an immediate, " *
        "policy-relevant consequence — losing one sovereign builder state flips us into Captured " *
        "Hegemony, while adding one keeps us in Competitive Tension AND gains the most leverage."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
