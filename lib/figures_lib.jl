# scripts/figures_lib.jl
# Shared infrastructure for figures_paper{1,2,3}.jl.
# Color palette, theme, CSV/time-series loaders, exemplar config dict,
# and a uniform save_fig(...) helper that writes 600 DPI PNG + vector PDF.

using CairoMakie
using Printf
using Statistics

# ─── Paths ───────────────────────────────────────────────────────────

const PROJECT_ROOT_FIG = dirname(@__DIR__)
const SWEEP_DIR_FIG    = joinpath(PROJECT_ROOT_FIG, "data", "sweep_results")
const TS_DIR_FIG       = joinpath(SWEEP_DIR_FIG, "grand_sweep_timeseries")
const ANALYSIS_DIR_FIG = joinpath(SWEEP_DIR_FIG, "pattern_analysis")
const FIGURES_ROOT     = joinpath(PROJECT_ROOT_FIG, "figures")

# ─── Palette ─────────────────────────────────────────────────────────

const TRAJECTORY_ORDER = [
    "Governed Multipolarity",
    "Competitive Tension",
    "Bipolar Standoff",
    "Regulatory Preservation",
    "Open-Source Paradox",
    "Captured Hegemony",
    "Gatekeeping Inversion",
    "Algocratic Convergence",
]

# Diverging blue→red ramp: best (cool) → worst (warm), matches existing convention.
const TRAJECTORY_COLORS = Dict(
    "Governed Multipolarity"  => "#2166ac",
    "Competitive Tension"     => "#4393c3",
    "Bipolar Standoff"        => "#92c5de",
    "Regulatory Preservation" => "#66c2a5",
    "Open-Source Paradox"     => "#fdae61",
    "Captured Hegemony"       => "#f46d43",
    "Gatekeeping Inversion"   => "#d53e4f",
    "Algocratic Convergence"  => "#9e0142",
)

const STATE_COLORS = Dict(
    "S_BC" => "#2166ac",
    "S_BS" => "#d53e4f",
    "S_BR" => "#66c2a5",
    "S_BL" => "#fc8d59",
    "S_CH" => "#6a3d9a",
    "S_DT" => "#33a02c",
    "S_AC" => "#1f78b4",
    "S_DD" => "#b15928",
)

const KAPPA_DIM_LABEL = ["κ_c (cognitive)", "κ_p (physical)", "κ_e (enforcement)",
                        "κ_s (scientific)", "κ_a (administrative)"]
const KAPPA_DIM_COL   = ["kappa_c", "kappa_p", "kappa_e", "kappa_s", "kappa_a"]
const KAPPA_DIM_COLOR = ["#1f77b4", "#ff7f0e", "#d62728", "#2ca02c", "#9467bd"]

const TRAJ_DISPLAY_NAME = Dict(
    "TRAJ_GOVERNED_MULTIPOLARITY"  => "Governed Multipolarity",
    "TRAJ_COMPETITIVE_TENSION"     => "Competitive Tension",
    "TRAJ_BIPOLAR_STANDOFF"        => "Bipolar Standoff",
    "TRAJ_REGULATORY_PRESERVATION" => "Regulatory Preservation",
    "TRAJ_OPEN_SOURCE_PARADOX"     => "Open-Source Paradox",
    "TRAJ_CAPTURED_HEGEMONY"       => "Captured Hegemony",
    "TRAJ_GATEKEEPING_INVERSION"   => "Gatekeeping Inversion",
    "TRAJ_ALGOCRATIC_CONVERGENCE"  => "Algocratic Convergence",
)
display_traj(s::AbstractString) = get(TRAJ_DISPLAY_NAME, s, s)

# Exemplar configurations (highest score_margin per trajectory; Algocratic overridden
# to the canonical M=1 C=1 O=0 R=0 E=1.0 spec preset).
const EXEMPLARS = [
    (name = "Governed Multipolarity",  M=4, C=3, O=0.0, R=0.0, E=0.0),
    (name = "Competitive Tension",     M=3, C=1, O=0.1, R=0.5, E=0.3),
    (name = "Bipolar Standoff",        M=2, C=1, O=0.5, R=0.3, E=0.5),
    (name = "Regulatory Preservation", M=2, C=1, O=0.2, R=1.0, E=0.4),
    (name = "Open-Source Paradox",     M=2, C=1, O=1.0, R=0.0, E=1.0),
    (name = "Captured Hegemony",       M=1, C=2, O=0.9, R=0.0, E=1.0),
    (name = "Gatekeeping Inversion",   M=2, C=2, O=0.0, R=0.8, E=1.0),
    (name = "Algocratic Convergence",  M=1, C=1, O=0.0, R=0.0, E=1.0),
]

const PRESENT_DAY_ANCHOR = (M=2, C=3, O=0.6, R=0.3, E=0.2)
const ACCELERATING_TRAJECTORIES = Set([
    "Governed Multipolarity", "Competitive Tension", "Bipolar Standoff",
    "Regulatory Preservation", "Open-Source Paradox", "Gatekeeping Inversion",
])
const DECELERATING_TRAJECTORIES = Set(["Captured Hegemony", "Algocratic Convergence"])

# ─── Theme ───────────────────────────────────────────────────────────

function apply_publication_theme!()
    set_theme!(Theme(
        fontsize = 11,
        fonts = (
            regular     = "TeX Gyre Pagella",
            bold        = "TeX Gyre Pagella Bold",
            italic      = "TeX Gyre Pagella Italic",
            bold_italic = "TeX Gyre Pagella Bold Italic",
        ),
        Axis = (
            xgridvisible  = true,
            ygridvisible  = true,
            xgridcolor    = (:gray, 0.18),
            ygridcolor    = (:gray, 0.18),
            xgridwidth    = 0.5,
            ygridwidth    = 0.5,
            spinewidth    = 0.7,
            xticklabelsize = 9,
            yticklabelsize = 9,
            titlesize      = 12,
            titlegap       = 8,
            xlabelsize     = 10,
            ylabelsize     = 10,
            xlabelpadding  = 4,
            ylabelpadding  = 4,
            xtickalign     = 1,
            ytickalign     = 1,
            xticksize      = 4,
            yticksize      = 4,
            xtickwidth     = 0.7,
            ytickwidth     = 0.7,
        ),
        Legend = (
            framevisible   = false,
            labelsize      = 9,
            titlesize      = 9.5,
            patchsize      = (16, 12),
            rowgap         = 2,
            padding        = (6, 6, 6, 6),
        ),
        Colorbar = (
            labelsize      = 9.5,
            ticklabelsize  = 9,
            tickalign      = 1,
            ticksize       = 4,
            spinewidth     = 0.5,
            width          = 10,
        ),
        Label = (fontsize = 10,),
    ))
end

# ─── Save figure (PNG @ 600 DPI + vector PDF) ────────────────────────

function save_fig(fig, name; outdir::String, dpi::Real = 600)
    isdir(outdir) || mkpath(outdir)
    pdf_path = joinpath(outdir, "$name.pdf")
    png_path = joinpath(outdir, "$name.png")
    save(pdf_path, fig)
    save(png_path, fig; px_per_unit = dpi / 72)
    return (png = png_path, pdf = pdf_path)
end

# ─── CSV reader (tiny, no embedded commas in our outputs) ────────────

function read_csv_rows(path::String)
    isfile(path) || error("CSV not found: $path")
    lines = readlines(path)
    isempty(lines) && error("Empty CSV: $path")
    header = String.(split(lines[1], ','))
    rows = Vector{Vector{String}}(undef, length(lines)-1)
    @inbounds for i in 1:length(lines)-1
        rows[i] = String.(split(lines[i+1], ','))
    end
    return header, rows
end

function col_idx(header, name)
    i = findfirst(==(name), header)
    isnothing(i) && error("Column \"$name\" not found")
    return i
end

function getcol(rows, idx)
    [r[idx] for r in rows]
end

function parsecol_float(rows, idx)
    out = Vector{Float64}(undef, length(rows))
    @inbounds for i in eachindex(rows)
        s = rows[i][idx]
        out[i] = s == "Inf" ? Inf : s == "-Inf" ? -Inf : s == "NaN" ? NaN : parse(Float64, s)
    end
    return out
end

parsecol_int(rows, idx) = parse.(Int, getcol(rows, idx))

# ─── Summary CSV → strongly-typed columns ───────────────────────────

struct SummaryData
    M::Vector{Int}
    C::Vector{Int}
    O::Vector{Float64}
    R::Vector{Float64}
    E::Vector{Float64}
    trajectory::Vector{String}
    runner_up::Vector{String}
    score_margin::Vector{Float64}
    trajectory_score::Vector{Float64}
    initial_leverage::Vector{Float64}
    final_mean_leverage::Vector{Float64}
    final_mean_kappa::Vector{Float64}
    final_kappa_c::Vector{Float64}
    final_kappa_p::Vector{Float64}
    final_commoditization::Vector{Float64}
    n_clusters_displaced::Vector{Int}
    t_first_cluster_displaced::Vector{Float64}
    t_last_cluster_displaced::Vector{Float64}
end

function load_summary(path::String = joinpath(SWEEP_DIR_FIG, "grand_sweep_summary.csv"))
    h, r = read_csv_rows(path)
    return SummaryData(
        parsecol_int(r,   col_idx(h, "M")),
        parsecol_int(r,   col_idx(h, "C")),
        parsecol_float(r, col_idx(h, "O")),
        parsecol_float(r, col_idx(h, "R")),
        parsecol_float(r, col_idx(h, "E")),
        getcol(r,         col_idx(h, "trajectory_name")),
        getcol(r,         col_idx(h, "runner_up")),
        parsecol_float(r, col_idx(h, "score_margin")),
        parsecol_float(r, col_idx(h, "trajectory_score")),
        parsecol_float(r, col_idx(h, "initial_leverage")),
        parsecol_float(r, col_idx(h, "final_mean_leverage")),
        parsecol_float(r, col_idx(h, "final_mean_kappa")),
        parsecol_float(r, col_idx(h, "final_kappa_c")),
        parsecol_float(r, col_idx(h, "final_kappa_p")),
        parsecol_float(r, col_idx(h, "final_commoditization")),
        parsecol_int(r,   col_idx(h, "n_clusters_displaced")),
        parsecol_float(r, col_idx(h, "t_first_cluster_displaced")),
        parsecol_float(r, col_idx(h, "t_last_cluster_displaced")),
    )
end

# Build (M, C, O, R, E) → row-index lookup for fast lookup.
function summary_lookup(s::SummaryData)
    d = Dict{NTuple{5, Any}, Int}()
    @inbounds for i in eachindex(s.M)
        d[(s.M[i], s.C[i], round(s.O[i]; digits=1), round(s.R[i]; digits=1), round(s.E[i]; digits=1))] = i
    end
    return d
end

# ─── Time-series filename and loader ─────────────────────────────────

function ts_filename(M::Int, C::Int, O::Real, R::Real, E::Real)
    O_s = @sprintf("%.1f", round(O; digits=1))
    R_s = @sprintf("%.1f", round(R; digits=1))
    E_s = @sprintf("%.1f", round(E; digits=1))
    return "config_M$(M)_C$(C)_O$(O_s)_R$(R_s)_E$(E_s).csv"
end

ts_path(M, C, O, R, E) = joinpath(TS_DIR_FIG, ts_filename(M, C, O, R, E))

struct TS
    header::Vector{String}
    rows::Vector{Vector{String}}
    archs::Vector{String}
    times::Vector{Float64}
end

function load_ts(M::Int, C::Int, O::Real, R::Real, E::Real)
    h, r = read_csv_rows(ts_path(M, C, O, R, E))
    archs = unique([row[col_idx(h, "archetype")] for row in r])
    ts = sort(unique(parse.(Float64, [row[col_idx(h, "t")] for row in r])))
    return TS(h, r, archs, ts)
end

# Mean of a numeric column across archetypes, per timestep.
function mean_series(ts::TS, colname::String)
    t_i = col_idx(ts.header, "t")
    v_i = col_idx(ts.header, colname)
    by_t = Dict{Float64, Vector{Float64}}()
    for r in ts.rows
        t = parse(Float64, r[t_i])
        v = parse(Float64, r[v_i])
        push!(get!(by_t, t, Float64[]), v)
    end
    times = sort(collect(keys(by_t)))
    vals  = [mean(by_t[t]) for t in times]
    return times, vals
end

# Per-state series for a numeric column. Returns Dict{archetype → Vector{(t, v)}}.
function per_state_series(ts::TS, colname::String)
    t_i = col_idx(ts.header, "t")
    a_i = col_idx(ts.header, "archetype")
    v_i = col_idx(ts.header, colname)
    out = Dict{String, Vector{Tuple{Float64, Float64}}}()
    for r in ts.rows
        a = r[a_i]
        t = parse(Float64, r[t_i])
        v = parse(Float64, r[v_i])
        push!(get!(out, a, Tuple{Float64,Float64}[]), (t, v))
    end
    for k in keys(out)
        sort!(out[k]; by = x -> x[1])
    end
    return out
end

# Per-state coalition_active intervals (bool column).
function per_state_bool(ts::TS, colname::String)
    t_i = col_idx(ts.header, "t")
    a_i = col_idx(ts.header, "archetype")
    v_i = col_idx(ts.header, colname)
    out = Dict{String, Vector{Tuple{Float64, Bool}}}()
    for r in ts.rows
        a = r[a_i]
        t = parse(Float64, r[t_i])
        v = r[v_i] == "true"
        push!(get!(out, a, Tuple{Float64,Bool}[]), (t, v))
    end
    for k in keys(out)
        sort!(out[k]; by = x -> x[1])
    end
    return out
end

# First time each of the 14 occupation clusters crosses D ≥ 0.5
# (across all archetypes). Returns Vector{(crossing_time, archetype)} length 14,
# with crossing_time = Inf and archetype = "" if never crossed.
function cluster_crossings(ts::TS)
    out = fill((Inf, ""), 14)
    t_i = col_idx(ts.header, "t")
    a_i = col_idx(ts.header, "archetype")
    d_idxs = [col_idx(ts.header, "D_$(lpad(i, 2, '0'))") for i in 1:14]
    for r in ts.rows
        t = parse(Float64, r[t_i])
        a = r[a_i]
        for c in 1:14
            if out[c][1] == Inf
                D = parse(Float64, r[d_idxs[c]])
                if D >= 0.5
                    out[c] = (t, a)
                end
            end
        end
    end
    return out
end

# Per-cluster D(t) for ONE archetype, returned as a 14×T matrix.
function cluster_D_matrix(ts::TS, archetype::String)
    a_i = col_idx(ts.header, "archetype")
    t_i = col_idx(ts.header, "t")
    d_idxs = [col_idx(ts.header, "D_$(lpad(i, 2, '0'))") for i in 1:14]
    rows_a = filter(r -> r[a_i] == archetype, ts.rows)
    times = sort(unique([parse(Float64, r[t_i]) for r in rows_a]))
    M = zeros(Float64, 14, length(times))
    t_map = Dict(times[i] => i for i in eachindex(times))
    for r in rows_a
        ti = t_map[parse(Float64, r[t_i])]
        for c in 1:14
            M[c, ti] = parse(Float64, r[d_idxs[c]])
        end
    end
    return times, M
end

# ─── Cluster names ───────────────────────────────────────────────────

function load_cluster_names(path::String = joinpath(SWEEP_DIR_FIG, "cluster_index.csv"))
    h, r = read_csv_rows(path)
    out = String[]
    for row in r
        n = row[2]
        if startswith(n, "\"") && endswith(n, "\"")
            n = n[2:end-1]
        end
        push!(out, n)
    end
    return out
end

# ─── Grouping/aggregation helpers ────────────────────────────────────

# Given parallel arrays for (key₁, key₂) → val, return a sorted-key matrix.
function pivot_mean(keys1::AbstractVector, keys2::AbstractVector, vals::AbstractVector)
    u1 = sort(unique(keys1))
    u2 = sort(unique(keys2))
    nx, ny = length(u1), length(u2)
    sums = zeros(nx, ny)
    cnts = zeros(Int, nx, ny)
    i1map = Dict(u1[i] => i for i in eachindex(u1))
    i2map = Dict(u2[i] => i for i in eachindex(u2))
    for k in eachindex(vals)
        i = get(i1map, keys1[k], 0); j = get(i2map, keys2[k], 0)
        i == 0 || j == 0 && continue
        sums[i, j] += vals[k]
        cnts[i, j] += 1
    end
    mat = fill(NaN, nx, ny)
    for i in 1:nx, j in 1:ny
        if cnts[i, j] > 0
            mat[i, j] = sums[i, j] / cnts[i, j]
        end
    end
    return u1, u2, mat
end

# Mode trajectory per (k1, k2) cell.
function pivot_mode(keys1::AbstractVector, keys2::AbstractVector, vals::AbstractVector{String})
    u1 = sort(unique(keys1))
    u2 = sort(unique(keys2))
    nx, ny = length(u1), length(u2)
    cell_counts = Dict{Tuple{Int,Int}, Dict{String,Int}}()
    i1map = Dict(u1[i] => i for i in eachindex(u1))
    i2map = Dict(u2[i] => i for i in eachindex(u2))
    for k in eachindex(vals)
        i = i1map[keys1[k]]; j = i2map[keys2[k]]
        dd = get!(cell_counts, (i, j), Dict{String,Int}())
        dd[vals[k]] = get(dd, vals[k], 0) + 1
    end
    out = Matrix{String}(undef, nx, ny)
    for i in 1:nx, j in 1:ny
        d = get(cell_counts, (i, j), Dict{String,Int}())
        if isempty(d)
            out[i, j] = ""
        else
            out[i, j] = argmax(d)
        end
    end
    return u1, u2, out
end

# ─── Apply theme on load ─────────────────────────────────────────────
apply_publication_theme!()
