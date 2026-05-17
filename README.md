# A Proleptic Analysis of Power Structures in the Pre-AGI World

Figure-reproduction code for the paper *A Proleptic Analysis of Power Structures in
the Pre-AGI World*, which calibrates the dispensability model to **present-day
conditions** (the M=2 US/China duopoly, C=3 frontier firms per state, DeepSeek-era
openness, low-medium regulation, low autonomous enforcement) and traces how
plausible near-future policy choices reshape the trajectory.

This repository contains the scripts that generate every figure in the paper from
the published dataset on Zenodo. It does **not** contain the simulation model itself
— that will be released as a Julia package (`TheDispensabilityGame.jl`) at paper
acceptance.

## Data

This work uses the **AGI Game — Grand Parameter Sweep Dataset**, archived on Zenodo
with a persistent DOI:

- **Concept DOI** (always latest): [10.5281/zenodo.20259914](https://doi.org/10.5281/zenodo.20259914)
- **Version DOI** (v1.0.0): [10.5281/zenodo.20259915](https://doi.org/10.5281/zenodo.20259915)
- License: CC-BY-4.0

The dataset (1.57 GB compressed) holds 31,944 per-configuration simulation outputs
plus derived analytical tables. Running `make data` (or `make all`) downloads and
unpacks it automatically.

## Quick start

```bash
git clone https://github.com/ps-research/pre-agi-power-structures.git
cd pre-agi-power-structures
julia --project=. -e 'using Pkg; Pkg.instantiate()'
make all
```

That downloads the dataset (~2 min), unpacks it (~30 s), and generates all 7
figures into `figures/<name>/` (PDF + 600 DPI PNG + JSON metadata). Total time
on a 32-thread machine: ~3 minutes.

## Per-figure commands

`make <stem>` regenerates a single figure. The stem is the experiment filename
without the `.jl` extension:

| Make target | Figure | Description |
|---|---|---|
| `01_fig3_1_present_day_map` | Fig 3.1 | Present-day calibration map: anchor + 4 O/E neighbors on the (O, E) slice at M=2 |
| `02_fig3_2_neighbor_sensitivity` | Fig 3.2 | ΔL̄ bar chart for the 10 one-step perturbations of the anchor |
| `03_fig3_3_confusion_network` | Fig 3.3 | Trajectory confusion network + sorted top-10 ambiguous-pair table |
| `04_fig3_4_OS_paradox_arc` | Fig 3.4 | OS Paradox 3-panel arc: commoditization → value-layer migration → leverage |
| `05_fig3_5_projection_scenarios` | Fig 3.5 | Four near-future scenarios from the present-day anchor (per-state L(t)) |
| `06_fig3_6_cognitive_vs_physical` | Fig 3.6 | Population-fraction-displaced heatmap on (O, E) at M=2 |
| `07_fig3_7_R_intervention` | Fig 3.7 | Effect of R on the present-day path (R = 0.0, 0.3, 0.9) |

## Repository layout

```
.
├── README.md                 (this file)
├── LICENSE                   (MIT — code)
├── Project.toml              (Julia dependencies)
├── Makefile                  (master runner)
├── data/
│   ├── fetch.sh              (downloads + verifies Zenodo dataset)
│   └── sweep_results/        (populated by fetch.sh — gitignored)
├── lib/
│   └── figures_lib.jl        (shared palette, theme, CSV/TS loaders)
├── experiments/
│   └── 0X_*.jl               (one script per figure)
└── figures/                  (generated output — gitignored)
```

## Reproducibility

Continuous integration runs `make all` on every push and uploads the regenerated
figures as a build artifact, so the green ✓ on the latest commit is evidence that
the dataset → figures pipeline still works on a clean Ubuntu machine. See the
[Actions tab](https://github.com/ps-research/pre-agi-power-structures/actions).

The simulation code that produced the dataset is currently held in a private
repository pending paper acceptance. Once accepted, it will be released as the
`TheDispensabilityGame.jl` Julia package; this repository will be updated to
declare a dependency on the published package version.

## License

- **Code** (this repository, Project.toml, Makefile, fetch.sh, experiments, lib):
  MIT (see `LICENSE`).
- **Figures and data**: CC-BY-4.0, inherited from the Zenodo dataset license.
  Cite the dataset DOI when reusing.

---

Built with [Claude Code](https://claude.ai/code) using Claude Opus 4.7 (Max effort, 1M context).
