#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "compare-layer-state.py"
SPEC = importlib.util.spec_from_file_location("compare_layer_state", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class DeployComparisonTests(unittest.TestCase):
    def test_layout_change_is_a_delta(self) -> None:
        self.assertEqual(
            MODULE.deploy_deltas(["old.wic\t10000"], ["new.wic\t10000"]),
            ["removed old.wic", "added new.wic"],
        )

    def test_small_rebuild_size_noise_is_accepted(self) -> None:
        self.assertEqual(
            MODULE.deploy_deltas(["image.wic\t100000000"], ["image.wic\t100300000"]),
            [],
        )

    def test_material_size_change_is_a_delta(self) -> None:
        self.assertEqual(
            MODULE.deploy_deltas(["image.wic\t100000000"], ["image.wic\t101000000"]),
            ["size image.wic: 100000000 -> 101000000 (tolerance 500000)"],
        )

    def test_malformed_or_duplicate_entries_fail_closed(self) -> None:
        with self.assertRaises(ValueError):
            MODULE.deploy_entries(["missing-size"])
        with self.assertRaises(ValueError):
            MODULE.deploy_entries(["image.wic\t1", "image.wic\t2"])


if __name__ == "__main__":
    unittest.main()
