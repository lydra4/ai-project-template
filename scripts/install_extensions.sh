#!/bin/bash

set -euo pipefail

echo "🔌 Installing VS Code extensions..."
if command -v code &> /dev/null; then
    extensions=(
        "charliermarsh.ruff"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-python.mypy-type-checker"
        "imagirom.hydralance"
        "redhat.vscode-yaml"
    )

    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "^${ext}$"; then
            echo "  ✓ $ext (already installed)"
        else
            echo "  📦 Installing $ext..."
            code --install-extension "$ext" --force
        fi
    done
    echo "✅ VS Code extensions installed."
else
    echo "⚠️  VS Code CLI not found. Skipping extension installation."
fi
