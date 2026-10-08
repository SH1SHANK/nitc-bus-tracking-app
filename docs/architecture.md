# Tracklet architecture

Tracklet is a single Flutter application targeting Android and Web. The code is organized into small layers rather than packages:

- `app/` owns bootstrap, routing, and the application shell.
- `core/` contains platform-neutral configuration, errors, logging, formatting, and coordinate types.
- `design_system/` contains reusable visual tokens and components.
- `data/` contains models, repositories, and Supabase integration.
- `services/` wraps platform capabilities such as location, storage, maps, and notifications.
- `features/` contains user-facing modules and consumes data/services through providers and abstractions.

## Boundaries

`dart run tool/verify_architecture.dart` enforces these rules:

- `core` cannot depend on `features`, `data`, or `services`.
- `design_system` cannot depend on application layers.
- Features cannot import other features.
- Features cannot import vendor SDKs directly; use `data/` or `services/` boundaries.
- Shared code cannot import feature code.
- `dart:io` is not allowed in application code because the app must build for Web.
- Icon and font packages are isolated in `design_system/`.

This is intentionally a small source-level guard, not a custom static-analysis framework. Add a rule only when it protects a concrete dependency direction.

## Configuration boundary

All compile-time environment values are read by `lib/core/config/app_config.dart`. Use `--dart-define-from-file` locally or explicit `--dart-define` values in CI. Do not scatter `String.fromEnvironment` calls through features.

The public client configuration contains environment name, Supabase URL/anon key, OneSignal app ID, map configuration, and campus defaults. Server-role keys, OneSignal REST keys, Mapbox secret tokens, signing credentials, and service-account credentials never belong in Flutter configuration.

## Supabase

Schema changes are SQL migrations under `supabase/migrations/`. Review and test migrations locally before applying them to a Supabase project. Production migration deployment is deliberately not automated yet.
