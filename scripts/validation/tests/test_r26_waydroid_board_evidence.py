import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "scripts/validation/capture-r26-waydroid-board-evidence.sh"


class BoardEvidenceCollectorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SCRIPT.read_text(encoding="utf-8")

    def test_release_mode_checks_domain_and_avcs(self):
        self.assertIn("semanage permissive -l", self.source)
        self.assertIn("waydroid-enforcing FAIL", self.source)
        self.assertIn("unexplained-avc FAIL", self.source)

    def test_acceptance_surfaces_are_captured(self):
        for evidence in (
            "binder-service-list",
            "surfaceflinger-running",
            "kiosk-services",
            "waydroid-network",
            "zram-active",
            "etnaviv-active",
            "v4l2-h264-decode",
            "ota-state",
            "secure-boot",
            "image-hashes",
        ):
            self.assertIn(evidence, self.source)

    def test_h264_is_exercised_not_inferred(self):
        self.assertIn("gst-launch-1.0", self.source)
        self.assertIn("h264parse", self.source)
        self.assertIn("fakesink", self.source)
        self.assertIn("NOT_RUN", self.source)

    def test_collector_does_not_update_or_reboot(self):
        for forbidden in ("fioctl update", "aktualizr-lite update", "reboot", "shutdown"):
            self.assertNotIn(forbidden, self.source)


if __name__ == "__main__":
    unittest.main()
