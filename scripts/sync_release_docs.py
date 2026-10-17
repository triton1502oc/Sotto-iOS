#!/usr/bin/env python3
"""
scripts/sync_release_docs.py

Automated release documentation synchronization and linting for Sotto iOS.
Verifies version parity, deployment targets, Swift file structure completeness in README.md,
and guards against prohibited clinical terms or stale UI references.
"""

from __future__ import annotations

import sys
import os
import re
import plistlib
import argparse
from typing import Optional
from pathlib import Path

# ANSI colors for high-signal CLI output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"

PROHIBITED_TERMS = [
    (r"diagnostic tree", "Clinical term 'diagnostic tree' prohibited; use 'root-cause discovery tree'"),
    (r"root-cause triage", "Clinical term 'root-cause triage' prohibited; use 'root-cause discovery'"),
    (r"Primary Category:\s*`?Medical`?", "Primary Category 'Medical' prohibited; use 'Accessibility' or 'Utilities'"),
    (r"Tap\s+['\"]?🛡️['\"]?\s+in\s+(?:the\s+)?top\s+bar", "Stale UI reference: Safety Card is anchored on the phrase board, not top bar"),
    (r"top\s+bar\s+QR\s+icon", "Stale UI reference: QR Scanner is in Settings > Data & Backup, not top bar"),
]

def get_repo_root() -> Path:
    return Path(__file__).resolve().parent.parent

def load_plist(plist_path: Path) -> dict:
    with open(plist_path, "rb") as f:
        return plistlib.load(f)

def save_plist(plist_path: Path, data: dict):
    with open(plist_path, "wb") as f:
        plistlib.dump(data, f)

def check_docs(repo_root: Path) -> bool:
    all_passed = True
    print(f"\n{BOLD}{CYAN}=== Sotto iOS Release Documentation & Integrity Audit ==={RESET}\n")

    plist_path = repo_root / "Sotto/Resources/Info.plist"
    if not plist_path.exists():
        print(f"{RED}[FAIL] Missing Info.plist at {plist_path}{RESET}")
        return False

    plist_data = load_plist(plist_path)
    version = plist_data.get("CFBundleShortVersionString", "")
    build_num = plist_data.get("CFBundleVersion", "")

    print(f"Current Info.plist Version: {BOLD}{version}{RESET} (Build {BOLD}{build_num}{RESET})")

    if not version:
        print(f"{RED}[FAIL] CFBundleShortVersionString is empty in Info.plist{RESET}")
        return False

    version_parts = version.split(".")
    if len(version_parts) < 2:
        print(f"{RED}[FAIL] Invalid semver version: {version}{RESET}")
        return False
    major_minor_branch = f"v{version_parts[0]}.{version_parts[1]}.x"

    # 1. Check SECURITY.md
    sec_path = repo_root / "SECURITY.md"
    if sec_path.exists():
        sec_content = sec_path.read_text(encoding="utf-8")
        if f"`{major_minor_branch}`" in sec_content and "Current active release branch" in sec_content:
            print(f"{GREEN}[OK]{RESET} SECURITY.md active branch matches {major_minor_branch}")
        else:
            print(f"{RED}[FAIL]{RESET} SECURITY.md missing active branch entry for `{major_minor_branch}`")
            all_passed = False
    else:
        print(f"{RED}[FAIL]{RESET} Missing SECURITY.md")
        all_passed = False

    # 2. Check bug_report.md
    bug_path = repo_root / ".github/ISSUE_TEMPLATE/bug_report.md"
    if bug_path.exists():
        bug_content = bug_path.read_text(encoding="utf-8")
        expected_bug_ver = f"- Sotto Version: [e.g. v{version}]"
        if expected_bug_ver in bug_content:
            print(f"{GREEN}[OK]{RESET} bug_report.md example version matches v{version}")
        else:
            print(f"{RED}[FAIL]{RESET} bug_report.md does not match '{expected_bug_ver}'")
            all_passed = False
    else:
        print(f"{RED}[FAIL]{RESET} Missing .github/ISSUE_TEMPLATE/bug_report.md")
        all_passed = False

    # 3. Check docs/APP_STORE_SUBMISSION_CHECKLIST.md
    checklist_path = repo_root / "docs/APP_STORE_SUBMISSION_CHECKLIST.md"
    if checklist_path.exists():
        check_content = checklist_path.read_text(encoding="utf-8")
        expected_checklist_ver = f"{version} Prepare for Submission"
        if expected_checklist_ver in check_content:
            print(f"{GREEN}[OK]{RESET} APP_STORE_SUBMISSION_CHECKLIST.md target matches '{expected_checklist_ver}'")
        else:
            print(f"{RED}[FAIL]{RESET} APP_STORE_SUBMISSION_CHECKLIST.md missing '{expected_checklist_ver}'")
            all_passed = False
    else:
        print(f"{RED}[FAIL]{RESET} Missing docs/APP_STORE_SUBMISSION_CHECKLIST.md")
        all_passed = False

    # 4. Check CHANGELOG.md
    changelog_path = repo_root / "CHANGELOG.md"
    if changelog_path.exists():
        changelog_content = changelog_path.read_text(encoding="utf-8")
        if f"## [v{version}]" in changelog_content:
            print(f"{GREEN}[OK]{RESET} CHANGELOG.md has entry for ## [v{version}]")
        elif f"## [{version}]" in changelog_content:
            print(f"{GREEN}[OK]{RESET} CHANGELOG.md has entry for ## [{version}]")
        else:
            print(f"{RED}[FAIL]{RESET} CHANGELOG.md missing release section for version v{version}")
            all_passed = False
    else:
        print(f"{RED}[FAIL]{RESET} Missing CHANGELOG.md")
        all_passed = False

    # 5. Check Deployment Target parity
    proj_path = repo_root / "project.yml"
    target_deployment = "16.0"
    if proj_path.exists():
        proj_content = proj_path.read_text(encoding="utf-8")
        m = re.search(r'deploymentTarget:\s*(?:\n\s*iOS:\s*"([^"]+)"|"([^"]+)")', proj_content)
        if m:
            target_deployment = m.group(1) or m.group(2)
        print(f"Deployment Target in project.yml: {BOLD}iOS {target_deployment}{RESET}")

    doc_targets = [
        ("ANTIGRAVITY.md", repo_root / "ANTIGRAVITY.md", rf"iOS {re.escape(target_deployment)}\+"),
        ("README.md", repo_root / "README.md", rf"iOS {re.escape(target_deployment)}\+"),
        ("CONTRIBUTING.md", repo_root / "CONTRIBUTING.md", rf"iOS {re.escape(target_deployment)}\+"),
    ]
    for name, p, pattern in doc_targets:
        if p.exists():
            content = p.read_text(encoding="utf-8")
            if re.search(pattern, content):
                print(f"{GREEN}[OK]{RESET} {name} specifies iOS {target_deployment}+")
            else:
                print(f"{RED}[FAIL]{RESET} {name} does not match deployment target iOS {target_deployment}+")
                all_passed = False
        else:
            print(f"{RED}[FAIL]{RESET} Missing {name}")
            all_passed = False

    # 6. Check that every Swift file under Sotto/ is in README.md
    readme_path = repo_root / "README.md"
    if readme_path.exists():
        readme_content = readme_path.read_text(encoding="utf-8")
        structure_match = re.search(r"## Project Structure\s+```(.*?)```", readme_content, re.DOTALL)
        if structure_match:
            structure_text = structure_match.group(1)
            sotto_dir = repo_root / "Sotto"
            swift_files = sorted([p.name for p in sotto_dir.glob("**/*.swift")])
            missing_in_readme = [sf for sf in swift_files if sf not in structure_text]
            if not missing_in_readme:
                print(f"{GREEN}[OK]{RESET} README.md Project Structure includes all {len(swift_files)} Swift source files")
            else:
                print(f"{RED}[FAIL]{RESET} README.md Project Structure is missing Swift files: {missing_in_readme}")
                all_passed = False
        else:
            print(f"{RED}[FAIL]{RESET} README.md missing ## Project Structure code block")
            all_passed = False

    # 7. Scan for prohibited clinical terms and stale UI references
    user_docs = [
        repo_root / "README.md",
        repo_root / "demo/README.md",
    ]
    docs_dir = repo_root / "docs"
    if docs_dir.exists():
        for p in docs_dir.glob("*.md"):
            user_docs.append(p)

    term_violations = 0
    for doc in user_docs:
        if not doc.exists():
            continue
        content = doc.read_text(encoding="utf-8")
        rel_path = doc.relative_to(repo_root)
        for pattern, explanation in PROHIBITED_TERMS:
            matches = list(re.finditer(pattern, content, re.IGNORECASE))
            if matches:
                for match in matches:
                    line_no = content[:match.start()].count("\n") + 1
                    matched_text = match.group(0)
                    print(f"{RED}[LINT ERROR]{RESET} {rel_path}:{line_no} Found prohibited pattern '{matched_text}': {explanation}")
                    term_violations += 1
                    all_passed = False

    if term_violations == 0:
        print(f"{GREEN}[OK]{RESET} Zero prohibited clinical terms or stale UI references across all markdown docs")

    print("\n" + "=" * 58)
    if all_passed:
        print(f"{GREEN}{BOLD}✓ ALL RELEASE DOCUMENTATION & INTEGRITY CHECKS PASSED{RESET}\n")
    else:
        print(f"{RED}{BOLD}✗ DOCUMENTATION CHECKS FAILED — Review errors above{RESET}\n")

    return all_passed

def bump_version(repo_root: Path, new_version: str, new_build: str | None = None) -> bool:
    print(f"\n{BOLD}{CYAN}=== Bumping Sotto iOS Release Version to {new_version} ==={RESET}\n")

    plist_path = repo_root / "Sotto/Resources/Info.plist"
    plist_data = load_plist(plist_path)

    old_version = plist_data.get("CFBundleShortVersionString", "")
    old_build = plist_data.get("CFBundleVersion", "")

    plist_data["CFBundleShortVersionString"] = new_version
    if new_build:
        plist_data["CFBundleVersion"] = str(new_build)
    save_plist(plist_path, plist_data)
    print(f"{GREEN}[OK]{RESET} Info.plist: {old_version} (Build {old_build}) ➔ {new_version} (Build {plist_data['CFBundleVersion']})")

    # Update SECURITY.md
    sec_path = repo_root / "SECURITY.md"
    if sec_path.exists():
        sec_text = sec_path.read_text(encoding="utf-8")
        parts = new_version.split(".")
        new_active = f"v{parts[0]}.{parts[1]}.x"
        old_parts = old_version.split(".")
        old_active = f"v{old_parts[0]}.{old_parts[1]}.x" if len(old_parts) >= 2 else ""

        if old_active and old_active != new_active:
            # Shift old active to maintenance, new to active
            sec_text = re.sub(
                r'\|\s*`' + re.escape(old_active) + r'`\s*\|\s*:white_check_mark:\s*\|\s*Current active release branch\s*\|',
                f'| `{new_active}` | :white_check_mark: | Current active release branch |\n| `{old_active}` | :white_check_mark: | Maintenance branch |',
                sec_text
            )
            # Remove duplicate old maintenance line if any
            sec_path.write_text(sec_text, encoding="utf-8")
            print(f"{GREEN}[OK]{RESET} SECURITY.md: Promoted {new_active} to active release branch")

    # Update bug_report.md
    bug_path = repo_root / ".github/ISSUE_TEMPLATE/bug_report.md"
    if bug_path.exists():
        bug_text = bug_path.read_text(encoding="utf-8")
        bug_text = re.sub(r"- Sotto Version:\s*\[e\.g\.\s*v[^\]]+\]", f"- Sotto Version: [e.g. v{new_version}]", bug_text)
        bug_path.write_text(bug_text, encoding="utf-8")
        print(f"{GREEN}[OK]{RESET} bug_report.md: Updated example version to v{new_version}")

    # Update APP_STORE_SUBMISSION_CHECKLIST.md
    checklist_path = repo_root / "docs/APP_STORE_SUBMISSION_CHECKLIST.md"
    if checklist_path.exists():
        chk_text = checklist_path.read_text(encoding="utf-8")
        chk_text = re.sub(r"iOS App > [0-9.]+ Prepare for Submission", f"iOS App > {new_version} Prepare for Submission", chk_text)
        checklist_path.write_text(chk_text, encoding="utf-8")
        print(f"{GREEN}[OK]{RESET} APP_STORE_SUBMISSION_CHECKLIST.md: Updated version to {new_version}")

    # Re-run check
    check_docs(repo_root)

    print(f"""
{BOLD}{YELLOW}------------------------------------------------------------
RELEASE CHECKLIST & MANUAL STEPS FOR v{new_version}:
------------------------------------------------------------{RESET}
1. Add section '## [v{new_version}] - YYYY-MM-DD' in CHANGELOG.md.
2. Review 'docs/APP_STORE_LISTING.md' (What's New / Promotional Text).
3. Run project regeneration and syntax test:
   xcodegen generate
   swiftc $(find Sotto -name "*.swift") -parse

{BOLD}{RED}⚠️  PRE-RELEASE DEVICE VERIFICATION (MANDATORY FLIGHT RULE):
Always install and thoroughly test the Release build on a physical
device (e.g. iPad 7th gen) or simulator BEFORE creating a git tag
or pushing the release!
------------------------------------------------------------{RESET}
""")
    return True

def main():
    parser = argparse.ArgumentParser(description="Sotto iOS Release Documentation Sync & Integrity Tool")
    parser.add_argument("--check", action="store_true", help="Run verification checks on release docs (default)")
    parser.add_argument("--bump", type=str, help="Bump version in Info.plist and sync docs (e.g. 1.7.5)")
    parser.add_argument("--build", type=str, help="Optional build number when bumping (e.g. 13)")
    parser.add_argument("--sync", action="store_true", help="Re-sync doc references to current Info.plist version")

    args = parser.parse_args()
    repo_root = get_repo_root()

    if args.bump:
        success = bump_version(repo_root, args.bump, args.build)
        sys.exit(0 if success else 1)
    elif args.sync:
        plist_data = load_plist(repo_root / "Sotto/Resources/Info.plist")
        ver = plist_data.get("CFBundleShortVersionString", "")
        bld = plist_data.get("CFBundleVersion", "")
        success = bump_version(repo_root, ver, bld)
        sys.exit(0 if success else 1)
    else:
        success = check_docs(repo_root)
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
