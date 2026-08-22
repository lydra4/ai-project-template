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

## Setup

```bash
pip install -r dev-requirements.txt -r prod-requirements.txt
# or: conda env create -f env.yaml
```

## Quality checks

CI (`.github/workflows/ci-cd.yaml`) runs these on every push/PR — run them locally before committing:

```bash
black --check src tests
isort --check-only src tests
ruff check src tests
mypy src
bandit -r src/ -ll -ii
pytest -q --cov=src --cov-report=term-missing
```

## Conventions

- All functions must have type annotations (`mypy` runs with `disallow_untyped_defs = true`).
- Formatting is black + isort (black profile); linting is ruff (`E, F, I, UP, B`).
- Configuration is managed with Hydra/OmegaConf (`config/config.yaml`); avoid hard-coded parameters.
- Logging: call `setup_logging()` from `src/utils/general_utils.py`, which loads `config/logging.yaml`. Use module-level `logging.getLogger(__name__)`, never `print`.
- Secrets come from environment variables (see `src/.env.example`); never commit credentials — CI runs Gitleaks on full history.
- Dependencies are pinned exactly (`==`); Dependabot updates them weekly in grouped PRs.

## CI/CD and automation

- `ci-cd.yaml` — quality checks, Docker build + Trivy scan (push to ghcr.io on non-PR events), Gitleaks secret scan. The deploy job (Hugging Face Space) is currently commented out.
- `claude.yaml` — interactive Claude agent, triggered by `@claude` mentions in issues/PR comments.
- `claude-review.yaml` — automatic Claude review on every PR open/update.
- `claude-ci-triage.yaml` — Claude diagnoses failures of the "AI Project CI/CD" workflow and comments the root cause.
- All Claude workflows run on AWS Bedrock (ap-southeast-1) via OIDC; the role ARN is in the `AWS_ROLE_TO_ASSUME` secret.
