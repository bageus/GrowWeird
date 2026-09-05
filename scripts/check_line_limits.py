#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

MAX_LINES = 350
ROOT = Path(__file__).resolve().parents[1]
TEXT_EXTENSIONS = {
    ".cfg",
    ".gd",
    ".godot",
    ".json",
    ".md",
    ".py",
    ".sh",
    ".tres",
    ".tscn",
    ".txt",
    ".yaml",
    ".yml",
}
IGNORED_PARTS = {".git", ".godot", "android"}
GENERATED_DATA = {"tree_flower_layouts.json", "tree_leaf_layouts.json"}


def should_check(path: Path) -> bool:
    if any(part in IGNORED_PARTS for part in path.parts):
        return False
    if path.name in GENERATED_DATA and "visual" in path.parts:
        return False
    return path.suffix.lower() in TEXT_EXTENSIONS or path.name in {".gitignore", ".editorconfig", ".gitattributes"}


def line_count(path: Path) -> int:
    with path.open("r", encoding="utf-8") as handle:
        return sum(1 for _line in handle)


def main() -> int:
    violations: list[tuple[Path, int]] = []
    checked = 0
    for path in ROOT.rglob("*"):
        if not path.is_file() or not should_check(path):
            continue
        checked += 1
        count = line_count(path)
        if count > MAX_LINES:
            violations.append((path.relative_to(ROOT), count))

    if violations:
        print(f"Files above {MAX_LINES} lines:")
        for path, count in sorted(violations):
            print(f"  {path}: {count}")
        return 1

    print(f"Checked {checked} authored text files: all are <= {MAX_LINES} lines.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
