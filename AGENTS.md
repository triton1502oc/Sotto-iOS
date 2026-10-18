# Universal AI Agent Guidelines (AGENTS.md)

### TL;DR
All AI coding agents (Copilot, Cursor, Claude, Antigravity, etc.) working on Sotto-iOS must follow the architectural guardrails in [CONTRIBUTING.md](CONTRIBUTING.md), preserve 1:1 feature parity with Sotto Android, and execute mandatory project generation (`xcodegen generate`) and build verification (`swiftc $(find Sotto -name "*.swift") -parse`).

---

## 1. Context & Architecture

Refer to [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/CROSS_PLATFORM_WORKFLOW.md](docs/CROSS_PLATFORM_WORKFLOW.md) for:
- **Mission & Philosophy**: [CONTRIBUTING.md#1-mission--design-philosophy](CONTRIBUTING.md#1-mission--design-philosophy) (dignified, low-stimulus AAC with 1:1 Android parity).
- **Technical Guardrails**: [CONTRIBUTING.md#2-technical-guardrails](CONTRIBUTING.md#2-technical-guardrails) (100% Swift/SwiftUI, UDF/`ObservableObject`, native `AVFoundation`/`Speech`, `project.yml` via `xcodegen generate`).

---

## 2. Flight Rules for AI Agents

1. **Cross-Platform Alignment**:
   - Sotto features are led by Android (`../Sotto`) and ported to iOS with 1:1 feature parity.
   - When modifying features, verify how Android implements it in `../Sotto` to maintain consistency across platforms.
2. **Plan Before Multi-File Changes**:
   - Outline an implementation plan or design summary before modifying code across multiple files.
3. **Build & Project Verification**:
   - After adding, renaming, or removing files, always regenerate the Xcode project:
     ```bash
     xcodegen generate
     ```
   - Verify Swift syntax and ensure unit tests pass:
     ```bash
     swiftc $(find Sotto -name "*.swift") -parse
     ```
4. **Keep Diff Minimal & Focused**:
   - Do not refactor unrelated code or alter established dark-neutral / low-stimulus styling unless explicitly requested.
5. **Environment & Secrets**:
   - Never commit signing keys, personal Apple Developer accounts, personal team IDs, or personal machine paths.
   - Use relative paths (`../Sotto`) instead of absolute user paths.
6. **Release Workflow, Issue Assignment & Mandatory Device Prompt**:
   - Follow the release workflow and issue assignment rules in [CONTRIBUTING.md#4-release-process--guides](CONTRIBUTING.md#4-release-process--guides). **MANDATORY**: When assisting with any release, version bump, or release preparation, AI agents **must run `python3 scripts/sync_release_docs.py --check`** and **must explicitly ask and remind the user to install and test the Release build on a physical device or simulator** before creating the git tag or pushing the release.
7. **Autonomous Asset Rebuilding**:
   - When requested to update or rebuild demo assets, execute `./scripts/record_demo_en.sh` and `./scripts/record_demo_id.sh` directly without requiring multi-step approval.
8. **Code Standards, Backwards Compatibility & Telemetry**:
   - Follow [CONTRIBUTING.md#2-technical-guardrails](CONTRIBUTING.md#2-technical-guardrails) to enforce minimal Swift idioms, 100% phrase backwards compatibility, offline security, and mandatory opt-in `UsabilityTracker` telemetry for every new user-facing feature or preference.
9. **Documentation Governance (Zero Slop & Grounded Truth)**:
   - **Grounded & Verifiable**: Base documentation strictly on verified code, tests, and actual behaviors. Never extrapolate or assume unbuilt features, flags, or parameters.
   - **Surgical Diffs**: Only edit sections directly affected by code changes. Never rewrite whole documents or alter established structure and human tone.
   - **High Signal, Low Stimulus**: Strip introductory filler, conversational throat-clearing, and boilerplate. Always lead with a concise `TL;DR` or direct imperative steps.
   - **Co-Location**: Always update relevant documentation in the same commit or PR as the corresponding feature or bugfix to prevent documentation drift. Run `python3 scripts/sync_release_docs.py --check` when updating features, versions, or preparing releases.
10. **Instruction Hierarchy & Zero Duplication**:
    - **`CONTRIBUTING.md`**: Owns all architecture, code/telemetry standards, and the release workflow.
    - **`AGENTS.md`**: Owns universal AI behavior (planning, surgical diffs, build verification, grounded docs, pre-release user prompts). Never duplicate `CONTRIBUTING.md` checklists here—link to them.
    - **Local Agent Config (`GEMINI.md`)**: Never commit agent-specific tool mechanics (e.g., subagent spawning, watchdogs, artifact filenames) or local machine paths/credentials into `AGENTS.md` or `CONTRIBUTING.md`.
