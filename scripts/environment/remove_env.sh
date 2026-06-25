#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/env.yaml"

if ! command -v conda >/dev/null 2>&1; then
    echo "❌ Error: conda is not installed or not available in PATH."
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: env.yaml not found at: $ENV_FILE"
    exit 1
fi

ENV_NAME="$(
    awk '
        /^[[:space:]]*name[[:space:]]*:/ {
            sub(/^[^:]*:[[:space:]]*/, "")
            sub(/[[:space:]]*#.*/, "")
            gsub(/[[:space:]]/, "")
            print
            exit
        }
    ' "$ENV_FILE"
)"

if [ -z "$ENV_NAME" ]; then
    echo "❌ Error: env.yaml does not define an environment name."
    exit 1
fi

if [ "$ENV_NAME" = "base" ]; then
    echo "❌ Error: refusing to remove the base Conda environment."
    exit 1
fi

ENV_PATH="$(
    conda info --envs |
        awk -v env="$ENV_NAME" '$1 == env { print $NF; exit }'
)"

if [ -z "$ENV_PATH" ]; then
    echo "ℹ️ Conda environment '$ENV_NAME' does not exist."
    exit 0
fi

echo "Removing Conda environment: $ENV_NAME"
echo "Environment path: $ENV_PATH"

# Conda shell functions can reference unset variables.
set +u
eval "$(conda shell.bash hook)"
conda deactivate 2>/dev/null || true
set -u

if conda env remove -n "$ENV_NAME" -y; then
    echo "✅ Conda environment '$ENV_NAME' was removed."
else
    echo "❌ Conda could not remove '$ENV_NAME'."
    echo "Close processes using this environment and try again."
    exit 1
fi

if [ -d "$ENV_PATH" ]; then
    echo "⚠️ The environment directory still exists:"
    echo "   $ENV_PATH"
    echo "It was not deleted automatically for safety."
    exit 1
fi

echo "Cleaning Conda index caches..."
conda clean --index-cache -y

echo "✨ Environment '$ENV_NAME' was removed successfully."
