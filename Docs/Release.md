# Release

AppVitals follows semantic versioning.

## Versioning

- MAJOR: breaking public API or minimum platform changes
- MINOR: additive APIs, new modules, new console features
- PATCH: bug fixes, performance improvements, docs, internal refactors

## Release Checklist

1. Update README and docs for API changes.
2. Run `swift test`.
3. Run SwiftFormat and SwiftLint locally when installed.
4. Tag the release:

```bash
git tag 0.1.0
git push origin 0.1.0
```

5. Create GitHub release notes with migration guidance when needed.
