#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "canonicalise-bitbake-layer-output.py"
SPEC = importlib.util.spec_from_file_location("canonicalise_output", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class CanonicaliseOutputTests(unittest.TestCase):
    def test_recipe_values_keep_their_recipe_identity(self) -> None:
        self.assertEqual(
            MODULE.canonicalise_blocks(
                ["foo:", "  layer-a 1.0", "bar:", "  layer-b 2.0"]
            ),
            [
                "entry\tbar",
                "entry\tfoo",
                "value\tbar\tlayer-b 2.0",
                "value\tfoo\tlayer-a 1.0",
            ],
        )

    def test_parse_counts_are_removed_and_feature_sets_are_sorted(self) -> None:
        self.assertEqual(
            MODULE.canonicalise_blocks(
                [
                    "Parsing of 10 .bb files complete (0 cached)",
                    "foo:",
                    "  layer 1.0 (skipped: missing required distro features 'x11 opengl')",
                ]
            ),
            [
                "entry\tfoo",
                "value\tfoo\tlayer 1.0 (skipped: missing required distro features 'opengl x11')",
            ],
        )

    def test_layer_spacing_is_not_evidence(self) -> None:
        self.assertEqual(
            MODULE.canonicalise_layers(
                ["layer path priority", "meta-dd   build/..          11"]
            ),
            ["layer\tmeta-dd\tbuild/..\t11"],
        )


if __name__ == "__main__":
    unittest.main()
