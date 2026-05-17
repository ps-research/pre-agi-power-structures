#!/usr/bin/env julia
# scripts/updated/fig_3_5.jl — Paper 3, Fig 3.5 (revision)
# Updates:
#   - remove main figure title
#   - increase font size of the in-panel scenario-result annotations
#     (was 8.5 pt grey; now 11 pt bold black) so they're visible at print size
#   - bump panel titles and axis labels

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig3_5_projection_scenarios"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading scenario time series + summary…")
SUMMARY = load_summary()
LOOKUP  = summary_lookup(SUMMARY)

const SCENARIOS = [
    (label = "A. Today (anchor)",         M=2, C=3, O=0.6, R=0.3, E=0.2),
    (label = "B. Open-source surge",      M=2, C=3, O=0.9, R=0.3, E=0.2),
    (label = "C. Enforcement deployment", M=2, C=3, O=0.6, R=0.3, E=0.5),
    (label = "D. Regulatory push",        M=2, C=3, O=0.6, R=0.7, E=0.2),
]
TS_SCENARIOS = [load_ts(s.M, s.C, s.O, s.R, s.E) for s in SCENARIOS]

function build_figure()
    fig = Figure(size = (900, 600), figure_padding = 6)

    for (panel_i, (sc, ts)) in enumerate(zip(SCENARIOS, TS_SCENARIOS))
        row = (panel_i - 1) ÷ 2 + 1
        col = (panel_i - 1) % 2 + 1
        ax = Axis(fig[row, col];
            xlabel = row == 2 ? "Timestep t" : "",
            ylabel = col == 1 ? "Leverage L(t)" : "",
            title  = sc.label,
            titlesize = 13,
            xticks = 0:20:100, yticks = 0:0.2:1.0,
            limits = ((0, 100), (0.0, 1.0)),
            xlabelsize = 12, ylabelsize = 12,
            xticklabelsize = 11, yticklabelsize = 11,
        )
        if row == 1; ax.xticklabelsvisible = false; end
        if col == 2; ax.yticklabelsvisible = false; end
        ps = per_state_series(ts, "leverage")
        for a in sort(collect(keys(ps)))
            tv = ps[a]
            lines!(ax, [x[1] for x in tv], [x[2] for x in tv];
                color = get(STATE_COLORS, a, :black),
                linewidth = 2.0, label = a)
        end
        hlines!(ax, [0.3]; color = (:gray30, 0.55), linestyle = :dot, linewidth = 0.9)

        # Larger in-panel result annotation
        key = (sc.M, sc.C, round(sc.O; digits=1), round(sc.R; digits=1), round(sc.E; digits=1))
        i_sum = get(LOOKUP, key, nothing)
        if !isnothing(i_sum)
            tr = SUMMARY.trajectory[i_sum]
            L̄  = SUMMARY.final_mean_leverage[i_sum]
            text!(ax, 98, 0.05;
                  text = "→ $tr\nL̄ = $(@sprintf("%.3f", L̄))",
                  align = (:right, :bottom), fontsize = 11.5, color = :black, font = :bold)
        end
    end

    # State legend on the right
    elems = [LineElement(color = STATE_COLORS["S_BC"], linewidth = 2.6),
             LineElement(color = STATE_COLORS["S_BS"], linewidth = 2.6)]
    Legend(fig[1:2, 3], elems, ["S_BC", "S_BS"], "State";
        framevisible = false, labelsize = 11.5, titlesize = 12.5,
        patchsize = (24, 14), padding = (8, 6, 4, 4))

    colgap!(fig.layout, 10)
    rowgap!(fig.layout, 8)
    colsize!(fig.layout, 3, Auto(0.13))
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Four near-future scenarios from the present-day anchor (M=2, C=3): per-state leverage L(t) under varied (O, R, E) policy choices, with the resulting trajectory and final L̄.",

    "main_findings" =>
        "Panel A (Today, anchor): O=0.6, R=0.3, E=0.2 produces Competitive Tension with L̄=0.528 by " *
        "t=100. S_BC and S_BS curves descend in roughly parallel fashion. Panel B (Open-source " *
        "surge): O bumped 0.6 → 0.9 holding R and E. Trajectory unchanged (Competitive Tension), " *
        "L̄ drops slightly to 0.522 — openness alone is not a regime-flipper at this anchor, only " *
        "a small leverage erosion. Panel C (Enforcement deployment): E bumped 0.2 → 0.5 holding O " *
        "and R. Trajectory FLIPS to Bipolar Standoff and L̄ drops sharply to 0.462 — a leverage " *
        "loss of 0.066 relative to today. Of the three single-knob policy moves, enforcement " *
        "deployment is the only one that flips the trajectory away from Competitive Tension. " *
        "Panel D (Regulatory push): R bumped 0.3 → 0.7 holding O and E. Trajectory unchanged " *
        "(Competitive Tension), L̄ rises substantially to 0.586 — a leverage gain of 0.058. The " *
        "lesson: regulatory push (D) is the most leverage-positive single-knob move at this " *
        "anchor; enforcement deployment (C) is the most leverage-destructive AND the only " *
        "single-knob move that flips the regime. The four scenarios bracket the realistic leverage " *
        "outcome space between 0.462 (worst) and 0.586 (best) — a span of 0.124 from single-axis " *
        "policy choices.",

    "detailed_findings" =>
        "This figure shows four concrete near-future scenarios for the present-day calibration " *
        "anchor (M=2 US/China duopoly, C=3 frontier firms per state), varying one of the three " *
        "governance knobs (O, R, E) per panel. Each panel plots per-state leverage L(t) for the " *
        "two simulated state archetypes (S_BC in blue, S_BS in red), with the dotted line at " *
        "T_leverage=0.3 (coalition threshold) for reference. The in-panel annotation gives the " *
        "resulting dominant trajectory and the final mean leverage L̄ at t=100.\n\n" *
        "Scenario A — Today (anchor): O=0.6, R=0.3, E=0.2. Reference point. Trajectory: " *
        "Competitive Tension. L̄=0.528.\n\n" *
        "Scenario B — Open-source surge (O bumped 0.6 → 0.9): models the DeepSeek-style " *
        "intensification of open-source flooding. Trajectory unchanged (Competitive Tension), L̄ " *
        "drops by 0.006 to 0.522. Openness alone is essentially leverage-neutral at this anchor — " *
        "open-sourcing per se is not the dispensability-trap driver.\n\n" *
        "Scenario C — Enforcement deployment (E bumped 0.2 → 0.5): models a major AI-enforcement " *
        "rollout (autonomous surveillance, predictive policing, etc.). Trajectory FLIPS to " *
        "Bipolar Standoff, and L̄ drops sharply by 0.066 to 0.462. The enforcement-suppression " *
        "formula (1 − 0.4·E·(1 − 0.5·R)) directly multiplies leverage and accounts for the large " *
        "decrease; the trajectory flip happens because the increase in E moves the configuration " *
        "across the boundary between Competitive Tension and Bipolar Standoff in the trajectory " *
        "scoring space (see Fig 1.3, M=2 panel).\n\n" *
        "Scenario D — Regulatory push (R bumped 0.3 → 0.7): models stronger AI regulation (e.g., " *
        "EU AI Act + similar elsewhere). Trajectory unchanged (Competitive Tension), L̄ rises " *
        "substantially by 0.058 to 0.586. The regulation-leverage-floor (0.15·R) and the " *
        "attenuation of enforcement suppression by R both contribute.\n\n" *
        "For Paper 3, this figure gives the reader four immediately-recognisable near-future " *
        "policy scenarios with quantitative outcomes. Key claims: (1) regulatory push (D) is the " *
        "most leverage-positive single-knob move available at this anchor (+0.058); (2) " *
        "enforcement deployment (C) is the most leverage-destructive AND flips the regime to " *
        "Bipolar Standoff (−0.066); (3) open-source surge (B) is nearly leverage-neutral; (4) the " *
        "four scenarios bracket a realistic outcome space spanning 0.124 in L̄. The implication is " *
        "that AI-governance policy choices have substantial, asymmetric, and sometimes regime-" *
        "flipping consequences."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
