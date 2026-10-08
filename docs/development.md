# Development guide

## Prerequisites

- Flutter `3.47.5` and Dart `3.13.4`, pinned in `.fvmrc`
- FVM
- Java 17 for Android builds
- Chrome for Web development

Use FVM so local commands and CI use the same SDK:

```bash
fvm install
fvm flutter pub get
```

## Environment configuration

Choose one logical environment and copy its template. The resulting file is local-only and ignored by Git:

```bash
cp config/dev.example.json config/dev.json
```

Edit `config/dev.json` with client-safe development values. Never put Supabase service-role keys, OneSignal REST keys, Mapbox secret tokens, signing credentials, or service-account JSON in this file. Use the staging and production templates only with their corresponding protected environments.

Run with:

```bash
fvm flutter run -d chrome --dart-define-from-file=config/dev.json
fvm flutter run --dart-define-from-file=config/dev.json
```

## Quality and tests

```bash
fvm dart format .
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm dart run tool/verify_architecture.dart
fvm flutter test
```

The integration smoke test is separate from the normal fast PR suite:

```bash
fvm flutter test integration_test/smoke_test.dart
```

## Builds

```bash
fvm flutter build web --release
fvm flutter build apk --debug
fvm flutter build appbundle --release
```

The local release App Bundle uses the debug key unless `android/key.properties` and its keystore are supplied. Never commit either file. CI requires the protected Android signing secrets before building a release artifact.

Flutter Web uses path URLs for `/`, `/map`, and `/profile`. The production host must serve `index.html` as the fallback for those routes; the repository currently has no selected hosting provider or provider-specific rewrite file.

## Git and pull requests

Use short-lived branches such as `feature/*`, `fix/*`, `chore/*`, `docs/*`, or `refactor/*`. Open a pull request into `main`; do not normally push directly to `main`. CI runs formatting, analysis, architecture verification, tests, and Web/Android debug builds. Dependabot opens dependency-update PRs but does not merge them automatically.

Keep `pubspec.lock` committed. Avoid dependency overrides and Git dependencies unless there is a documented reason.

## Supabase migrations

Create a new timestamped SQL file under `supabase/migrations/` for every schema change. Review it, test it against a development project, and include it in the pull request. Do not manually edit production tables or add production credentials to the repository.

## Logging and future observability

`AppLogger` is the central logging boundary. Flutter framework errors and uncaught asynchronous errors are routed there from bootstrap. A production error-reporting provider can attach at that boundary later without spreading SDK calls across features.
