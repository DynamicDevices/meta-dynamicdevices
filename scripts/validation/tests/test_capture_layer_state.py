#!/usr/bin/env python3
"""Static regressions for the layer-state capture shell boundary."""

from pathlib import Path
import unittest


SCRIPT = Path(__file__).parents[1] / "capture-layer-state.sh"


class CaptureLayerStateTests(unittest.TestCase):
    def test_shell_does_not_expand_sed_end_anchor_as_argument_count(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertNotIn('s#[[:space:]]+$##"', source)
        self.assertEqual(source.count("-e 's#[[:space:]]+$##'"), 3)


if __name__ == "__main__":
    unittest.main()
