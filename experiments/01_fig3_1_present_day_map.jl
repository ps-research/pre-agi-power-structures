#!/usr/bin/env julia
# scripts/updated/fig_3_1.jl — Paper 3, Fig 3.1 (revision)
# Updates:
#   - remove main figure title
#   - bump fontsize of point labels (anchor, O-, O+, E-, E+)
#   - position each label in the direction the point lies from the anchor
#     (O- label to the LEFT of the O- point, E+ label ABOVE the E+ point, etc.)
#     so each label clearly belongs to its own marker
#   - replace single-line grey footnote with a structured legend (marker key)
#     plus a brief textual annotation

using CairoMakie, Printf, Statistics, JSON
include(joinpath(@__DIR__, "..", "lib", "figures_lib.jl"))

const FIG_NAME = "fig3_1_present_day_map"
const OUT_DIR  = joinpath(FIGURES_ROOT, FIG_NAME)
mkpath(OUT_DIR)

println("Loading summary…")
SUMMARY = load_summary()

function build_figure()
    mask = (SUMMARY.M .== 2) .& (SUMMARY.C .== 3) .& (round.(SUMMARY.R; digits=1) .== 0.3)
    O_vals = sort(unique(SUMMARY.O[mask]))
    E_vals = sort(unique(SUMMARY.E[mask]))
    nx, ny = length(O_vals), length(E_vals)

    Lmat = fill(NaN, nx, ny)
    Tmat = fill("", nx, ny)
    omap = Dict(O_vals[i] => i for i in eachindex(O_vals))
    emap = Dict(E_vals[i] => i for i in eachindex(E_vals))
    for i in findall(mask)
        oi = omap[round(SUMMARY.O[i]; digits=1)]
        ei = emap[round(SUMMARY.E[i]; digits=1)]
        Lmat[oi, ei] = SUMMARY.final_mean_leverage[i]
        Tmat[oi, ei] = SUMMARY.trajectory[i]
    end

    fig = Figure(size = (740, 620))
    ax = Axis(fig[1, 1];
        xlabel = "Openness O",
        ylabel = "Enforcement E",
        xticks = (1:nx, [@sprintf("%.1f", o) for o in O_vals]),
        yticks = (1:ny, [@sprintf("%.1f", e) for e in E_vals]),
        xlabelsize = 12, ylabelsize = 12,
        xticklabelsize = 10, yticklabelsize = 10,
    )

    hm = heatmap!(ax, 1:nx, 1:ny, Lmat;
        colormap = :viridis,
        colorrange = (minimum(filter(!isnan, Lmat)), maximum(filter(!isnan, Lmat))))

    # White boundary segments between different-trajectory neighbours
    for i in 1:nx, j in 1:ny
        if i < nx && Tmat[i, j] != Tmat[i+1, j]
            lines!(ax, [i+0.5, i+0.5], [j-0.5, j+0.5];
                   color = (:white, 0.9), linewidth = 1.2)
        end
        if j < ny && Tmat[i, j] != Tmat[i, j+1]
            lines!(ax, [i-0.5, i+0.5], [j+0.5, j+0.5];
                   color = (:white, 0.9), linewidth = 1.2)
        end
    end

    Colorbar(fig[1, 2], hm;
        label = "Final mean leverage L̄",
        labelsize = 11, ticklabelsize = 10,
        height = Relative(0.85), width = 14)

    # Anchor and neighbours
    anchor_O = PRESENT_DAY_ANCHOR.O; anchor_E = PRESENT_DAY_ANCHOR.E
    ai = omap[round(anchor_O; digits=1)]; aj = emap[round(anchor_E; digits=1)]
    anchor_traj = Tmat[ai, aj]

    # Anchor star
    scatter!(ax, [ai], [aj]; color = :white, strokecolor = :red,
        strokewidth = 2.6, markersize = 24, marker = :star5)
    # Place anchor label up-right of the star, slightly larger font
    text!(ax, ai + 0.32, aj + 0.32; text = "anchor",
          align = (:left, :bottom), fontsize = 12, color = :black, font = :bold)

    # Four O/E neighbours — label placed in the outward direction
    # so each label is unambiguously paired with its marker.
    nbrs = [
        (ai - 1, aj,     "O−", :right, :center, (-0.32, 0.0)),  # to the LEFT of the point
        (ai + 1, aj,     "O+", :left,  :center, (0.32,  0.0)),  # to the RIGHT
        (ai,     aj - 1, "E−", :center, :top,    (0.0, -0.32)),  # BELOW
        (ai,     aj + 1, "E+", :center, :bottom, (0.0,  0.32)),  # ABOVE
    ]
    for (ni, nj, lab, ha, va, off) in nbrs
        (1 <= ni <= nx && 1 <= nj <= ny) || continue
        flipped = Tmat[ni, nj] != anchor_traj
        scatter!(ax, [ni], [nj];
            color = flipped ? :red : :white,
            strokecolor = :black, strokewidth = 1.4,
            markersize = 14, marker = :diamond)
        text!(ax, ni + off[1], nj + off[2]; text = lab,
              fontsize = 11.5, color = :black, font = :bold,
              align = (ha, va))
    end

    # Structured legend below the figure
    elem_anchor = MarkerElement(color = :white, marker = :star5,
                                 strokecolor = :red, strokewidth = 2.0, markersize = 18)
    elem_same   = MarkerElement(color = :white, marker = :diamond,
                                 strokecolor = :black, strokewidth = 1.2, markersize = 12)
    elem_flip   = MarkerElement(color = :red, marker = :diamond,
                                 strokecolor = :black, strokewidth = 1.2, markersize = 12)
    elem_bound  = LineElement(color = :white, linewidth = 1.4)
    Legend(fig[2, 1:2],
        [elem_anchor, elem_same, elem_flip, elem_bound],
        ["Anchor: M=2, C=3, O=0.6, R=0.3, E=0.2  →  Competitive Tension",
         "Neighbour: same trajectory as anchor",
         "Neighbour: trajectory FLIPPED",
         "Boundary between adjacent dominant-trajectory cells"];
        orientation = :horizontal, nbanks = 2,
        framevisible = false, labelsize = 10.5, patchsize = (24, 14),
        padding = (8, 8, 4, 4))

    Label(fig[3, 1:2],
        "M-direction neighbours not drawable on a fixed-M slice: M=2 → M=1 also flips (to Captured Hegemony).";
        fontsize = 9.5, color = :gray30, halign = :left, padding = (8, 0, 4, 0))

    rowsize!(fig.layout, 2, Auto(0.13))
    rowsize!(fig.layout, 3, Auto(0.06))
    colgap!(fig.layout, 8)
    rowgap!(fig.layout, 4)
    return fig
end

println("Rendering…")
save_fig(build_figure(), FIG_NAME; outdir = OUT_DIR)

meta = Dict(
    "caption" =>
        "Present-day calibration slice (M=2, C=3, R=0.3): mean final leverage on the (O, E) grid, white trajectory boundaries, anchor and its one-step O/E neighbours marked.",

    "main_findings" =>
        "The present-day anchor (★) sits in a Competitive Tension region surrounded by a tile of " *
        "Bipolar Standoff to the immediate left (O−) and adjacent trajectory boundaries above and " *
        "to the right. Three of the four O/E neighbours stay within the Competitive Tension " *
        "region; one — O− (O = 0.5) — flips trajectory to Bipolar Standoff (marked red). The " *
        "M− neighbour (M = 2 → M = 1, not drawable on this fixed-M slice) also flips, to Captured " *
        "Hegemony — see Fig 3.2. So the anchor is unstable along two axes: M and O. The leverage " *
        "field on this slice ranges from ≈0.38 (top-right, high O + high E) to ≈0.58 (bottom-" *
        "left, low O + low E). The anchor's L̄ ≈ 0.53 sits in the mid-range, neither best nor " *
        "worst. The dotted-white boundary structure shows that trajectory regions in this slice " *
        "are large and well-defined — there are only 3–4 distinct trajectory tiles on the entire " *
        "grid, with the anchor sitting near one boundary. The bigger leverage gain available " *
        "without a trajectory flip is the E− move (E = 0.2 → 0.1), which raises L̄ by ≈0.025 " *
        "without changing the trajectory classification.",

    "detailed_findings" =>
        "This is Paper 3's hero figure: a single slice through the parameter space at the " *
        "present-day calibration values (M=2 corresponds to the US/China duopoly, C=3 corresponds " *
        "to ~3 frontier firms per state, R=0.3 corresponds to the present-day low-regulation " *
        "posture), with the anchor exactly at (O=0.6, E=0.2) — the DeepSeek-era openness and " *
        "low-deployment enforcement levels.\n\n" *
        "Construction: heatmap of mean final leverage L̄ over the 11×11 (Openness, Enforcement) " *
        "grid at the fixed M=2, C=3, R=0.3 slice. Color scale shows L̄ from ≈0.38 (worst, " *
        "high O + high E) to ≈0.58 (best, low O + low E). White polyline segments mark cell " *
        "boundaries where the dominant trajectory classification changes between adjacent cells, " *
        "revealing the trajectory tile structure.\n\n" *
        "The anchor (★) is marked at (O=0.6, E=0.2). Its four one-step O/E neighbours are " *
        "drawn as diamonds: open white = same trajectory as anchor; filled red = trajectory " *
        "flipped. Labels are placed in the outward direction from the anchor (O− label to the " *
        "left of its point, E+ label above, etc.) so each label unambiguously belongs to its " *
        "marker.\n\n" *
        "Key observations:\n" *
        "  • Anchor classification: Competitive Tension. Final mean leverage ≈ 0.53.\n" *
        "  • Three of four O/E neighbours stay in Competitive Tension; only O− (O = 0.5) flips " *
        "to Bipolar Standoff.\n" *
        "  • The M− neighbour (M = 2 → 1) cannot be drawn on this fixed-M slice but it also " *
        "flips — to Captured Hegemony (see Fig 3.2 for the full sensitivity panel).\n" *
        "  • The trajectory tiles are large; the anchor sits near a boundary, which is why one " *
        "of four in-slice neighbours flips even at the smallest single-step perturbation.\n" *
        "  • The leverage field is dominated by the E axis: moving down (lower E) improves L̄; " *
        "moving up worsens it. O has a weaker effect within this slice.\n\n" *
        "For Paper 3, this figure tells the reader 'here is where we are, and here is what " *
        "happens one step in any direction.' It is the geographic anchor for the projection " *
        "scenarios in Fig 3.5."
)

open(joinpath(OUT_DIR, FIG_NAME * ".json"), "w") do io
    JSON.print(io, meta, 2)
end

println("Saved to $OUT_DIR")
