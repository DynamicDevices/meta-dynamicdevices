#!/usr/bin/env python3
"""Tests for immutable layer-adoption baseline evidence."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "run-layer-adoption-regression.py"
WORKFLOW_PATH = Path(__file__).parents[3] / ".github/workflows/layer-adoption-gate.yml"
SPEC = importlib.util.spec_from_file_location("run_layer_adoption_regression", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class BaselineEvidenceTests(unittest.TestCase):
    def test_gate_initializes_product_submodules_in_both_worktrees(self) -> None:
        workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
        self.assertEqual(workflow.count("submodule update --init --recursive"), 2)
        self.assertEqual(workflow.count("meta-dynamicdevices-bsp meta-dynamicdevices-distro"), 2)
        self.assertIn("git -C ../baseline", workflow)

    def test_valid_cache_is_accepted_and_tampering_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "packages.txt").write_text("package-a\n", encoding="utf-8")
            marker = {
                "base_sha": "abc123",
                "tuple_id": "machine-image",
                "evidence_sha256": MODULE.evidence_digest(root),
            }
            (root / MODULE.MARKER).write_text(json.dumps(marker), encoding="utf-8")
            self.assertTrue(MODULE.valid_cached_evidence(root, "abc123", "machine-image"))

            (root / "packages.txt").write_text("package-b\n", encoding="utf-8")
            self.assertFalse(MODULE.valid_cached_evidence(root, "abc123", "machine-image"))

    def test_marker_is_not_part_of_evidence_digest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "state.txt").write_text("stable\n", encoding="utf-8")
            before = MODULE.evidence_digest(root)
            (root / MODULE.MARKER).write_text("{}\n", encoding="utf-8")
            self.assertEqual(before, MODULE.evidence_digest(root))


if __name__ == "__main__":
    unittest.main()
