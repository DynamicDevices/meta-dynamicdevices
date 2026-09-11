import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[3]
FIO_API = REPOSITORY / "scripts" / "fio-api.sh"


class FioApiRunSelectionTests(unittest.TestCase):
    def test_defaults_to_primary_non_mfgtools_run(self):
        with tempfile.TemporaryDirectory() as home:
            config = Path(home) / ".config" / "fioctl.yaml"
            config.parent.mkdir(parents=True)
            config.write_text("access_token fixture bearer test-token\n", encoding="utf-8")

            command = textwrap.dedent(
                f"""
                set -e
                source {FIO_API!s}
                api_call() {{
                    case "$1" in
                        */builds/42/)
                            printf '%s\\n' '{{"data":{{"build":{{"runs":[{{"name":"imx95-frdm-evk-mfgtools"}},{{"name":"imx95-frdm-evk"}}]}}}}}}'
                            ;;
                        */runs/imx95-frdm-evk/console.log)
                            printf '%s\\n' 'main-run TMPDIR warning'
                            ;;
                        *)
                            return 1
                            ;;
                    esac
                }}
                test "$(primary_build_run 42)" = imx95-frdm-evk
                builds_command logs 42 | grep -F 'Build 42 logs (imx95-frdm-evk'
                builds_command search 42 TMPDIR | grep -F 'main-run TMPDIR warning'
                """
            )
            environment = os.environ.copy()
            environment["HOME"] = home
            subprocess.run(["bash", "-c", command], check=True, env=environment)


if __name__ == "__main__":
    unittest.main()
