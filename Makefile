# Master runner for figure reproduction.
# Targets:
#   make            — fetch dataset then generate all figures
#   make data       — fetch the Zenodo dataset only
#   make <stem>     — regenerate a single figure (use experiment filename stem,
#                     e.g. `make 01_fig1_1_two_family_Lt`)
#   make clean      — delete generated figures
#   make clean-data — delete fetched dataset

JULIA_THREADS ?= 32
JULIA         := julia --project=. -t $(JULIA_THREADS)

EXP_FILES := $(sort $(wildcard experiments/*.jl))
EXP_NAMES := $(notdir $(basename $(EXP_FILES)))

.PHONY: all data clean clean-data help $(EXP_NAMES)

all: data $(EXP_NAMES)

data: data/sweep_results/.fetched

data/sweep_results/.fetched:
	@./data/fetch.sh
	@touch $@

# Static pattern rule explicitly tied to each experiment name. Necessary
# because GNU Make does not apply implicit pattern rules to PHONY targets.
# Enables both `make all` and `make 01_fig1_1_two_family_Lt` to work.
$(EXP_NAMES): %: experiments/%.jl | data
	$(JULIA) $<

clean:
	rm -rf figures/

clean-data:
	rm -rf data/sweep_results/

help:
	@echo "Targets:"
	@echo "  make                — fetch data + generate all figures"
	@echo "  make data           — fetch Zenodo dataset only"
	@echo "  make <stem>         — regenerate one figure (e.g. 'make 01_fig1_1_two_family_Lt')"
	@echo "  make clean          — remove generated figures"
	@echo "  make clean-data     — remove fetched dataset"
