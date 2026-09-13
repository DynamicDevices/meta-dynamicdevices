#!/usr/bin/env python3
"""Fail closed if the Waydroid SELinux development escape hatch broadens."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
APPEND = ROOT / "dynamic-layers/selinux/recipes-security/refpolicy/refpolicy-targeted_%.bbappend"
POLICY = ROOT / "dynamic-layers/selinux/recipes-security/refpolicy/refpolicy-targeted/waydroid.te"
DEVELOPMENT_KAS = ROOT / "kas/r26-jaguar-screen-selinux.yml"
ENFORCING_KAS = ROOT / "kas/r26-jaguar-screen-selinux-enforcing-smoke.yml"
FACTORY_IMAGE = ROOT / "meta-dynamicdevices-distro/recipes-samples/images/lmp-factory-image.bb"


class WaydroidSelinuxPolicyTest(unittest.TestCase):
    def test_tracked_policy_is_not_permissive(self) -> None:
        self.assertNotIn("permissive waydroid_t;", POLICY.read_text(encoding="utf-8"))

    def test_permissive_mode_defaults_off_and_is_development_gated(self) -> None:
        text = APPEND.read_text(encoding="utf-8")
        self.assertIn('WAYDROID_SELINUX_DEVELOPMENT_PERMISSIVE ?= "0"', text)
        self.assertIn('WAYDROID_SELINUX_POLICY_DISCOVERY ?= "0"', text)
        self.assertIn("d.getVar('WAYDROID_SELINUX_POLICY_DISCOVERY') != '1'", text)
        self.assertIn("bb.fatal(", text)

    def test_discovery_stack_opts_in_explicitly(self) -> None:
        text = DEVELOPMENT_KAS.read_text(encoding="utf-8")
        self.assertIn('LOCAL_DEVELOPMENT_BUILD = "1"', text)
        self.assertIn('WAYDROID_SELINUX_DEVELOPMENT_PERMISSIVE = "1"', text)
        self.assertIn('WAYDROID_SELINUX_POLICY_DISCOVERY = "1"', text)

    def test_enforcing_smoke_stack_opts_out_explicitly(self) -> None:
        text = ENFORCING_KAS.read_text(encoding="utf-8")
        self.assertIn('WAYDROID_SELINUX_DEVELOPMENT_PERMISSIVE = "0"', text)

    def test_cra_runtime_is_scoped_to_selinux_screen_image(self) -> None:
        text = FACTORY_IMAGE.read_text(encoding="utf-8")
        self.assertIn("d.getVar('MACHINE') == 'imx8mm-jaguar-screen'", text)
        self.assertIn("bb.utils.contains('DISTRO_FEATURES', 'selinux'", text)
        self.assertIn("'lmp-feature-audit.inc'", text)


if __name__ == "__main__":
    unittest.main()
