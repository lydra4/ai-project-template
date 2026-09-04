# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

This is a data science project template (Python 3.13). New projects clone it and
replace the placeholder names (`temp` in `pyproject.toml` and `env.yaml`, the
Dockerfile name in `docker/`).

## Repository structure

- `src/` — application code. Currently `src/utils/general_utils.py` (logging setup, config helpers).
- `tests/` — pytest suite; test files mirror `src/` module names (`test_general_utils.py`).
- `config/` — `config.yaml` (Hydra app config) and `logging.yaml` (dictConfig logging).
- `data/` — staged data folders: `01-raw/`, `02-preprocessed/`, `03-processed/`. Never commit data files.
- `notebooks/` — exploratory notebooks; not linted or tested by CI.
- `scripts/` — docker and environment helper scripts.
- `docker/template.Dockerfile` — multi-stage build (builder venv → slim runtime).
- `dev-requirements.txt` / `prod-requirements.txt` — pinned dependencies. Dev = tooling only; runtime deps go in prod.
- `.vscode/settings.json` — tracked on purpose; wires ruff as the editor formatter (see Editor setup).

## Setup

```bash
bash scripts/environment/setup_env.sh   # conda env from env.yaml + pre-commit install
# or: pip install -r dev-requirements.txt -r prod-requirements.txt
```

The conda env is named after `name:` in `env.yaml` (`temp` until renamed). After creating
it, run **Python: Select Interpreter** in VS Code and pick that env — the ruff and mypy
extensions resolve their binaries from the selected interpreter.

## Editor setup

`.vscode/settings.json` is committed so every clone formats identically:

- `ruff` is the Python formatter, with `formatOnSave` plus `organizeImports`/`fixAll` code
  actions on save. Without this, `ruff format` violations are invisible until pre-commit
  rewrites the files and aborts the commit.
- `ruff.importStrategy = "fromEnvironment"` forces the env's pinned ruff instead of the
  extension's bundled copy; a version mismatch makes the editor and pre-commit disagree.
- Settings are scoped to `[python]`, so notebooks are untouched (`nbstripout` handles those).

Editor config is a convenience only — `pre-commit` and CI are the enforcement.

## Quality checks

CI (`.github/workflows/ci-cd.yaml`) runs these on every push/PR — run them locally before committing:

```bash
ruff format --check src tests
ruff check src tests
mypy src
bandit -r src/ -ll -ii
pytest -q --cov=src --cov-report=term-missing
```

## Conventions

- All functions must have type annotations (`mypy` runs with `disallow_untyped_defs = true`).
- Formatting, linting, and import sorting are all ruff (`ruff format`; lint rules `E, F, I, UP, B`).
- Configuration is managed with Hydra/OmegaConf (`config/config.yaml`); avoid hard-coded parameters.
- Logging: call `setup_logging()` from `src/utils/general_utils.py`, which loads `config/logging.yaml`. Use module-level `logging.getLogger(__name__)`, never `print`.
- Secrets come from environment variables (see `src/.env.example`); never commit credentials — CI runs Gitleaks on full history.
- Dependencies are pinned exactly (`==`); Dependabot updates them weekly in grouped PRs.

## CI/CD and automation

- `ci-cd.yaml` is the only workflow — quality checks, Docker build + Trivy scan (push to ghcr.io on non-PR events), Gitleaks secret scan. The deploy job (Hugging Face Space) is currently commented out.
- `.github/dependabot.yaml` — weekly grouped dependency PRs.
