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
        self.assertEqual(source.count("-e 's#[[:space:]]+$##'"), 1)
        self.assertEqual(source.count("| normalise_kas_projection"), 3)

    def test_kas_projection_removes_host_noise_and_sorts_at_call_site(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        match = re.search(r"(?ms)^normalise_kas_projection\(\) \{\n.*?^\}\n", source)
        self.assertIsNotNone(match)
        result = subprocess.run(
            [
                "bash",
                "-c",
                match.group(0)
                + """
PWD=/workspace/candidate
printf '%s\n' \\
  '2026-09-12 20:00:00 - INFO     - kas 4.7 started' \\
  '/__w/project/baseline/build/layers/meta/conf/layer.conf  ' \\
  '/workspace/candidate/recipe.bb' | normalise_kas_projection
""",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.stdout,
            "<REPO>/build/layers/meta/conf/layer.conf\n<REPO>/recipe.bb\n",
        )

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
        self.assertEqual(source.count("require_selected_value "), 10)
        self.assertIn("ERROR: selected BitBake environment does not contain", source)

    def test_module_signing_uses_kernel_runtime_variables(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertIn(
            'MODSIGN_PRIVKEY:forcevariable = "$test_keys_dir/privkey_modsign.pem"',
            source,
        )
        self.assertIn(
            'MODSIGN_X509:forcevariable = "$test_keys_dir/x509_modsign.crt"',
            source,
        )
        self.assertIn(
            'require_selected_value MODSIGN_PRIVKEY "<TEST_KEYS>/privkey_modsign.pem"',
            source,
        )
        self.assertIn(
            'require_selected_value MODSIGN_X509 "<TEST_KEYS>/x509_modsign.crt"',
            source,
        )

    def test_every_signing_consumer_path_is_forced_and_asserted(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        runtime_paths = {
            "UBOOT_SIGN_KEYDIR": "<TEST_KEYS>",
            "UBOOT_SPL_SIGN_KEYDIR": "<TEST_KEYS>",
            "UEFI_SIGN_KEYDIR": "<TEST_KEYS>/uefi",
            "OPTEE_TA_SIGN_KEY": "<TEST_KEYS>/ubootdev.key",
            "TF_A_SIGN_KEY_PATH": "<TEST_KEYS>/tf-a/privkey_ec_prime256v1.pem",
        }
        for name, expected in runtime_paths.items():
            with self.subTest(name=name):
                self.assertIn(f"{name}:forcevariable =", source)
                self.assertIn(
                    f'require_selected_value {name} "{expected}"', source
                )
        self.assertNotRegex(
            source,
            r"(?m)^    (?:SIGNING_|MODSIGN_|UBOOT_|UEFI_|OPTEE_|TF_A_)[A-Z0-9_]+ =",
        )

    def test_disk_monitor_uses_inode_not_disk_units(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")
        disk_monitor = next(
            line for line in source.splitlines() if "BB_DISKMON_DIRS =" in line
        )
        self.assertNotIn(",1G", disk_monitor)
        self.assertEqual(disk_monitor.count(",100K"), 3)
        self.assertEqual(disk_monitor.count(",50K"), 3)


if __name__ == "__main__":
    unittest.main()
