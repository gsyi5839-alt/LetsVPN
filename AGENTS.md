# Repository Guidelines

## Project Structure & Module Organization
This repository is a multi-platform Flutter app. Main code lives in `lib/`, with a feature-first layout under `lib/features/<feature>/{data,notifier,model,widget}`. Shared infrastructure is in `lib/core/` (routing, DB, theme, utilities). Native core integration is in `lib/hiddifycore/`, and generated outputs are in `lib/gen/` (do not edit manually).  
Platform folders are `android/`, `ios/`, `linux/`, `macos/`, `windows/`, and `web/`. Static resources are under `assets/` (`images/`, `fonts/`, `translations/`). Tests are in `test/` with mirrored domains (`test/core`, `test/features`, `test/drift`).

## Build, Test, and Development Commands
- `make get`: install Dart/Flutter dependencies (`flutter pub get`).
- `make gen`: regenerate code (`build_runner` outputs like `*.g.dart`).
- `make translate`: regenerate i18n code from `assets/translations`.
- `make common-prepare`: run `get + gen + translate`.
- `make <platform>-prepare`: fetch platform core libs and prepare build (example: `make windows-prepare`, `make linux-amd64-prepare`).
- `flutter run --device-id=<id>`: run locally on a target device.
- `flutter test`: run the test suite (CI baseline).
- `make <platform>-release`: build release artifacts (example: `make windows-release`, `make linux-release`, `make android-release`).

## Coding Style & Naming Conventions
Follow `analysis_options.yaml` (`package:lint/strict.yaml`) and keep formatting consistent with a 120-column width. Use Dart defaults:
- file names: `snake_case.dart`
- types/classes/enums: `PascalCase`
- methods/variables: `camelCase`
Never hand-edit generated files such as `*.g.dart`, `*.freezed.dart`, or files in `lib/gen/`.

## Testing Guidelines
Use Flutter tests with `_test.dart` suffix and keep test paths aligned with source areas (for example, `lib/features/profile/...` -> `test/features/profile/...`). Add regression tests for bug fixes and DB migration tests when schema changes. Run `flutter test` before opening a PR. Current CI runs `make linux-amd64-prepare` then `flutter test`; no fixed coverage threshold is enforced.

## Commit & Pull Request Guidelines
Recent history uses concise prefixes such as `fix:`, `new:`, `release:`, and `chore:`. Keep commits focused and descriptive (one logical change per commit). For complex changes, discuss via GitHub Issue first (as noted in `CONTRIBUTING.md`).  
PRs should include: change summary, motivation, linked issue, platforms tested, and screenshots/video for UI-visible changes. Do not include secrets, signing keys, or build artifacts in commits.
