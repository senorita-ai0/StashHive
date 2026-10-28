#!/usr/bin/env python3
"""Detect cycles among local Dart imports/exports under lib/.

The check intentionally uses only Python's standard library. It follows both
relative imports and package:stashhive imports, including local URIs in
conditional import/export directives. Third-party and dart: libraries are
outside this package-internal graph.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterable

_DIRECTIVE_RE = re.compile(
    r"^\s*(?:import|export)\s+(.+?);",
    re.MULTILINE | re.DOTALL,
)
_URI_RE = re.compile(r"""['"]([^'"]+)['"]""")
_PACKAGE_PREFIX = "package:stashhive/"


def _resolve_local_uri(importer: Path, uri: str, lib_root: Path) -> Path | None:
    """Resolve a package-internal or relative URI to a Dart file, if local."""
    if uri.startswith(_PACKAGE_PREFIX):
        target = lib_root / uri[len(_PACKAGE_PREFIX) :]
    elif uri.startswith(("dart:", "package:")):
        return None
    else:
        target = importer.parent / uri

    root = lib_root.resolve()
    resolved = target.resolve()
    try:
        resolved.relative_to(root)
    except ValueError:
        return None
    if resolved.suffix != ".dart":
        return None
    return resolved


def build_import_graph(lib_root: Path) -> dict[Path, set[Path]]:
    """Build a graph of existing Dart files and their local import/export edges."""
    root = lib_root.resolve()
    files = sorted(root.rglob("*.dart"))
    graph: dict[Path, set[Path]] = {path: set() for path in files}

    for importer in files:
        source = importer.read_text(encoding="utf-8")
        for directive_match in _DIRECTIVE_RE.finditer(source):
            for uri_match in _URI_RE.finditer(directive_match.group(1)):
                target = _resolve_local_uri(importer, uri_match.group(1), root)
                if target is not None and target in graph:
                    graph[importer].add(target)
    return graph


def find_import_cycles(graph: dict[Path, set[Path]]) -> list[list[Path]]:
    """Return each discovered directed cycle as an ordered closed path."""
    state: dict[Path, int] = {}
    stack: list[Path] = []
    stack_index: dict[Path, int] = {}
    cycles: list[list[Path]] = []
    seen: set[tuple[Path, ...]] = set()

    def canonical_cycle(cycle: list[Path]) -> tuple[Path, ...]:
        # The last node repeats the first. Rotate the open cycle so that the
        # same directed cycle found from another root is only reported once.
        open_cycle = cycle[:-1]
        if not open_cycle:
            return tuple(cycle)
        rotations = [
            tuple(open_cycle[index:] + open_cycle[:index])
            for index in range(len(open_cycle))
        ]
        best = min(rotations, key=lambda item: tuple(str(node) for node in item))
        return best + (best[0],)

    def visit(node: Path) -> None:
        state[node] = 1
        stack_index[node] = len(stack)
        stack.append(node)

        for neighbor in sorted(graph.get(node, set())):
            neighbor_state = state.get(neighbor, 0)
            if neighbor_state == 0:
                visit(neighbor)
            elif neighbor_state == 1:
                cycle = stack[stack_index[neighbor] :] + [neighbor]
                key = canonical_cycle(cycle)
                if key not in seen:
                    seen.add(key)
                    cycles.append(list(key))

        stack.pop()
        stack_index.pop(node, None)
        state[node] = 2

    for node in sorted(graph):
        if state.get(node, 0) == 0:
            visit(node)
    return cycles


def _display_path(path: Path, lib_root: Path) -> str:
    return path.resolve().relative_to(lib_root.resolve()).as_posix()


def main() -> int:
    repository_root = Path(__file__).resolve().parents[1]
    lib_root = repository_root / "lib"
    if not lib_root.is_dir():
        print(f"Architecture check failed: missing source directory {lib_root}", file=sys.stderr)
        return 2

    graph = build_import_graph(lib_root)
    cycles = find_import_cycles(graph)
    if cycles:
        print(f"Found {len(cycles)} local Dart import/export cycle(s):", file=sys.stderr)
        for cycle in cycles:
            print(
                "  " + " -> ".join(_display_path(node, lib_root) for node in cycle),
                file=sys.stderr,
            )
        return 1

    print(f"No local Dart import/export cycles found in {len(graph)} source files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
