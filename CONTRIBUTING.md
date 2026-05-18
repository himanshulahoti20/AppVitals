# Contributing

Thanks for helping make AppVitals sharper.

## Local Setup

```bash
swift test
```

Optional tools:

```bash
brew install swiftlint swiftformat
```

## Pull Requests

- Keep changes focused.
- Add Swift Testing coverage for behavior changes.
- Prefer small public APIs with clear names.
- Preserve production safety defaults.
- Avoid heavy dependencies.

## Architecture Principles

- Swift-native first
- actor-backed shared state
- bounded memory
- redaction by default
- SwiftUI-first UI
- modular targets with clear dependency direction
