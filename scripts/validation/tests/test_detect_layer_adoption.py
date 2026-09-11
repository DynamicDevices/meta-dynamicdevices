#!/usr/bin/env python3
"""Regression tests for protected layer-adoption tuple handling."""

from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "detect-layer-adoption.py"
SPEC = importlib.util.spec_from_file_location("detect_layer_adoption", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def document(*tuples: dict[str, str]) -> str:
    return json.dumps({"schema": 1, "tuples": list(tuples)})


def entry(tuple_id: str, machine: str = "machine-a") -> dict[str, str]:
    return {
        "id": tuple_id,
        "machine": machine,
        "distro": "distro-a",
        "image": "image-a",
        "config": "kas/test.yml",
    }


class ProtectedTupleTests(unittest.TestCase):
    def validate(self, baseline: str, candidate: str) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "kas").mkdir()
            (root / "kas/test.yml").touch()
            matrix = root / "ci/layer-adoption-tuples.json"
            matrix.parent.mkdir()
            matrix.write_text(candidate, encoding="utf-8")
            result = subprocess.CompletedProcess([], 0, stdout=baseline, stderr="")
            with mock.patch.object(MODULE.subprocess, "run", return_value=result), mock.patch.object(
                MODULE.Path, "is_file", return_value=True
            ):
                MODULE.validate_tuple_matrix("baseline", matrix)

    def test_extension_preserves_existing_tuple(self) -> None:
        self.validate(document(entry("existing")), document(entry("existing"), entry("new")))

    def test_removing_existing_tuple_fails(self) -> None:
        with self.assertRaisesRegex(ValueError, "removed=existing"):
            self.validate(document(entry("existing")), document(entry("replacement")))

    def test_redefining_existing_tuple_fails(self) -> None:
        with self.assertRaisesRegex(ValueError, "redefined=existing"):
            self.validate(document(entry("existing")), document(entry("existing", "machine-b")))

    def test_duplicate_candidate_id_fails(self) -> None:
        with self.assertRaisesRegex(ValueError, "duplicate tuple id existing"):
            self.validate(document(entry("existing")), document(entry("existing"), entry("existing")))


if __name__ == "__main__":
    unittest.main()
