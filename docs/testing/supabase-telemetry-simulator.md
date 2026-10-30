# Supabase telemetry simulator (test environments only)

The simulator writes a small stream of generated positions through the existing
Fastify device-authentication and telemetry-ingestion endpoints. Those requests
update the real `bus_positions` and `bus_current_state` tables and use the
existing database sequence/epoch checks. It does not register devices or
reassign buses.

## Safety boundaries

- The Edge Function accepts only the signed `fleet` request. Supabase JWT
  verification stays enabled; the HMAC timestamp and one-time nonce provide a
  second caller check.
- Each configured bus and device ID must start with `SIM-`; the database must
  already contain an active bus marked `is_simulation=true` and an active device
  assigned to that bus.
- The rider RPC continues to exclude simulation buses. A separate projection
  exposes only simulation rows, and app builds must explicitly opt in.
- The database schedule is inert unless Vault contains
  `telemetry_simulator_enabled=true`. The migration does not add credentials or
  enable the simulator.

## Test setup

1. Apply migrations to an isolated test Supabase project. Do not use the
   production project.
2. Provision a dedicated `SIM-` bus, active device, and active trip on route R1
   or R2 through the existing admin workflow. Mark only that bus
   `is_simulation=true`. Do not reuse a real bus or device.
3. Configure the Edge Function secrets `SIMULATOR_CRON_HMAC_SECRET` (at least 32
   bytes), `SIMULATOR_FLEET_JSON` (the pre-provisioned bus/device identifiers
   and device secret), and `RENDER_API_URL`. The service-role key remains a
   platform-provided server secret and is never added to Flutter or migration
   SQL.
4. Store the matching HMAC secret and a gateway-accepted JWT in Vault as
   `telemetry_simulator_hmac_secret` and `telemetry_simulator_gateway_jwt`. Set
   `telemetry_simulator_enabled` to `true` only when the test database is ready.
   The scheduler then submits four telemetry samples per minute.
5. Build a non-production app with
   `--dart-define=ENVIRONMENT=development --dart-define=INCLUDE_SIMULATED_BUSES=true`.
   The app fetches normal buses from the rider RPC and merges in simulation-only
   rows from `get_simulated_bus_positions_for_testing()`.
6. To stop writes, set the Vault flag back to `false` or unschedule
   `bus-telemetry-simulator-15s`. Existing telemetry rows are retained.

The migration contains no device secrets. Do not paste credential values into
source files, SQL migrations, command history, or logs. This repository change
does not deploy the function, apply migrations, provision Vault, or invoke the
simulator.
