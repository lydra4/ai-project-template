import logging
import logging.config
from collections.abc import Iterator
from pathlib import Path
from unittest import mock

import pytest
import yaml

from src.utils.general_utils import setup_logging

MINIMAL_LOGGING_CONFIG: dict = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"plain": {"format": "%(levelname)s - %(message)s"}},
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "DEBUG",
            "formatter": "plain",
        }
    },
    "root": {"level": "WARNING", "handlers": ["console"]},
}


@pytest.fixture(autouse=True)
def restore_logging_state() -> Iterator[None]:
    root = logging.getLogger()
    saved_handler = root.handlers[:]
    saved_level = root.level
    saved_disable = logging.root.manager.disable
    try:
        yield
    finally:
        root.handlers[:] = saved_handler
        root.setLevel(saved_level)
        logging.root.manager.disable = saved_disable


@pytest.fixture(autouse=True)
def isolated_cwd(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> Path:
    monkeypatch.chdir(tmp_path)
    return tmp_path


@pytest.fixture
def logging_config_file(tmp_path: Path) -> Path:
    config_path = tmp_path / "logging.yaml"
    config_path.write_text(yaml.safe_dump(MINIMAL_LOGGING_CONFIG), encoding="utf-8")
    return config_path


def test_valid_config_is_passed_to_dictconfig(logging_config_file: Path) -> None:
    with mock.patch("logging.config.dictConfig") as mock_dict_config:
        setup_logging(logging_config_path=logging_config_file)

    mock_dict_config.assert_called_once_with(MINIMAL_LOGGING_CONFIG)


def test_valid_config_is_applied_to_root_logger(logging_config_file: Path) -> None:
    setup_logging(logging_config_path=logging_config_file)

    root = logging.getLogger()
    assert root.level == logging.WARNING
    assert [type(handler) for handler in root.handlers] == [logging.StreamHandler]


def test_create_logs_directory(logging_config_file: Path, isolated_cwd: Path) -> None:
    assert not (isolated_cwd / "logs").exists()

    setup_logging(logging_config_path=logging_config_file)

    assert (isolated_cwd / "logs").is_dir()


def test_existing_logs_directory_is_not_an_error(
    logging_config_file: Path,
    isolated_cwd: Path,
) -> None:
    (isolated_cwd / "logs").mkdir()

    setup_logging(logging_config_path=logging_config_file)
    setup_logging(logging_config_path=logging_config_file)

    assert (isolated_cwd / "logs").is_dir()


def test_default_config_path(monkeypatch: pytest.MonkeyPatch) -> None:
    opened_paths: list[str] = []
    real_open = open

    def spy_open(path, *args, **kwargs):  # type: ignore[no-untyped-def]
        opened_paths.append(str(path))
        return real_open(path, *args, **kwargs)

    monkeypatch.setattr("builtins.open", spy_open)

    with mock.patch("logging.config.dictConfig"), mock.patch("logging.basicConfig"):
        setup_logging()

    assert opened_paths == ["./config/logging.yaml"]


def test_missing_file_falls_back_to_basic_config(tmp_path: Path) -> None:
    missing_path = tmp_path / "does-not-exist.yaml"

    with mock.patch("logging.basicConfig") as mock_basic_config:
        setup_logging(logging_config_path=missing_path)

    mock_basic_config.assert_called_once_with(
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.INFO,
    )


def test_malformed_yaml_falls_back_to_basic_config(tmp_path: Path) -> None:
    bad_config = tmp_path / "broken.yaml"
    bad_config.write_text("handlers: [unclosed\n  :: nope", encoding="utf-8")

    with mock.patch("logging.basicConfig") as mock_basic_config:
        setup_logging(logging_config_path=bad_config)

    mock_basic_config.assert_called_once()
    assert mock_basic_config.call_args.kwargs["level"] == logging.INFO


@pytest.mark.parametrize(
    "default_level",
    [logging.DEBUG, logging.INFO, logging.WARNING, logging.ERROR],
)
def test_default_level_is_used_in_fallback(tmp_path: Path, default_level: int) -> None:
    with mock.patch("logging.basicConfig") as mock_basic_config:
        setup_logging(
            logging_config_path=tmp_path / "missing.yaml",
            default_level=default_level,
        )

    assert mock_basic_config.call_args.kwargs["level"] == default_level


def test_fallback_logs_explanatory_message(
    tmp_path: Path, caplog: pytest.LogCaptureFixture
) -> None:
    with caplog.at_level(logging.INFO, logger="src.utils.general_utils"):
        with mock.patch("logging.basicConfig"):
            setup_logging(logging_config_path=tmp_path / "missing.yaml")

    assert "Logging config invalid or missing. Basic config is used." in caplog.text


def test_repository_logging_config_is_valid() -> None:
    config_path = Path(__file__).resolve().parents[1] / "config" / "logging.yaml"

    with mock.patch("logging.config.dictConfig") as mock_dict_config:
        setup_logging(logging_config_path=config_path)

    mock_dict_config.assert_called_once()
    config = mock_dict_config.call_args.args[0]
    assert config["version"] == 1
    assert set(config["root"]["handlers"]) <= set(config["handlers"])
    for handler in config["handlers"].values():
        assert "class" in handler
