#!/usr/bin/env python3
"""Regressions for the layer-state capture shell boundary."""

from pathlib import Path
import re
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "capture-layer-state.sh"


class CaptureLayerStateTests(unittest.TestCase):
    def test_shell_does_not_expand_sed_end_anchor_as_argument_count(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertNotIn('s#[[:space:]]+$##"', source)
        self.assertEqual(source.count("-e 's#[[:space:]]+$##'"), 3)

    def test_capture_command_replays_failure_log_and_preserves_status(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        match = re.search(r"(?ms)^capture_command\(\) \{\n.*?^\}\n", source)
        self.assertIsNotNone(match)

        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [
                    "bash",
                    "-c",
                    match.group(0)
                    + """
set -o pipefail
output_dir=$1
capture_command failure bash -c 'printf "visible diagnostic\\n"; exit 7' \\
    | sed 's/diagnostic/output/'
""",
                    "capture-command-test",
                    directory,
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 7)
            self.assertEqual(result.stdout, "visible output\n")
            self.assertIn("ERROR: command failed while capturing failure", result.stderr)
            self.assertIn("visible diagnostic", result.stderr)
            self.assertEqual(
                (Path(directory) / "failure.log").read_text(encoding="utf-8"),
                "visible diagnostic\n",
            )

    def test_dependency_capture_uses_current_bitbake_graph_outputs(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("build/pn-buildlist", source)
        self.assertIn("build/task-depends.dot", source)
        self.assertNotIn("build/recipe-depends.dot", source)

    def test_environment_assertions_emit_named_diagnostics(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertIn('capture_command environment run_bitbake "bitbake -e $target" >/dev/null', source)
        self.assertIn("require_selected_value() {", source)
        self.assertEqual(source.count("require_selected_value "), 3)
        self.assertIn("ERROR: selected BitBake environment does not contain", source)


if __name__ == "__main__":
    unittest.main()
