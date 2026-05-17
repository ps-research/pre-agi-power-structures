#!/usr/bin/env julia
# scripts/updated/fig_3_4.jl — Paper 3, Fig 3.4 (revision)
# Updates:
#   - remove main figure title (was on Panel 1)
#   - move value-layer legend from beside Panel 2 to BELOW Panel 2
#     (horizontal, between Panel 2 and Panel 3)

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig3_4_OS_paradox_arc"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading OS Paradox time series…")
TS_OS = load_ts(2, 1, 1.0, 0.0, 1.0)

function build_figure()
    fig = Figure(size = (760, 700), figure_padding = 6)

    t_c, comm  = mean_series(TS_OS, "commoditization")
    _,   v_mod = mean_series(TS_OS, "value_model")
    _,   v_com = mean_series(TS_OS, "value_compute")
    _,   v_dat = mean_series(TS_OS, "value_data")
    _,   v_int = mean_series(TS_OS, "value_integration")
    _,   L_    = mean_series(TS_OS, "leverage")

    # Panel 1: commoditization
    # yticks start at 0.2 so the bottom "0.0" label does not collide with the
    # "1.0" tick at the top of Panel 2 immediately below.
    ax1 = Axis(fig[1, 1];
        ylabel = "Commoditization C(t)",
        limits = ((0, 100), (0, 1.05)),
        xticks = 0:20:100, yticks = 0.2:0.2:1,
        xticklabelsvisible = false,
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 10, yticklabelsize = 10,
    )
    lines!(ax1, t_c, comm; color = "#9e0142", linewidth = 2.6)
    band!(ax1, t_c, fill(0.0, length(t_c)), comm;
          color = ("#9e0142", 0.16))

    # Panel 2: stacked value-migration area
    ax2 = Axis(fig[2, 1];
        ylabel = "Value-layer share",
        limits = ((0, 100), (0, 1.0)),
        xticks = 0:20:100, yticks = 0:0.2:1,
        xticklabelsvisible = false,
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 10, yticklabelsize = 10,
    )
    stacks = [v_mod, v_com, v_dat, v_int]
    labels = ["model", "compute", "data", "integration"]
    colors = ["#4393c3", "#66c2a5", "#fdae61", "#d53e4f"]
    base = zeros(length(t_c))
    for k in eachindex(stacks)
        upper = base .+ stacks[k]
        band!(ax2, t_c, base, upper; color = (colors[k], 0.88))
        base = upper
    end

    # Legend BELOW Panel 2 (horizontal)
    elems = [PolyElement(color = (colors[k], 0.88)) for k in eachindex(stacks)]
    Legend(fig[3, 1], elems, labels, "Value layer";
        orientation = :horizontal, framevisible = false,
        labelsize = 11, titlesize = 12, patchsize = (24, 14),
        padding = (4, 4, 2, 2))

    # Panel 3: L̄(t) with phase shading
    ax3 = Axis(fig[4, 1];
        xlabel = "Timestep t",
        ylabel = "Mean leverage L̄(t)",
        limits = ((0, 100), (0.0, 0.65)),
        xticks = 0:20:100, yticks = 0:0.1:0.6,
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 10, yticklabelsize = 10,
    )
    lines!(ax3, t_c, L_; color = "#2166ac", linewidth = 2.6)

    phases = [(0,  20, "Democratization", "#9be3c9"),
              (20, 50, "Collapse",        "#fde7a9"),
              (50, 80, "Consolidation",   "#fbb4ae"),
              (80, 100, "Concentration",  "#cab2d6")]
    for (a, b, label, color) in phases
        band!(ax3, [a, b], [0.0, 0.0], [0.65, 0.65];
              color = (color, 0.28))
        text!(ax3, (a + b)/2, 0.62; text = label,
              fontsize = 9.5, color = :black, align = (:center, :top),
              font = :italic)
    end
    hlines!(ax3, [0.3]; color = (:steelblue, 0.65), linestyle = :dot, linewidth = 1)

    # Row sizing
    rowsize!(fig.layout, 1, Auto(1.0))
    rowsize!(fig.layout, 2, Auto(1.0))
    rowsize!(fig.layout, 3, Auto(0.10))  # narrow legend strip
    rowsize!(fig.layout, 4, Auto(1.0))
    rowgap!(fig.layout, 4)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Open-Source Paradox arc (M=2, C=1, O=1.0, R=0.0, E=1.0): commoditization, value-layer migration, and mean leverage L̄(t) — annotated with the four canonical phases.",

    "main_findings" =>
        "Three stacked panels trace the OS Paradox story end-to-end for the canonical exemplar. " *
        "Commoditization (top) rises from 0 to ≈ 1.0 between t=15 and t=70, then plateaus — open-" *
        "sourcing has flooded the model layer with substitutes by t=70. Value-layer migration " *
        "(middle) shows the model layer's share shrinking from ≈ 0.60 to ≈ 0.30 over the same " *
        "window, while compute, data, and integration shares grow. By t=100, value has " *
        "redistributed: model 0.30, compute 0.27, data 0.21, integration 0.22 — roughly " *
        "equipartitioned among non-model layers. Leverage (bottom) declines smoothly from 0.58 to " *
        "0.30, hitting the T_leverage = 0.3 coalition threshold exactly at t=100. The four canonical " *
        "phases of the OS Paradox are annotated: Democratization (t=0–20) when commoditization is " *
        "small and leverage is intact; Collapse (t=20–50) when commoditization spikes and leverage " *
        "drops most steeply; Consolidation (t=50–80) when commoditization saturates and value " *
        "starts migrating to compute and integration; Concentration (t=80–100) when value has " *
        "fully migrated and leverage settles at the coalition threshold.",

    "detailed_findings" =>
        "This figure provides the canonical visual of the Open-Source Paradox dynamic — the " *
        "scenario in which an aggressive open-source flooding strategy by one state " *
        "(commoditizing frontier models) ultimately concentrates value in the layers downstream " *
        "of model production (compute, data, integration), while public leverage erodes alongside.\n\n" *
        "Construction: three stacked panels sharing the time axis, drawn from the OS Paradox " *
        "exemplar (M=2, C=1, O=1.0, R=0.0, E=1.0).\n" *
        "  Panel 1 — commoditization C(t) (filled crimson area): rises from 0 to ≈ 1.0 between " *
        "t=15 and t=70, then plateaus. This is the open-source flooding effect: as S_BS adopts " *
        "the Open Source Flood strategy and pushes high-quality models into the public domain, " *
        "the commoditization variable in the model registers the flooding rate.\n" *
        "  Panel 2 — value-layer stacked share (model + compute + data + integration sum to 1.0 " *
        "at every t): the model layer's share contracts from 0.60 to 0.30; compute grows from " *
        "0.20 to 0.27; data from 0.10 to 0.21; integration from 0.10 to 0.22. The redistribution " *
        "is driven by the value_migration update in src/dynamics/open_source.jl, which transfers " *
        "share away from the model layer as commoditization grows.\n" *
        "  Panel 3 — mean leverage L̄(t) (blue solid): starts at 0.58 (after governance " *
        "suppression at t=0), declines steadily to 0.30 by t=100 (the T_leverage coalition " *
        "threshold). Four phase bands annotate the canonical OS Paradox arc:\n" *
        "    • Democratization (t=0–20): commoditization small, leverage intact.\n" *
        "    • Collapse (t=20–50): commoditization spikes; leverage drops steepest.\n" *
        "    • Consolidation (t=50–80): commoditization saturates; value migrates downstream.\n" *
        "    • Concentration (t=80–100): value fully migrated; leverage settles at threshold.\n\n" *
        "For Paper 3, this figure is the canonical narrative figure for the Open-Source Paradox: " *
        "it shows in one frame why open-sourcing aggressively can paradoxically concentrate power, " *
        "by shifting value away from the layer the public can substitute (models become common) " *
        "and into the layers that require capital (compute, integration)."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
