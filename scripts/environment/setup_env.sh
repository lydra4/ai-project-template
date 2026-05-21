set -e

eval "$(conda shell.bash hook)"

if ! command -v mamba &> /dev/null; then
    echo "⚡ Installing mamba into base environment..."
    conda install -n base -c conda-forge mamba -y
fi

echo "🚀 Creating environment from env.yaml using mamba..."
mamba env create -f env.yaml -y
echo "✅ Environment created."

# Extract env name from env.yaml
ENV_NAME=$(grep -E '^name:' env.yaml | awk '{print $2}')

echo "🔧 Activating environment: $ENV_NAME ..."
conda activate "$ENV_NAME"

echo "🛠️ Setting up pre-commit..."
pre-commit install
pre-commit run --all-files || true
echo "✅ Pre-commit setup completed."

echo "🧹 Cleaning conda & pip caches..."
mamba clean -a -y
conda clean --index-cache -y || true
pip cache purge
pre-commit clean
echo "✨ Cleanup done."
