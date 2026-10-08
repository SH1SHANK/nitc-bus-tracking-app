# Release checklist

- [ ] Version in `pubspec.yaml` updated as `MAJOR.MINOR.PATCH+BUILD`.
- [ ] `CHANGELOG.md` updated and release notes prepared.
- [ ] Configuration values verified for the intended environment.
- [ ] `fvm dart format --set-exit-if-changed .` passes.
- [ ] `fvm flutter analyze` passes.
- [ ] `fvm flutter test` passes.
- [ ] Web release build passes and route fallback is verified.
- [ ] Android signed AAB builds from protected signing credentials.
- [ ] Database migrations reviewed and applied through the approved Supabase process.
- [ ] Version tag created, for example `v1.0.0`.
- [ ] GitHub Release created with notes and the AAB artifact.
- [ ] Android release submitted to Play Console.
- [ ] Web deployment verified on `/`, `/map`, and `/profile`.

The repository currently prepares Web and Android artifacts but does not automatically deploy to a hosting provider or Play Console.
