#!/usr/bin/env python3
"""Run every protected Yocto tuple in one fail-closed regression job."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


MARKER = ".complete.json"
FIELDS = ("id", "machine", "distro", "image", "config", "product_features")
PRODUCT_SUBMODULES = ("meta-dynamicdevices-bsp", "meta-dynamicdevices-distro")
CAPTURE_SCHEMA_FILES = (
    "ci/layer-adoption-contract.json",
    "scripts/validation/run-layer-adoption-regression.py",
    "scripts/validation/capture-layer-state.sh",
    "scripts/validation/canonicalise-bitbake-layer-output.py",
    "scripts/validation/select-bitbake-env.py",
    "scripts/validation/generate-layer-adoption-test-keys.sh",
)


def submodule_commit(repository: Path, relative: str) -> str:
    entry = git_output(repository, "ls-tree", "HEAD", "--", relative).split()
    if len(entry) < 3 or entry[0] != "160000" or entry[1] != "commit":
        raise RuntimeError(f"{repository}: {relative} is not a pinned git submodule")
    return entry[2]


def evidence_digest(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.name == MARKER:
            continue
        relative = path.relative_to(root).as_posix().encode()
        digest.update(relative)
        digest.update(b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


def capture_schema_digest(repository: Path) -> str:
    digest = hashlib.sha256()
    for relative in CAPTURE_SCHEMA_FILES:
        digest.update(relative.encode())
        digest.update(b"\0")
        digest.update(hashlib.sha256((repository / relative).read_bytes()).digest())
    return digest.hexdigest()


def valid_cached_evidence(
    root: Path, base_sha: str, tuple_id: str, capture_schema: str
) -> bool:
    try:
        marker = json.loads((root / MARKER).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    return marker == {
        "base_sha": base_sha,
        "tuple_id": tuple_id,
        "capture_schema": capture_schema,
        "evidence_sha256": evidence_digest(root),
    }


def load_tuples(path: Path) -> list[dict[str, str]]:
    document = json.loads(path.read_text(encoding="utf-8"))
    if document.get("schema") != 1 or not isinstance(document.get("tuples"), list):
        raise ValueError(f"{path}: expected schema=1 and a tuples array")
    tuples = []
    seen = set()
    for index, raw in enumerate(document["tuples"]):
        if not isinstance(raw, dict) or any(field not in raw for field in FIELDS):
            raise ValueError(f"{path}: tuple {index} is incomplete")
        entry = {field: str(raw[field]) for field in FIELDS}
        if not entry["id"] or entry["id"] in seen:
            raise ValueError(f"{path}: duplicate or empty tuple id {entry['id']!r}")
        seen.add(entry["id"])
        tuples.append(entry)
    if not tuples:
        raise ValueError(f"{path}: no protected tuples")
    return tuples


def remove_build_tree(repository: Path) -> None:
    repository = repository.resolve()
    build = (repository / "build").resolve()
    if build.parent != repository or repository == Path("/"):
        raise RuntimeError(f"refusing unsafe build cleanup: {build}")
    shutil.rmtree(build, ignore_errors=True)


def git_output(repository: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=repository, text=True).strip()


def prepare_repository(repository: Path) -> None:
    """Initialize and verify the pinned local layers used by every KAS tuple."""
    for relative in PRODUCT_SUBMODULES:
        expected = submodule_commit(repository, relative)
        layer = repository / relative
        layer_conf = layer / "conf/layer.conf"
        if not layer_conf.is_file():
            subprocess.run(
                [
                    "git",
                    "-c",
                    "url.https://github.com/.insteadOf=git@github.com:",
                    "submodule",
                    "update",
                    "--init",
                    "--recursive",
                    "--",
                    relative,
                ],
                cwd=repository,
                check=True,
            )
        if not layer_conf.is_file():
            raise RuntimeError(f"{repository}: {relative}/conf/layer.conf is missing")
        actual = git_output(layer, "rev-parse", "HEAD")
        if actual != expected:
            raise RuntimeError(
                f"{repository}: {relative} is at {actual}, expected pinned {expected}"
            )
        if git_output(layer, "status", "--porcelain", "--untracked-files=all"):
            raise RuntimeError(f"{repository}: {relative} has uncommitted content")


def apply_baseline_repairs(
    baseline: Path, candidate: Path, contract_path: Path, base_sha: str
) -> None:
    """Apply an exact, audited repair to an otherwise unbuildable baseline."""
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    repairs = contract.get("baseline_repairs", [])
    if not isinstance(repairs, list):
        raise ValueError("baseline_repairs must be an array")
    for repair in repairs:
        if not isinstance(repair, dict):
            raise ValueError("baseline repair must be an object")
        if repair.get("base_sha") != base_sha:
            continue
        required = {"submodule", "from", "to", "url", "ref", "files", "reason"}
        if not required <= repair.keys():
            raise ValueError("baseline repair is incomplete")
        relative = str(repair["submodule"])
        old = str(repair["from"])
        new = str(repair["to"])
        url = str(repair["url"])
        ref = str(repair["ref"])
        files = repair["files"]
        reason = str(repair["reason"]).strip()
        if relative not in PRODUCT_SUBMODULES:
            raise ValueError(f"unsupported baseline repair submodule: {relative}")
        if any(not re.fullmatch(r"[0-9a-f]{40}", commit) for commit in (old, new)):
            raise ValueError("baseline repair pins must be full lowercase commit IDs")
        if not url.startswith("https://github.com/DynamicDevices/"):
            raise ValueError("baseline repair URL must use the DynamicDevices HTTPS origin")
        if not ref.startswith("refs/heads/"):
            raise ValueError("baseline repair ref must be an explicit branch")
        if (
            not reason
            or not isinstance(files, list)
            or not files
            or any(
                not isinstance(path, str)
                or Path(path).is_absolute()
                or ".." in Path(path).parts
                for path in files
            )
        ):
            raise ValueError("baseline repair needs a reason and exact file list")
        if submodule_commit(baseline, relative) != old:
            raise RuntimeError(f"baseline repair {relative}: unexpected source pin")
        if submodule_commit(candidate, relative) != new:
            raise RuntimeError(f"baseline repair {relative}: unexpected candidate pin")

        candidate_layer = candidate / relative
        subprocess.run(
            ["git", "merge-base", "--is-ancestor", old, new],
            cwd=candidate_layer,
            check=True,
        )
        changed = git_output(candidate_layer, "diff", "--name-only", old, new).splitlines()
        if sorted(changed) != sorted(str(path) for path in files):
            raise RuntimeError(
                f"baseline repair {relative}: changed files do not match contract"
            )

        baseline_layer = baseline / relative
        subprocess.run(["git", "fetch", url, ref], cwd=baseline_layer, check=True)
        fetched = git_output(baseline_layer, "rev-parse", "FETCH_HEAD")
        if fetched != new:
            raise RuntimeError(f"baseline repair {relative}: ref resolved to {fetched}")
        subprocess.run(
            ["git", "checkout", "--detach", new], cwd=baseline_layer, check=True
        )
        if git_output(baseline_layer, "status", "--porcelain", "--untracked-files=all"):
            raise RuntimeError(f"baseline repair {relative}: checkout is dirty")
        print(
            f"Applying audited baseline repair for {relative}: {old} -> {new}",
            flush=True,
        )


def capture(
    script: Path,
    repository: Path,
    entry: dict[str, str],
    output: Path,
    environment: dict[str, str],
) -> None:
    subprocess.run(
        [
            str(script),
            entry["config"],
            entry["machine"],
            entry["distro"],
            entry["image"],
            entry["product_features"],
            str(output),
        ],
        cwd=repository,
        env=environment,
        check=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--cache", required=True, type=Path)
    parser.add_argument("--test-keys", required=True, type=Path)
    args = parser.parse_args()

    baseline = args.baseline.resolve()
    candidate = args.candidate.resolve()
    evidence = args.evidence.resolve()
    cache = args.cache.resolve()
    test_keys = args.test_keys.resolve()
    capture_script = candidate / "scripts/validation/capture-layer-state.sh"
    compare_script = candidate / "scripts/validation/compare-layer-state.py"
    contract = candidate / "ci/layer-adoption-contract.json"
    tuples = load_tuples(candidate / "ci/layer-adoption-tuples.json")
    base_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=baseline, text=True
    ).strip()
    capture_schema = capture_schema_digest(candidate)

    # This preparation is intentionally owned by the shared regression driver,
    # not by CI YAML. Local and hosted runs therefore build the same pinned
    # submodule content through the same KAS capture path.
    prepare_repository(baseline)
    prepare_repository(candidate)
    apply_baseline_repairs(baseline, candidate, contract, base_sha)

    environment = os.environ.copy()
    environment["LAYER_ADOPTION_TEST_KEYS_DIR"] = str(test_keys)
    environment["LAYER_ADOPTION_CACHE_DIR"] = str(cache / "yocto")
    shutil.rmtree(evidence, ignore_errors=True)
    (evidence / "baseline").mkdir(parents=True)
    (evidence / "candidate").mkdir(parents=True)

    for entry in tuples:
        tuple_id = entry["id"]
        print(f"::group::Protect {tuple_id}", flush=True)
        cached = cache / "baselines" / base_sha / tuple_id
        baseline_output = evidence / "baseline" / tuple_id
        candidate_output = evidence / "candidate" / tuple_id
        temporary: Path | None = None
        try:
            if valid_cached_evidence(cached, base_sha, tuple_id, capture_schema):
                print(f"Reusing immutable baseline evidence for {base_sha}", flush=True)
            else:
                shutil.rmtree(cached, ignore_errors=True)
                cached.parent.mkdir(parents=True, exist_ok=True)
                temporary = Path(tempfile.mkdtemp(prefix=f".{tuple_id}-", dir=cached.parent))
                capture(capture_script, baseline, entry, temporary, environment)
                marker = {
                    "base_sha": base_sha,
                    "tuple_id": tuple_id,
                    "capture_schema": capture_schema,
                    "evidence_sha256": evidence_digest(temporary),
                }
                (temporary / MARKER).write_text(
                    json.dumps(marker, sort_keys=True) + "\n", encoding="utf-8"
                )
                temporary.rename(cached)
                temporary = None

            shutil.copytree(cached, baseline_output, ignore=shutil.ignore_patterns(MARKER))
            capture(capture_script, candidate, entry, candidate_output, environment)
            subprocess.run(
                [
                    "python3",
                    str(compare_script),
                    "--baseline",
                    str(baseline_output),
                    "--candidate",
                    str(candidate_output),
                    "--tuple",
                    tuple_id,
                    "--contract",
                    str(contract),
                ],
                check=True,
            )
        finally:
            if temporary is not None:
                shutil.rmtree(temporary, ignore_errors=True)
            remove_build_tree(baseline)
            remove_build_tree(candidate)
            print("::endgroup::", flush=True)

    print(f"PASS: all {len(tuples)} protected Yocto tuples are unchanged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
