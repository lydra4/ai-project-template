set -e

ENV_NAME="${1}"

eval "$(conda shell.bash hook)"

echo "🚀 Creating environment: $ENV_NAME ..."
conda env create -f env.yaml -n "$ENV_NAME" -y
echo "✅ Environment '$ENV_NAME' created."

echo "🔧 Activating environment..."
conda activate "$ENV_NAME"

echo "🛠️  Setting up pre-commit..."
pre-commit install
pre-commit run --all-files
echo "✅ Pre-commit setup completed."