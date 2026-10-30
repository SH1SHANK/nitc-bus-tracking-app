# Phase 2 — Security and Privacy Hardening

## 1. Summary

Source changes are prepared in both repositories. No production deployment, remote migration, credential rotation, or production-data operation was performed.

The Phase 1 F-01 issue is confirmed in the deployed Supabase Edge Function configuration: `telemetry-simulator` was ACTIVE at version 9 with `verify_jwt=false`. The handler used a service-role client, accepted caller-selected modes and provisioning fields, and included a fleet path that registered/reassigned fixed devices. Until the changes in this report are deployed, the production endpoint remains exposed to unauthorized simulator operations. Source tests do not change that status.

The implementation narrows the Edge Function to one signed scheduled fleet operation, sets JWT verification on, rejects replayed signatures, removes runtime device provisioning and fixed credentials, and requires an explicitly marked simulator fleet. Rider projections and backend rider reads exclude simulation buses. Flutter no longer defaults to a remote Supabase project or Fastify endpoint; its Vercel build requires an explicit environment. An existing Flutter end-to-end test that invoked the deployed function with device credentials was disabled to prevent test runs from writing production telemetry.

## 2. Repositories and preflight state

| Repository | Pre-edit state | Result |
|---|---|---|
| `NITC_BUS_TRACKING_APP` | `main`, `899272a`; tracked tree clean. `docs/audits/phase-1-baseline-audit.md` was untracked and preserved. | App, Supabase functions/migrations/tests, configuration, and deployment docs reviewed. |
| `backend_bus_tracker` | `fix/telemetry-supabase-compatibility`, `aad73de`; tracked tree clean. | Current checkout and relevant auth, telemetry, trip, and bus routes/tests reviewed. |

Backend documentation identifies `stable` as authoritative. Its local `stable` and `origin/stable` point to `4a77fd1`, while the checkout is `aad73de`. The checked-out branch differs from `stable` in 29 files (primarily its architecture documentation and telemetry-simulator tooling). No branch was switched. The edited bus route exists on `stable` and the targeted bus-route change applies cleanly against that file, but the current work remains on the feature branch; deployment must include the backend filter on the branch actually released.

Read-only Supabase inspection identified project `fnngudikrvelpuhngtlw`, ACTIVE_HEALTHY, PostgreSQL 17.11. The deployed migration ledger contains all 19 repository migrations through `20261017060000_retention_cleanup_and_index_optimization`. The new migration in this report is not deployed. No read-only deployment access for the Render backend was available, so its deployed commit/configuration remains unverified.

## 3. Finding-to-change mapping

### F-01 — simulator authorization and privileged device operations

**Severity: P0 Critical, confirmed for the deployed Edge Function configuration; source path confirmed.** Read-only function inventory showed version 9 active with `verify_jwt=false`. The previous source created a service-role client and dispatched caller-selected modes; its fleet operation could register/reassign devices and inject telemetry. The cron caller sent no authentication material. The code change does not secure the already deployed revision.

Changes:

- `supabase/config.toml` now sets `verify_jwt = true` for `telemetry-simulator`.
- `security.ts` verifies an HMAC-SHA-256 signature over the timestamp, nonce, and exact request body; timestamps outside a five-minute window, weak/missing secrets, invalid methods, malformed bodies, extra caller fields, invalid signatures, and replayed nonces are rejected.
- `index.ts` accepts only the signed `fleet` operation. User JWTs, including an administrator JWT, do not authorize simulation. No interactive simulator path is retained.
- The service-role client remains server-side. It is not created until required server configuration is present, and no service-role database call happens for an invalid signature.
- The hard-coded fleet and runtime `register_tracking_device(... p_allow_reassign: true)` path were removed. Fleet definitions and device secrets must come from server-side `SIMULATOR_FLEET_JSON`; every fleet bus/device identifier must start with `SIM-`, and each device must already be active and assigned to a database row marked `is_simulation=true`.
- `20261018083234_secure_telemetry_simulator_scheduler.sql` replaces the cron caller. It reads the HMAC secret and gateway JWT from Supabase Vault, sends the JWT required by the gateway plus a short-lived HMAC signature and random nonce, and grants nonce consumption only to `service_role`. No credential is embedded in migration SQL.
- Missing fleet or server configuration fails closed with a generic error. Function errors do not return database exception text.

The signed request is the only permitted operational caller. Admin simulation is intentionally unavailable; an admin/user JWT alone cannot access it. The scheduled job and interactive-user path are therefore handled without making the function public.

### F-04 — implicit production endpoint selection

**Severity: P2 Medium, source-confirmed; source correction implemented.** `AppConfig` previously defaulted to a live Supabase URL, a public anon key, and a Fastify URL. The public anon key is not a secret, but its fallback caused development builds without defines to access the production project.

The URL/key/backend defaults are now empty. Supabase initialization requires a supported explicit `ENVIRONMENT`, a valid HTTPS endpoint for staging/production (or HTTPS/loopback HTTP in development), and a nonempty anon key. Fastify health checks ignore malformed/insecure URLs. `scripts/vercel-build.sh` requires an explicit environment via `TRACKLET_ENVIRONMENT`, `ENVIRONMENT`, or Vercel’s environment value, and maps Vercel preview to staging. The Android release workflow already defines `ENVIRONMENT=production` and was left intact.

### F-05 — simulation data visible in rider surfaces

**Severity: P1 High, source-confirmed; source correction implemented.** Simulator telemetry previously targeted ordinary Bus 1/Bus 2 records, and rider projections included all active buses. Authentication alone would not have isolated those writes.

The migration adds `buses.is_simulation NOT NULL DEFAULT false`, filters simulator buses from `get_active_bus_positions_v2`, `get_active_trip_stop_events`, and `get_nearby_buses`, and leaves existing buses classified as real. The Fastify `/buses`, `/buses/:id`, and nearby-bus paths are also restricted to non-simulation rows. The Edge Function verifies each configured device’s active status and exact assignment to a simulation bus before invoking simulator actions. Admin operations remain able to inspect the operational data.

### F-02 and F-03 — deliberately deferred

The batch telemetry GPS-jump inconsistency (F-02) and multi-write trip lifecycle consistency (F-03) remain unchanged. No direct authorization vulnerability was established that requires changing either workflow in this phase. Their reliability fixes remain for the later reliability phase.

## 4. Trust boundaries and data flow

### Scheduled simulator

1. `pg_cron` invokes `public.trigger_telemetry_simulation_15s()`.
2. The database function reads the HMAC secret and gateway JWT from Vault. It signs a fixed `{"mode":"fleet"}` operation with a fresh timestamp and UUID nonce; the request includes the gateway JWT for `verify_jwt=true` and the HMAC headers for application-level trust.
3. Supabase’s gateway validates the JWT. The Edge Function independently validates method, exact operation schema, timestamp window, HMAC, and server configuration.
4. Only after signature validation does the service-role client call `consume_telemetry_simulator_nonce`. A unique nonce insert rejects replay.
5. The handler validates its server-side fleet configuration and queries the database to ensure all target buses are marked simulation-only and each configured device is active and assigned to its configured bus. It never creates/reassigns devices.
6. It sends simulator telemetry through the configured Fastify API using the pre-provisioned device credentials. Rider RPCs and Fastify rider reads exclude simulation buses.

Missing secrets/configuration, a malformed fleet, bad assignment, expired/replayed signature, JWT failure, or database authorization failure stops the request before telemetry actions. A correctly signed request still cannot target a real bus unless the database record is explicitly marked simulation-only.

### Rider, device, and staff boundaries

- Flutter authenticates with its public Supabase anon/publishable key; authorization remains in RLS and narrowly granted RPCs. The client contains no service-role, simulator HMAC, or device signing secret.
- Device authentication remains in Fastify plus database RPCs. Telemetry requires a verified device JWT, an active device lookup, a body device ID equal to the token subject, schema checks, and the existing ingestion RPC. Session reset remains credential-gated and rate limited.
- Staff user tokens are validated using Supabase Auth `getUser`; trip routes separately enforce the server-returned `app_metadata.role`. New regression tests verify rider/unauthenticated calls stop before a privileged database query.
- CORS remains a browser policy, not an authorization boundary.

## 5. Database authorization, RLS, and grants

The new ordered migration is additive and does not rewrite applied migrations. It:

- Adds `is_simulation` with a safe false default.
- Adds `telemetry_simulator_nonces` with RLS enabled and no anon/authenticated table grants.
- Defines a SECURITY DEFINER nonce-consumption RPC with explicit `pg_catalog, public, pg_temp` search path, expiry bounds, unique-nonce semantics, revoked PUBLIC/anon/authenticated execution, and an explicit `service_role` grant.
- Replaces the simulator cron function with Vault-backed gateway/HMAC headers, a fixed operation, and explicit execution grants to `postgres` and `service_role` only.
- Replaces rider position, trip-event, and nearby-bus projections to omit simulation buses while preserving result signatures and grants.
- Replaces the named 15-second cron job using its prior schedule.

Existing device, credential-management, admin, ingestion, and rider RPC grant contracts were reviewed in the canonical app migrations and were not otherwise changed. The simulator now relies on the existing pre-provisioned device records and Fastify device authentication rather than a service-role registration bypass.

## 6. Fastify authentication and privacy

Existing source checks were retained: device JWT verification, active-device lookup, device subject/body binding, request schemas, rate limits, and role checks on staff trip routes. Tests already cover unauthenticated telemetry, inactive devices, mismatched device IDs, invalid credentials, and reset-session behavior. New tests cover unauthenticated/rider trip-start denial before database access and simulation-bus exclusion from rider bus list/detail reads.

Fastify’s logger redacts `req.headers.authorization`; route logs inspected contain device identifiers/codes but not authorization headers or GPS coordinates. No logging or error-response change outside the simulator’s generic error response was necessary. Existing audit logs were preserved. No retention period or historical data was changed.

## 7. Configuration and deployment prerequisites

Before deployment, operations must:

1. Provision the HMAC secret (at least 32 bytes) in both Edge Function environment as `SIMULATOR_CRON_HMAC_SECRET` and Supabase Vault as `telemetry_simulator_hmac_secret`. Store a gateway-accepted anon JWT in Vault as `telemetry_simulator_gateway_jwt` for the `apikey` and `Authorization` headers; never use a service-role credential for this gateway field or use the anon JWT as the HMAC secret.
2. Create/identify dedicated simulator bus rows and set `is_simulation=true` only for those rows. Pre-provision active device rows assigned to those buses through the authorized device-management process; the simulator does not register or reassign devices.
3. Set `SIMULATOR_FLEET_JSON` and `RENDER_API_URL` in trusted Edge Function secrets/configuration. Fleet records must contain only the pre-provisioned SIM buses/devices and their device secrets. Keep these values out of SQL, URLs, logs, and the Flutter bundle.
4. Deploy the secured Edge Function/configuration first. Until the nonce RPC exists, valid signed requests fail closed; the old cron’s headerless requests are rejected by the new gateway JWT requirement.
5. Apply the new database migration after the function is secured. It installs the nonce RPC, rider filters, and signed cron job. Then release the Fastify rider filters on the intended backend branch. No production migration or deployment occurred during this phase.
6. Verify the deployed Edge Function reports `verify_jwt=true`, inspect cron success/failure without exposing headers, and confirm simulation rows do not appear in rider position/event/bus reads. Do not treat local test results as production verification.

The backend change is on `fix/telemetry-supabase-compatibility`; the repository documentation says production auto-deploys `stable`. Its filter must be carried to the actual release branch after branch review. No automatic branch reconciliation was done.

## 8. Files changed

App repository:

- `lib/core/config/app_config.dart`
- `scripts/vercel-build.sh`
- `supabase/config.toml`
- `supabase/functions/telemetry-simulator/index.ts`
- `supabase/functions/telemetry-simulator/security.ts`
- `supabase/functions/telemetry-simulator/security_test.ts`
- `supabase/migrations/20261018083234_secure_telemetry_simulator_scheduler.sql`
- `supabase/tests/simulator_security_test.sql`
- `test/core/config/app_config_test.dart`
- `test/pipeline_e2e_test.dart` (removed live production-write coverage; replaced with an explicit skip)
- `README.md`
- `docs/architecture/deployment-and-configuration.md`
- This report.

Backend repository:

- `src/routes/buses.ts`
- `test/buses.simulation-privacy.test.ts`
- `test/authorization.test.ts`

No dependency manifest, lockfile, build output, secret, signing value, or production configuration value was intentionally changed. The Phase 1 report remains untouched.

## 9. Checks and exact outcomes

| Command | Result |
|---|---|
| `flutter test --reporter compact` | **Passed** — 381 tests passed; 1 live pipeline test skipped. |
| `flutter analyze` | **Passed** — no issues found. |
| `flutter test test/core/config/app_config_test.dart --reporter compact` | **Passed** — 4 config tests passed. |
| `deno test supabase/functions/telemetry-simulator/security_test.ts` | **Passed** — 3 tests: missing/invalid credentials and user JWT denial before nonce storage; expired/malformed/extra-field rejection; valid scheduled signature and replay denial. |
| `deno check --config supabase/functions/deno.json supabase/functions/telemetry-simulator/index.ts supabase/functions/telemetry-simulator/security_test.ts` | **Not verified** — blocked by an uncached `@supabase/realtime-js@2.118.0` dependency. No dependency installation was performed. |
| `npm test` | **Passed** — 7 test files, 45 tests. |
| `npm run typecheck` | **Passed** — TypeScript check exited 0. |
| `npm run build` | **Passed** — TypeScript production build exited 0. |
| `bash -n scripts/vercel-build.sh` | **Passed** — shell syntax valid. |
| `env -u TRACKLET_ENVIRONMENT -u ENVIRONMENT -u VERCEL_ENV -u SUPABASE_URL -u SUPABASE_ANON_KEY bash scripts/vercel-build.sh` | **Expected rejection** — exit 1 before dependency/build steps because environment selection is missing. |
| `supabase migration up --local` | **Passed with caveat** — applied migration `20261018083234` to the local database before the final edit that raised the HMAC secret minimum from nonempty to 32 bytes. The final migration file revision was not applied locally. |
| `supabase db query --local --file supabase/tests/simulator_security_test.sql` | **Passed with caveat** — SQL assertions returned `DO` against the applied local migration revision, before the final HMAC minimum-length edit. |
| `supabase db query --local --file supabase/tests/rider_telemetry_access_test.sql` | **Passed** — existing rider-access SQL assertion block returned `DO`. |
| `supabase db test --local supabase/tests/simulator_security_test.sql supabase/tests/rider_telemetry_access_test.sql` | **Not a usable runner for these files** — exit 1, because the repository tests are `DO` assertion scripts, not pgTAP tests with TAP plans; runner reported zero tests/no plan. Both files were then executed successfully with `supabase db query --local --file`. |
| `supabase db query --local --file supabase/migrations/20261018083234_secure_telemetry_simulator_scheduler.sql` | **CLI limitation** — exit 1: this query command prepares one statement and rejects a multi-statement migration. The final migration file revision has not been reapplied. |
| `git diff --check` | **Passed at implementation verification time** in both repositories. The current app and backend worktrees contain subsequent unrelated user edits; current check reports a trailing blank line in `docs/telemetry-integration-changelog.md`, which was not changed for this phase. |

Flutter invoked package resolution during its test/analyze commands. At implementation verification time, no package manifest or lockfile changes remained. The local SQL test ran against the local Supabase container, not the linked production database; that container is now stopped, so the final SQL migration revision could not be reapplied or retested during continuation.

## 10. Rollback considerations

Do not restore the previous Edge Function revision or `verify_jwt=false`; that would restore the confirmed exposure. If the simulator must be stopped, unschedule `bus-telemetry-simulator-15s` first and retain JWT verification. Keep the `is_simulation` column and rider projection filters so existing simulator rows remain isolated. The nonce table/RPC and cron function can be removed only after the scheduler is stopped and the function no longer calls the RPC. Preserve simulation rows and secrets for a separately reviewed cleanup/rotation operation; this phase does not delete data or rotate credentials.

## 11. Remaining risks and unverified work

- **Follow-up simulator removal is source-only and not deployed.** The Flutter workbench and hard-coded device credentials, Edge Function source, backend CLI simulator, and simulator cron/RPC objects are removed or scheduled for removal in the new migration. Production cron/function state is unchanged until the migration is applied and the hosted Edge Function is deleted; no production operation occurred.
- **Production remains exposed until secured Edge Function source/configuration is deployed.** Current live version 9 was read-only observed with `verify_jwt=false`; no production call was made.
- The deployed backend revision, deployed environment variables, and current Render role/rate-limit configuration were not verified.
- Vault secret presence/values, Edge Function secret presence, cron job state/history, and actual simulation-device provisioning were not inspected. Their values are intentionally not reported.
- The migration remains unapplied in the live project. The final SQL file revision differs from the version applied to the now-stopped local stack only in the 32-byte HMAC minimum check; reapply and rerun SQL assertions against an isolated local stack before release.
- Deno security unit tests passed; Deno static type checking is not verified because the required package was not cached and dependency installation was avoided. Full deployed Edge Function behavior has not been exercised.
- The local SQL assertions verified grants, RLS, nonce replay, and projection definitions for the locally applied revision. No production catalog query or write was performed.
- `stable`/feature-branch divergence means the Fastify filter is not on the documented production release branch yet.
- F-02 and F-03 remain intentionally deferred. No production deployment occurred.
