#!/usr/bin/env python3
"""
Создаёт полный бекап проекта (архив ZIP) для отчёта/переноса.

Поведение (как в Luma2025/backup_project.py):
- Включает все файлы и папки проекта, кроме тех, что в исключениях.
- Секреты (.env, credentials.json, *.key и т.п.) не попадают в архив.
- Архивы сохраняются ВНУТРИ проекта: папка backups/.
- Хранится не более 3 архивов; лишние удаляются (остаются самые новые).
- Ctrl+C во время упаковки: без длинного traceback, незавершённый .zip удаляется.

Дополнительно для C# / Visual Studio: исключаются bin/, obj/, .vs и др.
Папка YouTubeDownloads (скачанные видео) в архив не включается;
внутри неё отдельно исключается YouTubeDownloads/youtube.com (кэш/данные по домену).

Дистрибутив для Telegram/GitHub: папка release-staging и любые *.zip в проекте
в бекап не попадают (не дублировать тяжёлые архивы в backups/).
"""

from __future__ import annotations

import fnmatch
import sys
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


# Корень проекта = папка, где лежит этот скрипт
PROJECT_ROOT = Path(__file__).resolve().parent
BACKUP_DIR = PROJECT_ROOT / "backups"
BACKUP_PREFIX = "youtube-dl-gui-master_backup_"
MAX_BACKUPS = 3

# Папки-сегменты пути: если любой сегмент совпадает — файл не в архив
EXCLUDE_DIRS = {
    "venv",
    ".venv",
    "__pycache__",
    ".git",
    "backups",
    ".vs",
    ".idea",
    ".mypy_cache",
    ".pytest_cache",
    "node_modules",
    "YouTubeDownloads",
    # Подготовка релиза (exe + zip локально; в Git уже в .gitignore)
    "release-staging",
    # .NET / MSBuild
    "bin",
    "obj",
    "packages",
    "TestResults",
}

# Префикс относительного пути (несколько сегментов подряд), не только одно имя папки
EXCLUDE_RELATIVE_PREFIXES: tuple[tuple[str, ...], ...] = (
    ("YouTubeDownloads", "youtube.com"),
)

EXCLUDE_FILES_EXACT = {
    # Собранное приложение в корне репо (если положили для отправки в Telegram)
    "youtube-dl-gui.exe",
    "youtube-dl-gui-updater.exe",
    ".env",
    ".env.local",
    ".env.development",
    ".env.production",
    "credentials.json",
}

EXCLUDE_FILE_GLOBS = [
    "*.zip",
    "*.log",
    "*.db",
    "*.db-shm",
    "*.db-wal",
    "*.sqlite",
    "*.sqlite3",
    "*.suo",
    "*.user",
    "*.pfx",
    "*.p12",
    "*.pem",
    "*.key",
]


C = {
    "reset": "\033[0m",
    "bold": "\033[1m",
    "green": "\033[92m",
    "yellow": "\033[93m",
    "cyan": "\033[96m",
    "magenta": "\033[95m",
    "red": "\033[91m",
    "dim": "\033[2m",
}


def msg(text: str, color: str = "reset") -> None:
    try:
        if hasattr(sys.stdout, "reconfigure"):
            sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    except Exception:
        pass

    try:
        print(f"{C.get(color, '')}{text}{C['reset']}")
    except UnicodeEncodeError:
        safe = text.encode(sys.stdout.encoding or "utf-8", errors="replace").decode(
            sys.stdout.encoding or "utf-8", errors="replace"
        )
        print(f"{C.get(color, '')}{safe}{C['reset']}")


def ensure_backup_dir() -> None:
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)


def get_backups() -> list[tuple[Path, float]]:
    if not BACKUP_DIR.exists():
        return []
    files: list[tuple[Path, float]] = []
    for p in BACKUP_DIR.glob(f"{BACKUP_PREFIX}*.zip"):
        if p.is_file():
            files.append((p, p.stat().st_mtime))
    files.sort(key=lambda x: x[1], reverse=True)
    return files


def trim_old_backups(backups: list[tuple[Path, float]]) -> None:
    for path, _ in backups[MAX_BACKUPS:]:
        try:
            path.unlink()
            msg(f"  Удалён старый бекап: {path.name}", "red")
        except OSError:
            pass


@dataclass(frozen=True)
class ExcludeDecision:
    excluded: bool
    reason: str | None = None


def should_exclude_file(path: Path, rel: Path) -> ExcludeDecision:
    parts = rel.parts
    for prefix in EXCLUDE_RELATIVE_PREFIXES:
        if len(parts) >= len(prefix) and parts[: len(prefix)] == prefix:
            return ExcludeDecision(True, f"prefix:{Path(*prefix).as_posix()}")

    for part in rel.parts:
        if part in EXCLUDE_DIRS:
            return ExcludeDecision(True, f"dir:{part}")

    if path.name in EXCLUDE_FILES_EXACT:
        return ExcludeDecision(True, f"file:{path.name}")

    for g in EXCLUDE_FILE_GLOBS:
        if fnmatch.fnmatch(path.name.lower(), g.lower()):
            return ExcludeDecision(True, f"glob:{g}")

    return ExcludeDecision(False, None)


def backup_project() -> Path | None:
    ensure_backup_dir()
    date_str = datetime.now().strftime("%Y-%m-%d_%H-%M")
    archive_path = BACKUP_DIR / f"{BACKUP_PREFIX}{date_str}.zip"

    msg("\n  📦 Создание архива...", "cyan")
    count = 0
    skipped = 0

    try:
        with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for path in sorted(PROJECT_ROOT.rglob("*")):
                if not path.is_file():
                    continue

                try:
                    rel = path.relative_to(PROJECT_ROOT)
                except ValueError:
                    continue

                if path.resolve() == archive_path.resolve():
                    skipped += 1
                    continue

                decision = should_exclude_file(path, rel)
                if decision.excluded:
                    skipped += 1
                    continue

                zf.write(path, rel.as_posix())
                count += 1
    except KeyboardInterrupt:
        msg("\n  Остановлено (Ctrl+C). Архив не завершён.", "yellow")
        try:
            if archive_path.is_file():
                archive_path.unlink()
                msg(f"  Удалён незавершённый файл: {archive_path.name}", "dim")
        except OSError:
            pass
        return None

    msg(f"  Добавлено файлов: {count}", "dim")
    msg(f"  Пропущено файлов: {skipped}", "dim")
    return archive_path


if __name__ == "__main__":
    msg("╔══════════════════════════════════════════════════╗", "cyan")
    msg("║     youtube-dl-gui-master — Бекап проекта        ║", "cyan")
    msg("╚══════════════════════════════════════════════════╝", "cyan")

    try:
        out = backup_project()
    except KeyboardInterrupt:
        msg("\n  Остановлено (Ctrl+C).", "yellow")
        sys.exit(130)

    if out is None:
        sys.exit(130)

    msg(f"\n  ✅ Бекап создан: {out.name}", "green")
    msg(f"     {out}", "dim")

    backups = get_backups()
    if backups:
        msg(f"\n  📋 Архивы бекапов (не более {MAX_BACKUPS}):", "yellow")
        for i, (path, mtime) in enumerate(backups[:MAX_BACKUPS], 1):
            dt = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
            size_mb = path.stat().st_size / (1024 * 1024)
            mark = " ← новый" if path == out else ""
            msg(f"     {i}. {path.name}  {dt}  ({size_mb:.2f} МБ){mark}", "magenta")

    if len(backups) > MAX_BACKUPS:
        msg("\n  🗑 Очистка старых бекапов:", "yellow")
        trim_old_backups(backups)

    msg("")
