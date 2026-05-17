#!/usr/bin/env julia
# scripts/updated/fig_3_3.jl — Paper 3, Fig 3.3 (revision, Option A)
# Updates:
#   - remove main figure title
#   - simplify the network to show only the TOP 7 confusion edges (was
#     anything ≥ 50, which created visual noise that competed with the
#     headline pairs)
#   - put edge-weight labels in white-background chips to prevent overlap
#   - replace the small grey footnote with a structured top-10 table on the
#     right of the figure
#   - bigger nodes, better label placement

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig3_3_confusion_network"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading summary…")
SUMMARY = load_summary()

# Compute symmetric ambiguous-pair counts.
function compute_pairs(s::SummaryData)
    pair = Dict{Tuple{String, String}, Int}()
    for i in eachindex(s.M)
        s.score_margin[i] < 0.05 || continue
        t1 = s.trajectory[i]
        t2 = display_traj(s.runner_up[i])
        t1 == t2 && continue
        k = t1 < t2 ? (t1, t2) : (t2, t1)
        pair[k] = get(pair, k, 0) + 1
    end
    return pair
end

PAIRS = compute_pairs(SUMMARY)
PAIRS_SORTED = sort(collect(PAIRS), by = x -> x[2], rev = true)

const TOP_NETWORK_EDGES = 7
const TOP_TABLE_ROWS    = 10

function build_figure()
    n = length(TRAJECTORY_ORDER)
    θ = [π/2 - 2π*(i-1)/n for i in 1:n]
    pos = Dict(TRAJECTORY_ORDER[i] => (cos(θ[i]), sin(θ[i])) for i in 1:n)

    # Shorter figure so the network (square via AxisAspect) fills its
    # column height. figure_padding kept tight to remove outer white margin.
    fig = Figure(size = (1180, 540), figure_padding = 4)

    # ─── Network on the left ────────────────────────────────────────
    ax = Axis(fig[1, 1];
        aspect = AxisAspect(1),
        limits = ((-2.30, 2.30), (-1.45, 1.45)),
        xticksvisible = false, yticksvisible = false,
        xticklabelsvisible = false, yticklabelsvisible = false,
        xgridvisible = false, ygridvisible = false,
        leftspinevisible = false, rightspinevisible = false,
        topspinevisible = false, bottomspinevisible = false,
    )

    top_edges = PAIRS_SORTED[1:TOP_NETWORK_EDGES]
    max_w = top_edges[1][2]

    # Draw edges
    for ((a, b), w) in top_edges
        x1, y1 = pos[a]; x2, y2 = pos[b]
        lw  = 1.5 + 6.5 * (w / max_w)
        alpha = 0.35 + 0.60 * (w / max_w)
        lines!(ax, [x1, x2], [y1, y2];
            color = (:gray25, alpha), linewidth = lw)
    end

    # Draw edge-weight labels in white chips (only top 5 to declutter)
    for ((a, b), w) in top_edges[1:min(5, length(top_edges))]
        x1, y1 = pos[a]; x2, y2 = pos[b]
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        # White rectangle background
        text_str = string(w)
        nchar = length(text_str)
        # rectangle size in axis units
        rw = 0.06 * nchar
        rh = 0.10
        poly!(ax, Point2f[(mx-rw, my-rh), (mx+rw, my-rh),
                           (mx+rw, my+rh), (mx-rw, my+rh)];
              color = (:white, 0.92), strokecolor = (:gray60, 0.8), strokewidth = 0.5)
        text!(ax, mx, my; text = text_str,
            fontsize = 10.5, color = :black, font = :bold,
            align = (:center, :center))
    end

    # Draw nodes and labels
    for nm in TRAJECTORY_ORDER
        x, y = pos[nm]
        scatter!(ax, [x], [y];
            color = TRAJECTORY_COLORS[nm],
            strokecolor = :black, strokewidth = 1.4,
            markersize = 32)
        lx = x * 1.13; ly = y * 1.13
        ha = x > 0.1 ? :left : (x < -0.1 ? :right : :center)
        text!(ax, lx, ly; text = nm, fontsize = 10.5,
              align = (ha, :center), font = :bold, color = :black)
    end

    # ─── Table on the right ────────────────────────────────────────
    # Narrower axis-x range so columns sit closer together.
    XMAX = 76.0
    tbl_ax = Axis(fig[1, 2];
        limits = ((0, XMAX), (0, TOP_TABLE_ROWS + 1)),
        xticksvisible = false, yticksvisible = false,
        xticklabelsvisible = false, yticklabelsvisible = false,
        xgridvisible = false, ygridvisible = false,
        leftspinevisible = false, rightspinevisible = false,
        topspinevisible = false, bottomspinevisible = false,
    )

    # Column anchors (no more # column).
    mx_a, mx_b   = 2.5, 5.5                   # the two trajectory colour swatches
    pair_text_x  = 8.0                        # pair text (left-aligned)
    configs_x    = XMAX - 1.0                 # configs count (right-aligned)

    header_y = TOP_TABLE_ROWS + 0.5
    poly!(tbl_ax, Point2f[(0, TOP_TABLE_ROWS), (XMAX, TOP_TABLE_ROWS),
                          (XMAX, TOP_TABLE_ROWS + 1), (0, TOP_TABLE_ROWS + 1)];
          color = (:gray88, 0.7), strokewidth = 0)
    text!(tbl_ax, pair_text_x, header_y; text = "Confusion pair (winner ↔ runner-up)",
        font = :bold, fontsize = 13.5, color = :gray10,
        align = (:left, :center))
    text!(tbl_ax, configs_x, header_y; text = "Configs",
        font = :bold, fontsize = 13.5, color = :gray10,
        align = (:right, :center))

    for k in 1:min(TOP_TABLE_ROWS, length(PAIRS_SORTED))
        (a, b), w = PAIRS_SORTED[k]
        y_low  = Float64(TOP_TABLE_ROWS) - k
        y_high = y_low + 1
        yc = (y_low + y_high) / 2

        if k % 2 == 1
            poly!(tbl_ax, Point2f[(0, y_low), (XMAX, y_low),
                                   (XMAX, y_high), (0, y_high)];
                  color = (:gray92, 0.5), strokewidth = 0)
        end

        ca = TRAJECTORY_COLORS[a]
        cb = TRAJECTORY_COLORS[b]
        scatter!(tbl_ax, [mx_a], [yc]; color = ca,
                  strokecolor = :black, strokewidth = 0.6, markersize = 14)
        scatter!(tbl_ax, [mx_b], [yc]; color = cb,
                  strokecolor = :black, strokewidth = 0.6, markersize = 14)

        text!(tbl_ax, pair_text_x, yc;
              text = "$a   ↔   $b",
              fontsize = 12.5, color = :black,
              align = (:left, :center))
        text!(tbl_ax, configs_x, yc; text = string(w),
              fontsize = 13.5, color = :black, font = :bold,
              align = (:right, :center))
    end

    lines!(tbl_ax, [0, XMAX], [TOP_TABLE_ROWS + 1, TOP_TABLE_ROWS + 1]; color = :black, linewidth = 1.0)
    lines!(tbl_ax, [0, XMAX], [TOP_TABLE_ROWS,     TOP_TABLE_ROWS    ]; color = :black, linewidth = 0.7)
    lines!(tbl_ax, [0, XMAX], [0,                  0                 ]; color = :black, linewidth = 1.0)

    # Single-line caption beneath the table.
    Label(fig[2, 2],
        "Top 10 ambiguous pairs (score_margin < 0.05); network shows only the top 7 edges; thickness ∝ count.";
        fontsize = 10, color = :black, halign = :left, padding = (8, 0, 2, 0))

    colsize!(fig.layout, 1, Relative(0.50))
    colsize!(fig.layout, 2, Relative(0.50))
    colgap!(fig.layout, 12)
    rowsize!(fig.layout, 2, Auto(0.04))
    rowgap!(fig.layout, 2)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Trajectory confusion network and top-10 pair counts. Edge weight = configurations where the two trajectories are nearly tied (score margin < 0.05).",

    "main_findings" =>
        "Two confusion pairs dominate the trajectory space: Governed Multipolarity ↔ Regulatory " *
        "Preservation (2,465 configs, the thickest edge) and Captured Hegemony ↔ Algocratic " *
        "Convergence (1,500 configs). These two pairs alone account for 31% of the 13,025 " *
        "ambiguous configurations. Both pairs share an axis of dynamical equivalence: " *
        "Gov ↔ Reg are both 'preserved-leverage' archetypes with high R; Cap ↔ Alg are both " *
        "single-state high-E archetypes. The model classifies them as separate trajectories but " *
        "their score functions agree across a substantial parameter region. Competitive Tension " *
        "is the central swing node: it is one half of FIVE of the top 7 confusion pairs (CT ↔ " *
        "Gov, CT ↔ Reg, CT ↔ BS, CT ↔ OP, CT ↔ GI), reflecting that Competitive Tension is " *
        "definitionally a 'moderate' trajectory adjacent to most others in the model's scoring " *
        "space. The eight nominal archetypes effectively resolve into ≈ 6 distinct dynamical " *
        "regimes if Gov+Reg and Cap+Alg are treated as quasi-equivalent attractor pairs.",

    "detailed_findings" =>
        "This figure quantifies the dynamical adjacency structure of the 8-trajectory taxonomy. " *
        "For each pair of trajectories, the edge weight counts configurations where the trajectory " *
        "classifier was nearly tied between the two — score_margin < 0.05 — meaning the trajectory " *
        "scoring functions evaluated nearly equally on those configurations.\n\n" *
        "Construction: scan all 31,944 configurations; whenever the score margin between the " *
        "winning trajectory and its runner-up is < 0.05, increment the symmetric edge between " *
        "that (winner, runner-up) pair. Display the top 7 edges as a network on the left and the " *
        "top 10 as a sorted table on the right. The network gives the structural intuition (which " *
        "trajectories cluster); the table gives the precise per-pair counts.\n\n" *
        "Top pairs:\n" *
        "  1. Gov ↔ Reg Preservation: 2,465 — both archetypes share the 'high R, preserved L̄' " *
        "signature; they differ only in whether the classifier weights M (Governed needs M=4) " *
        "more or less than R (Reg needs high R, any M). At M=2 or M=3 with high R, the two " *
        "scores are nearly indistinguishable.\n" *
        "  2. Cap Hegemony ↔ Algocratic: 1,500 — both single-state high-E archetypes. They " *
        "differ in C (Cap needs C ≥ 2, Alg needs C = 1) but the scoring weights make this a " *
        "narrow distinction.\n" *
        "  3. Competitive Tension ↔ Gov Multipolarity: 966 — overlap when M is large and R is " *
        "moderate; the 'best' archetype shades into the 'middle' one.\n" *
        "  4. Competitive Tension ↔ Reg Preservation: 947 — symmetric overlap at moderate R.\n" *
        "  5. Bipolar Standoff ↔ Competitive Tension: 922 — overlap at M=2.\n" *
        "  6–10. Competitive Tension ↔ OP / GI; Bipolar ↔ GI; GI ↔ OP; Cap ↔ Reg.\n\n" *
        "Competitive Tension appears in 5 of the top 7 pairs — it is the model's most " *
        "boundary-prone trajectory, definitionally adjacent to almost every other archetype. " *
        "For Paper 3, the methodological message is that the 8-trajectory taxonomy is more " *
        "permissive than the canonical preset definitions suggest. Two pair-collapses (Gov+Reg, " *
        "Cap+Alg) would reduce the 8 archetypes to 6 attractors with cleaner classification " *
        "margins. The pair structure is informative for policy: dynamically, Governed " *
        "Multipolarity and Regulatory Preservation are nearly the same outcome; if a stakeholder " *
        "cares about the empirical effect on leverage, the distinction between the two is largely " *
        "cosmetic."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
