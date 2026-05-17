#!/usr/bin/env bash
# Downloads the AGI Game grand-sweep dataset from Zenodo.
# Idempotent: skips if already present and verified.
set -euo pipefail

DATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sweep_results"
ZENODO_URL="https://zenodo.org/api/records/20259915/files/sweep_results_v1.tar.gz/content"
EXPECTED_MD5="b9b058ffae24b25fb8bad6f4db59f738"
ZENODO_DOI="10.5281/zenodo.20259915"
TARBALL="$(mktemp -t sweep_results_v1.XXXXXX.tar.gz)"
trap "rm -f \"$TARBALL\"" EXIT

if [ -f "$DATA_DIR/grand_sweep_summary.csv" ] && [ -d "$DATA_DIR/grand_sweep_timeseries" ]; then
    echo "Dataset already present at $DATA_DIR (skipping)."
    exit 0
fi

mkdir -p "$DATA_DIR"
echo "Downloading 1.57 GB from Zenodo (DOI: $ZENODO_DOI)..."
curl -L --fail --progress-bar -o "$TARBALL" "$ZENODO_URL"

echo "Verifying MD5..."
echo "$EXPECTED_MD5  $TARBALL" | md5sum -c

echo "Extracting to $DATA_DIR..."
tar -xzf "$TARBALL" -C "$DATA_DIR"

n_ts=$(find "$DATA_DIR/grand_sweep_timeseries" -name "*.csv" 2>/dev/null | wc -l)
echo "Done. $n_ts time-series CSVs unpacked + summary + pattern analysis."
