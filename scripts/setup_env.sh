#!/bin/bash

set -euo pipefail

set +u
eval "$(conda shell.bash hook)"
set -u

if ! command -v mamba &> /dev/null; then
    echo "⚡ Installing mamba into base environment..."
    conda install -n base -c conda-forge mamba -y
fi

echo "🚀 Creating environment from env.yaml using mamba..."
mamba env create -f env.yaml -y
echo "✅ Environment created."

ENV_NAME=$(awk '/^name:/ {print $2}' env.yaml)

echo "🔧 Activating environment: $ENV_NAME ..."
set +u
conda activate "$ENV_NAME"
set -u

echo "🛠️ Setting up pre-commit..."
pre-commit install
echo "✅ Pre-commit setup completed."

if pre-commit run --all-files; then
    echo "✅ Pre-commit checks passed."
else
    echo "⚠️ Pre-commit checks failed; review the output above."
fi

echo "🧹 Cleaning conda & pip caches..."
mamba clean -a -y
conda clean --index-cache -y || true
pip cache purge
pre-commit clean
echo "✨ Cleanup done."
