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
        "product_features": "",
    }


class ProtectedTupleTests(unittest.TestCase):
    def test_local_and_ci_kas_process_changes_are_material(self) -> None:
        paths = (
            ".github/workflows/layer-adoption-gate.yml",
            ".gitattributes",
            "ci/layer-adoption-contract.json",
            "ci/layer-adoption-tuples.json",
            "kas/lmp-dynamicdevices.yml",
            "meta-dynamicdevices-bsp",
            "meta-dynamicdevices-distro",
            "meta-partner-nxp-imx",
            "scripts/kas-build-base.sh",
            "scripts/kas-shell-base.sh",
            "scripts/validation/capture-layer-state.sh",
            "scripts/validation/compare-layer-state.py",
            "scripts/validation/detect-layer-adoption.py",
            "scripts/validation/generate-layer-adoption-test-keys.sh",
            "scripts/validation/run-layer-adoption-regression.py",
        )
        for path in paths:
            with self.subTest(path=path):
                self.assertTrue(MODULE.is_material_path(path))

    def test_unrelated_utility_change_is_not_material(self) -> None:
        self.assertFalse(MODULE.is_material_path("scripts/analyze-boot-logs.sh"))

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

    def test_missing_product_features_fails(self) -> None:
        candidate = entry("existing")
        del candidate["product_features"]
        with self.assertRaisesRegex(ValueError, "lacks product_features"):
            self.validate(document(entry("existing")), document(candidate))

    def test_redefining_product_features_fails(self) -> None:
        candidate = entry("existing")
        candidate["product_features"] = "display"
        with self.assertRaisesRegex(ValueError, "redefined=existing"):
            self.validate(document(entry("existing")), document(candidate))


if __name__ == "__main__":
    unittest.main()
