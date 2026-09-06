#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_NAME=$(awk '/^name:/ {print $2}' "$PROJECT_ROOT/env.yaml")

if [ -z "$ENV_NAME" ] || [ "$ENV_NAME" = "base" ]; then
    echo "❌ Could not read a usable environment name from env.yaml."
    exit 1
fi

# Conda's shell functions reference unset variables.
set +u
eval "$(conda shell.bash hook)"
conda deactivate 2>/dev/null || true
set -u

echo "🧹 Removing conda environment: $ENV_NAME"
conda env remove -n "$ENV_NAME" -y
echo "✨ Removed '$ENV_NAME'."
