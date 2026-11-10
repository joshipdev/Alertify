# Contributing to Alertify

Thanks for helping improve Alertify. Contributions are welcome across the Flutter app, Firebase integration, ESP32 firmware, documentation, and development tooling.

## Before you start

- Check existing issues and pull requests to avoid duplicate work.
- For a large change or a change to data paths, Firebase rules, or hardware behavior, open an issue first to agree on the approach.
- Keep changes focused. Explain any security, privacy, hardware, or compatibility impact.
- Never commit credentials, private keys, service-account files, real user data, or local configuration. Use the supplied example configuration files.

## Development setup

1. Follow the setup instructions in [README.md](./README.md).
2. Install Flutter dependencies:

   ```sh
   flutter pub get
   ```

3. Configure your own Firebase project and local ESP32 settings. Do not use production credentials or data for development.

## Validate changes

For Flutter app or Dart changes, run:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

For Android release-impacting changes, also verify:

```sh
flutter build apk --release
```

For Firebase changes, review the rules and test them in the Firebase Rules simulator using a development project. Document any database-path or access-control changes.

For firmware changes, compile and test with the intended ESP32 board and library versions where possible. Document hardware assumptions, pin changes, and safe test conditions. Never test smoke or gas thresholds as a substitute for certified life-safety equipment.

If you cannot run a check, note that and explain why in your pull request.

## Pull requests

- Use a clear, descriptive title and explain the problem and solution.
- Link related issues.
- Include screenshots or short recordings for user-facing changes when useful; remove private or identifying information.
- Describe the affected layers (app, Firebase, firmware, docs, or tooling) and any setup or migration steps.
- List the checks you ran and any checks you could not run.
- Keep unrelated formatting or refactoring out of the change.

By submitting a contribution, you agree that it may be distributed under the repository's applicable licensing terms. If no license is present, ask the maintainers before contributing material that requires a particular license.
