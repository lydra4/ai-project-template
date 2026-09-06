# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

This is a data science project template (Python 3.13). New projects clone it and
replace the placeholder names: `temp` in `pyproject.toml`, `env.yaml`, and the
`Makefile`'s `IMAGE`; `template` in `docker/Dockerfile`'s `NON_ROOT_USER`; and the
workflow name in `ci-cd.yaml`.

## Repository structure

- `src/` — application code. Currently `src/utils/general_utils.py` (logging setup, config helpers).
- `tests/` — pytest suite; test files mirror `src/` module names (`test_general_utils.py`).
- `config/` — `config.yaml` (Hydra app config) and `logging.yaml` (dictConfig logging).
- `data/` — staged data folders: `01-raw/`, `02-preprocessed/`, `03-processed/`. Never commit data files.
- `notebooks/` — exploratory notebooks; not linted or tested by CI.
- `Makefile` — task entry point: `build`, `run`, `clean`, `setup`, `remove`, `check`, `test`. The image name is `IMAGE` on line 1; targets are `.PHONY` so they still run when a same-named directory exists.
- `scripts/` — conda environment helpers (`setup_env.sh`, `remove_env.sh`), wrapped by `make setup` / `make remove`.
- `docker/Dockerfile` — multi-stage build (builder venv → slim runtime).
- `dev-requirements.txt` / `prod-requirements.txt` — pinned dependencies. Dev = tooling only; runtime deps go in prod.
- `.vscode/settings.json` / `.vscode/extensions.json` — tracked on purpose (see Editor setup).

## Setup

```bash
make setup    # conda env from env.yaml + pre-commit install (runs scripts/setup_env.sh)
make remove   # tear that env down again
# or: pip install -r dev-requirements.txt -r prod-requirements.txt
```

The conda env is named after `name:` in `env.yaml` (`temp` until renamed). After creating
it, run **Python: Select Interpreter** in VS Code and pick that env — the ruff and mypy
extensions resolve their binaries from the selected interpreter.

## Editor setup

`.vscode/` is committed so every clone behaves identically. `settings.json` says how the
tools behave; `extensions.json` lists the extensions those settings depend on — settings
naming an uninstalled extension fail *silently*, so both files are required.

- `ruff` is the Python formatter, with `formatOnSave` plus `organizeImports`/`fixAll` code
  actions on save. Without this, `ruff format` violations are invisible until pre-commit
  rewrites the files and aborts the commit.
- `*.importStrategy = "fromEnvironment"` (ruff and mypy) forces the env's pinned binary
  instead of the extension's bundled copy; a version mismatch makes the editor and
  pre-commit disagree.
- `mypy-type-checker` surfaces `disallow_untyped_defs` while typing. **Do not set
  `mypy-type-checker.preferDaemon`** — in 2026.6.0 it routes into a code path that raises
  `KeyError: 'daemonStatusFile'` on every lint, and since `showNotifications` defaults to
  `off` the failure is completely silent: no squiggles, no error, errors only in the
  Output → Mypy log.
- `files.insertFinalNewline` + `files.trimFinalNewlines: false` mirror the
  `end-of-file-fixer` hook. VS Code does not add a final newline on its own, so without
  these every hand-edited file gets rewritten by pre-commit. (`files.trimTrailingWhitespace`
  would likewise mirror the `trailing-whitespace` hook; not set yet.)
- `[makefile]` sets `editor.insertSpaces: false`. Make rejects space-indented recipe lines
  with `*** missing separator`, and the `[python]`-scoped formatter settings do not cover
  this file type. The setting only affects new typing — converting an existing file needs
  **Convert Indentation to Tabs**.
- `check-json` skips `.vscode/` (`exclude: ^\.vscode/`) because both files are JSONC —
  comments and trailing commas are legal there but rejected by Python's strict json parser.
- Formatter settings are scoped to `[python]`, so notebooks are untouched (`nbstripout`
  handles those). File-hygiene settings are global, matching the hooks.

Editor config is a convenience only — `pre-commit` and CI are the enforcement.

## Quality checks

`.pre-commit-config.yaml` is the single source of truth. CI runs the same hooks, so local
and CI cannot disagree:

```bash
make check   # pre-commit run --all-files: ruff, mypy, bandit, gitleaks, nbstripout, file hygiene
make test    # pytest -q --cov=src --cov-report=term-missing; not a hook, run separately
```

Do not re-list individual tool commands in `ci-cd.yaml` — that split is what let a broken
`mypy_path` pass CI while failing every local commit. Add or change checks in
`.pre-commit-config.yaml` only.

## Conventions

- All functions must have type annotations (`mypy` runs with `disallow_untyped_defs = true`).
- Formatting, linting, and import sorting are all ruff (`ruff format`; lint rules `E, F, I, UP, B`).
- Configuration is managed with Hydra/OmegaConf (`config/config.yaml`); avoid hard-coded parameters.
- Logging: call `setup_logging()` from `src/utils/general_utils.py`, which loads `config/logging.yaml`. Use module-level `logging.getLogger(__name__)`, never `print`.
- Secrets come from environment variables (see `.env.example` at the repo root); never commit credentials — CI runs Gitleaks on full history.
- Dependencies are pinned exactly (`==`); Dependabot updates them weekly in grouped PRs.

## CI/CD and automation

- `ci-cd.yaml` is the only workflow — `pre-commit run --all-files` + pytest, Docker build + Trivy scan (push to ghcr.io on non-PR events), Gitleaks secret scan over full history. The deploy job (Hugging Face Space) is currently commented out.
- `.github/dependabot.yaml` — weekly grouped dependency PRs.
