# Universal AI Agent Guidelines (AGENTS.md)

### TL;DR
All AI coding agents (Copilot, Cursor, Claude, Antigravity, etc.) working on Sotto-iOS must follow the architectural guardrails in [CONTRIBUTING.md](CONTRIBUTING.md), preserve 1:1 feature parity with Sotto Android, and execute mandatory project generation and build verification.

---

## 1. Context & Architecture

Before making changes, familiarize yourself with [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/CROSS_PLATFORM_WORKFLOW.md](docs/CROSS_PLATFORM_WORKFLOW.md):
- **Domain**: Assistive Augmentative and Alternative Communication (AAC) for autistic teens & adults, speech-impaired individuals, and non-speaking users.
- **UI Policy**: Low-stimulus, dignified, 100% SwiftUI. Never use legacy Storyboards or UIKit xibs.
- **Data Flow**: Unidirectional state management (`ObservableObject`, `@Published`, state flows down, events flow up).
- **Audio & Speech**: Native `AVFoundation` and `Speech` framework with zero third-party dependencies.
- **Project Structure**: Driven by `project.yml`. Always run `xcodegen generate` after adding, removing, or modifying files.

---

## 2. Flight Rules for AI Agents

1. **Cross-Platform Alignment**:
   - Sotto features are led by Android (`../Sotto`) and ported to iOS with 1:1 feature parity.
   - When modifying features, verify how Android implements it in `../Sotto` to maintain consistency across platforms.
2. **Plan Before Multi-File Changes**:
   - For non-trivial modifications across multiple files, outline an implementation plan or design summary before modifying code.
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
6. **Pre-Release Device Verification Prompt (MANDATORY)**:
   - When assisting with any release, version bump, or release preparation, AI agents **MUST ALWAYS explicitly ask and remind the user to install and test the Release build on a physical device or simulator** before creating the git tag or pushing the release. Never tag or finalize a release without prompting the user.
7. **Autonomous Asset Rebuilding**:
   - When requested to update or rebuild demo assets, execute `./scripts/record_demo_en.sh` and `./scripts/record_demo_id.sh` directly without requiring multi-step approval.
8. **Issue Assignment on Close**:
   - When resolving, updating, or closing a GitHub issue or ticket, if the issue is unassigned, assign it to yourself (`gh issue edit <id> --add-assignee "@me"`) before or upon closing.
9. **Simplicity, Brevity, Safety & Security (Zero Regressions)**:
   - **Ensure Nothing Breaks**: Guarantee backwards compatibility for existing user data (saved phrases, preferences, custom trees) and verify test coverage.
   - **Simpler Code & Shorter Lines of Code**: Emphasize minimal abstractions, direct logic, concise Swift idioms, and eliminating dead code over premature architecture.
   - **Secure Code**: Maintain 100% offline privacy guarantees (zero covert analytics/leaks), sanitize imports, and adhere to secure iOS development standards.
10. **Telemetry for New Features**:
    - Every newly added user-facing feature or configurable capability MUST include corresponding privacy-preserving, opt-in telemetry via `UsabilityTracker` (e.g., activation marker, anonymous usage count, or state snapshot). Telemetry must strictly remain anonymous, zero PII/content, and gated behind user consent (`shareUsabilityMetrics`).
