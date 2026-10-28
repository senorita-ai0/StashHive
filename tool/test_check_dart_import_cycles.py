from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tool.check_dart_import_cycles import build_import_graph, find_import_cycles


class DartImportCycleCheckTests(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self._temporary_directory.cleanup)
        self.lib_root = Path(self._temporary_directory.name) / "lib"
        self.lib_root.mkdir()

    def _write(self, relative_path: str, source: str) -> Path:
        path = self.lib_root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8")
        return path.resolve()

    def test_detects_cycle_across_package_and_relative_imports(self) -> None:
        first = self._write(
            "first.dart",
            "import 'package:stashhive/second.dart';\n",
        )
        second = self._write("second.dart", "import 'first.dart';\n")

        graph = build_import_graph(self.lib_root)
        cycles = find_import_cycles(graph)

        self.assertEqual(len(cycles), 1)
        self.assertEqual(cycles[0], [first, second, first])

    def test_includes_conditional_import_and_export_edges(self) -> None:
        entry = self._write(
            "entry.dart",
            "import 'core.dart' if (dart.library.io) 'core_io.dart';\n"
            "export 'public.dart';\n",
        )
        core = self._write("core.dart", "")
        core_io = self._write("core_io.dart", "")
        public = self._write("public.dart", "")

        graph = build_import_graph(self.lib_root)

        self.assertEqual(graph[entry], {core, core_io, public})
        self.assertEqual(find_import_cycles(graph), [])

    def test_ignores_external_imports(self) -> None:
        entry = self._write(
            "entry.dart",
            "import 'dart:async';\n"
            "import 'package:flutter/material.dart';\n"
            "import 'package:third_party/library.dart';\n",
        )

        graph = build_import_graph(self.lib_root)

        self.assertEqual(graph[entry], set())
        self.assertEqual(find_import_cycles(graph), [])

    def test_reports_cycle_in_a_nested_directory(self) -> None:
        nested = self._write("data/reader.dart", "import '../services/codec.dart';\n")
        codec = self._write("services/codec.dart", "import '../data/reader.dart';\n")

        cycles = find_import_cycles(build_import_graph(self.lib_root))

        self.assertEqual(len(cycles), 1)
        self.assertEqual(cycles[0], [codec, nested, codec])


if __name__ == "__main__":
    unittest.main()
