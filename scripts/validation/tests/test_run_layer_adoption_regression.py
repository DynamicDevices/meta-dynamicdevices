#!/usr/bin/env python3
"""Tests for immutable layer-adoption baseline evidence."""

from __future__ import annotations

import importlib.util
import json
import re
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "run-layer-adoption-regression.py"
WORKFLOW_PATH = Path(__file__).parents[3] / ".github/workflows/layer-adoption-gate.yml"
SPEC = importlib.util.spec_from_file_location("run_layer_adoption_regression", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class BaselineEvidenceTests(unittest.TestCase):
    def test_generated_signing_identity_is_validated_before_reuse(self) -> None:
        generator = MODULE_PATH.parent / "generate-layer-adoption-test-keys.sh"
        with tempfile.TemporaryDirectory() as directory:
            keys = Path(directory) / "keys"
            subprocess.run([str(generator), str(keys)], check=True, capture_output=True)
            subprocess.run(
                [str(generator), "--check", str(keys)], check=True, capture_output=True
            )
            (keys / "x509_modsign.crt").write_text("invalid\n", encoding="utf-8")
            invalid = subprocess.run(
                [str(generator), "--check", str(keys)],
                check=False,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(invalid.returncode, 0)
            self.assertIn("invalid or expire within seven days", invalid.stderr)

    def test_local_kas_wrappers_use_ci_container_digest(self) -> None:
        root = WORKFLOW_PATH.parents[2]
        workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
        helper_name = "kas-container-image.sh"
        helper = (root / "scripts" / helper_name).read_text(encoding="utf-8")
        local_pin = re.search(r'^KAS_CONTAINER_IMAGE="([^"]+)"$', helper, re.MULTILINE)
        ci_pin = re.search(r"^\s+image: (\S+)$", workflow, re.MULTILINE)
        self.assertIsNotNone(local_pin)
        self.assertIsNotNone(ci_pin)
        self.assertEqual(local_pin.group(1), ci_pin.group(1))

        wrappers = [
            path for path in (root / "scripts").glob("kas-*.sh")
            if path.name != helper_name and "kas-container" in path.read_text(encoding="utf-8")
        ]
        self.assertTrue(wrappers)
        for wrapper in wrappers:
            with self.subTest(wrapper=wrapper.name):
                self.assertIn(helper_name, wrapper.read_text(encoding="utf-8"))

    def test_worktree_preparation_is_owned_by_shared_driver(self) -> None:
        workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
        self.assertNotIn("submodule update", workflow)

        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            pinned = "a" * 40

            def git_result(command: list[str], **kwargs: object) -> str:
                if "ls-tree" in command:
                    relative = command[-1]
                    return f"160000 commit {pinned}\t{relative}\n"
                if "rev-parse" in command:
                    return pinned + "\n"
                if "status" in command:
                    return ""
                self.fail(f"unexpected git command: {command}")

            def initialize(command: list[str], **kwargs: object) -> None:
                relative = command[-1]
                layer_conf = repository / relative / "conf/layer.conf"
                layer_conf.parent.mkdir(parents=True)
                layer_conf.touch()

            with mock.patch.object(
                MODULE.subprocess, "check_output", side_effect=git_result
            ), mock.patch.object(MODULE.subprocess, "run", side_effect=initialize) as run:
                MODULE.prepare_repository(repository)

            self.assertEqual(run.call_count, 2)

    def test_worktree_preparation_rejects_unpinned_layer(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            layer = repository / MODULE.PRODUCT_SUBMODULES[0]
            (layer / "conf").mkdir(parents=True)
            (layer / "conf/layer.conf").touch()
            results = [
                f"160000 commit {'a' * 40}\t{layer.name}\n",
                "b" * 40 + "\n",
            ]
            with mock.patch.object(
                MODULE.subprocess, "check_output", side_effect=results
            ):
                with self.assertRaisesRegex(RuntimeError, "expected pinned"):
                    MODULE.prepare_repository(repository)

    def test_gate_does_not_run_bitbake_as_root(self) -> None:
        workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
        self.assertNotIn("--user 0:0", workflow)
        self.assertIn("--user 1002:1002", workflow)

    def test_valid_cache_is_accepted_and_tampering_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "packages.txt").write_text("package-a\n", encoding="utf-8")
            marker = {
                "base_sha": "abc123",
                "tuple_id": "machine-image",
                "capture_schema": "schema-a",
                "evidence_sha256": MODULE.evidence_digest(root),
            }
            (root / MODULE.MARKER).write_text(json.dumps(marker), encoding="utf-8")
            self.assertTrue(
                MODULE.valid_cached_evidence(
                    root, "abc123", "machine-image", "schema-a"
                )
            )
            self.assertFalse(
                MODULE.valid_cached_evidence(
                    root, "abc123", "machine-image", "schema-b"
                )
            )

            (root / "packages.txt").write_text("package-b\n", encoding="utf-8")
            self.assertFalse(
                MODULE.valid_cached_evidence(
                    root, "abc123", "machine-image", "schema-a"
                )
            )

    def test_capture_schema_covers_every_evidence_producer(self) -> None:
        root = MODULE_PATH.parents[2]
        first = MODULE.capture_schema_digest(root)
        self.assertRegex(first, r"^[0-9a-f]{64}$")
        self.assertIn("scripts/validation/capture-layer-state.sh", MODULE.CAPTURE_SCHEMA_FILES)
        self.assertIn(
            "scripts/validation/canonicalise-bitbake-layer-output.py",
            MODULE.CAPTURE_SCHEMA_FILES,
        )

    def test_marker_is_not_part_of_evidence_digest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "state.txt").write_text("stable\n", encoding="utf-8")
            before = MODULE.evidence_digest(root)
            (root / MODULE.MARKER).write_text("{}\n", encoding="utf-8")
            self.assertEqual(before, MODULE.evidence_digest(root))


if __name__ == "__main__":
    unittest.main()
