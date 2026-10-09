#!/bin/bash

set -euo pipefail

set +u
eval "$(conda shell.bash hook)"
set -u

# Use Conda's libmamba solver (already configured on this system).
export CONDA_SOLVER=libmamba

echo "🚀 Creating environment from env.yaml using conda (libmamba)..."
conda env create -f env.yaml -y
echo "✅ Environment created."

ENV_NAME=$(awk '/^name:/ {print $2}' env.yaml)

echo "🔧 Activating environment: $ENV_NAME ..."
set +u
conda activate "$ENV_NAME"
set -u

echo "🔌 Installing VS Code extensions..."
bash "$(dirname "$0")/install_extensions.sh"

echo "🛠️ Setting up pre-commit..."
pre-commit install
echo "✅ Pre-commit setup completed."

if pre-commit run --all-files; then
    echo "✅ Pre-commit checks passed."
else
    echo "⚠️ Pre-commit checks failed; review the output above."
fi

echo "🧹 Cleaning conda & pip caches..."
conda clean -a -y
pip cache purge
pre-commit clean
echo "✨ Cleanup done."
