## Description

<!-- Provide a brief summary of the changes introduced in this PR. -->

Fixes #(issue)

---

## Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 🎨 UI/UX refinement (accessibility, contrast, touch targets)
- [ ] 📝 Documentation update
- [ ] ⚙️ CI / Build / Dependencies

---

## Sotto Design & Philosophy Checklist

- [ ] **Dignified & Mature UI**: Free of pediatric clutter, cartoon icons, or childish styling.
- [ ] **Low-Stimulation**: Preserves dark-neutral palette, calm transitions, and high contrast.
- [ ] **Zero-Distraction Mode**: Administrative actions (add, edit, delete, reorder) remain hidden during communication.
- [ ] **100% Offline & Private**: Zero analytics, telemetry, remote network calls, or cloud sync.
- [ ] **Lifecycle Safety**: Audio sessions and speech synthesizers cleanly handle system interruptions.

---

## Verification & Testing

### Automated Checks
- [ ] `xcodegen generate` succeeds.
- [ ] `swiftc $(find Sotto -name "*.swift") -parse` passes with zero errors.
- [ ] `xcodebuild build-for-testing` passes all unit tests.

### Device Verification
- [ ] Verified on physical iOS device or simulator.
- [ ] Tested landscape / portrait orientation and Dynamic Type / responsive layout.

---

## Visuals (if applicable)

<!-- Attach screenshots or short recordings demonstrating UI changes or bug fixes. -->
