# Repository Guidelines

## Project Structure & Module Organization

This repository contains the Flutter mobile frontend for Palcomtech Chicken Box. Application code lives in `lib/`: `main.dart` starts the app, `pages/` contains screens, `widgets/` reusable UI, `providers/` app state, `services/` API/auth logic, `core/network/` Dio and token handling, `models/` API objects, `routes/` navigation, and `constants/` shared config. Tests live in `test/`. Static images are in `assets/images/` and declared in `pubspec.yaml`. Platform projects are under `android/`, `ios/`, `web/`, `windows/`, `linux/`, and `macos/`. Project references are in `docs/`.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter run`: launch the app on the selected emulator, device, or web target.
- `flutter analyze`: run static analysis using `flutter_lints`.
- `flutter test`: run widget and unit tests in `test/`.
- `flutter build apk --release`: create an Android release APK.
- `dart format lib test`: format Dart sources before submitting changes.

Keep `.env` present for local runs because it is listed as a Flutter asset. Do not commit new secrets.

## Coding Style & Naming Conventions

Follow Dart defaults: two-space indentation, trailing commas for readable multi-line widget trees, `PascalCase` for classes/widgets, `camelCase` for members, and `snake_case.dart` file names. Prefer small widgets and services over large page files. Keep network access through `core/network/` and `services/` so auth interception and error handling stay centralized.

## Testing Guidelines

Use `flutter_test` for widget tests and place new tests under `test/` with names ending in `_test.dart`, such as `device_provider_test.dart` or `login_page_test.dart`. Run `flutter test` and `flutter analyze` before opening a pull request. Add tests for provider state changes, route-level UI behavior, and API error handling.

## Commit & Pull Request Guidelines

Recent history uses conventional-style commits such as `feat: Add quick reference guides`. Continue with short imperative subjects prefixed by `feat:`, `fix:`, `docs:`, `refactor:`, or `test:`. Pull requests should include a summary, linked issue or task when available, testing results, and screenshots or screen recordings for UI changes. Note any `.env`, Firebase, permission, or platform setup needed to verify the change.

## Agent-Specific Instructions

Keep generated changes scoped to the requested feature. Do not edit platform folders unless the change requires native configuration. Prefer existing project patterns before introducing new packages or architecture.
