# Tracklet Supabase Backend Foundation

This directory contains the official Supabase CLI configuration, version-controlled SQL migrations, deterministic seed data, automated tests, and operational guides for the **Tracklet** NITC campus transit and student profile application.

---

## 1. Project Reference & Connection

- **Project Ref ID**: `fnngudikrvelpuhngtlw`
- **Region**: `ap-northeast-1` (Tokyo)
- **Database Host**: `db.fnngudikrvelpuhngtlw.supabase.co`
- **CLI Version**: `2.119.0+`

### Linking the Supabase CLI

```bash
# 1. Authenticate with Supabase CLI
supabase login

# 2. Link local configuration to active project
supabase link --project-ref fnngudikrvelpuhngtlw

# 3. Check migration status
supabase migration list
```

---

## 2. Directory Structure

```text
supabase/
├── config.toml                              # Supabase CLI project configuration
├── migrations/
│   ├── 20261008040000_baseline_schema.sql   # Authoritative schema baseline (10 transit tables, PostGIS, functions, RLS)
│   ├── 20261009080000_add_bus_timings_and_anon_access.sql # Bus timings table & anon public access policies
│   ├── 20261009084500_create_campus_buildings.sql          # Campus buildings landmark table & trigram/spatial indexes
│   ├── 20261009085500_create_departments_users_and_profile_rpcs.sql # Departments, users, auth trigger & profile RPCs
│   ├── 20261009085900_create_hostels_table.sql             # Hostels table, canonical seed & get_hostels RPC
│   └── 20261009122500_comprehensive_postgis_normalization.sql # Dedicated route_geometries, PostGIS spatial RPCs & GiST indexes
├── seed.sql                                 # Deterministic seed data (stops, routes, buses, timings, departments, buildings, hostels)
├── tests/
│   ├── database_schema_and_seed_test.sql    # Transit schema & seed verification tests
│   ├── departments_and_users_test.sql       # Departments, hostels, users, auth trigger, and RPC tests
│   └── spatial_postgis_test.sql             # PostGIS distance, radius, GiST indexes & GeoJSON route geometry tests
└── README.md                                # Backend architecture and Flutter contract documentation
```

---

## 3. Database Architecture & Schema

### Core Tables

1. **`departments`**: 21 canonical academic/administrative NITC departments.
2. **`hostels`**: 16 canonical campus hostels and residential blocks.
3. **`users`**: Student profiles linked to `auth.users(id)` with department, hostel, and onboarding preferences.
4. **`campus_buildings`**: 100 campus landmarks with trigram search and PostGIS points.
5. **`stops`**: 9 canonical campus bus stops with PostGIS generated geography.
6. **`routes`**: 4 loop transit routes with metadata.
7. **`route_geometries`**: Dedicated road-following LineString geometries for Mapbox vector line rendering.
8. **`route_stops`**: 30 ordered stop sequences across routes.
9. **`buses`**: 6 canonical campus transit buses.
10. **`bus_timings`**: 100 scheduled departure timetable entries.
11. **`devices`**: GPS tracker hardware assigned to buses.
12. **`trips`**: Active operational trip sessions per bus/route.
13. **`bus_positions`**: Historical GPS telemetry breadcrumbs with GiST spatial indexing.
14. **`bus_current_state`**: Latest consolidated live position, speed, and heading per bus.
15. **`bus_events`**: Audit log of operational lifecycle events with optional spatial coordinates.

---

## 4. Departments & User Profile Workflow

### A. Auth Profile Trigger (`public.handle_new_user`)
- Attached to `auth.users` (`AFTER INSERT`).
- Executes under `SECURITY DEFINER` with `search_path = public, pg_temp`.
- Automatically inserts a new `public.users` row with `user_id = NEW.id` and `onboarding_completed = false`.
- Safely extracts `full_name` from `NEW.raw_user_meta_data->>'full_name'` if present.
- Safe and idempotent (`ON CONFLICT (user_id) DO NOTHING`).

### B. 21 Canonical Departments
| ID | Department | ID | Department |
|---|---|---|---|
| `AR` | Architecture & Planning | `GS` | Global Studies |
| `BT` | Biotechnology | `HS` | Humanities & Social Sciences |
| `CA` | Fine Arts & Cultural Activities | `IE` | Industrial Engineering |
| `CE` | Civil Engineering | `IK` | Indian Knowledge Systems |
| `CH` | Chemical Engineering | `MA` | Mathematics |
| `CS` | Computer Science & Engineering | `ME` | Mechanical Engineering |
| `CY` | Chemistry | `MS` | Materials Science & Engineering |
| `EC` | Electronics & Communication Engineering | `MT` | Metallurgical & Materials Engineering |
| `EE` | Electrical Engineering | `PE` | Production Engineering |
| `EN` | Energy Engineering | `PH` | Physics |
| `EP` | Engineering Physics | | |

---

## 5. RPC Functions & Flutter Contract

All profile RPCs require an authenticated user (`auth.uid()`). `get_departments()` is publicly callable (`anon` and `authenticated`).

### 1. `get_departments()`
- **Signature**: `get_departments()`
- **Returns**: `TABLE(department_id text, department_name text)`
- **Access**: `anon`, `authenticated`
- **Flutter Usage**:
  ```dart
  final List<dynamic> depts = await supabase.rpc('get_departments');
  // Returns: [{"department_id": "CS", "department_name": "Computer Science & Engineering"}, ...]
  ```

### 2. `get_hostels()`
- **Signature**: `get_hostels()`
- **Returns**: `TABLE(hostel_id text, hostel_name text, short_code text, gender text)`
- **Access**: `anon`, `authenticated`
- **Flutter Usage**:
  ```dart
  final List<dynamic> hostels = await supabase.rpc('get_hostels');
  // Returns: [{"hostel_id": "A", "hostel_name": "A Hostel", "short_code": "A", "gender": "boys"}, ...]
  ```

### 3. `get_my_profile()`
- **Signature**: `get_my_profile()`
- **Returns**: `TABLE(user_id uuid, full_name text, department_id text, department_name text, batch text, hostel text, onboarding_completed boolean, notification_prefs jsonb, created_at timestamptz, updated_at timestamptz)`
- **Access**: `authenticated`
- **Flutter Usage**:
  ```dart
  final profile = await supabase.rpc('get_my_profile').single();
  ```

### 3. `ensure_my_profile()`
- **Signature**: `ensure_my_profile()`
- **Returns**: Current profile row (creates default row if missing).
- **Access**: `authenticated`

### 4. `complete_onboarding(...)`
- **Signature**:
  ```sql
  complete_onboarding(
    p_full_name text,
    p_department_id text,
    p_batch text,
    p_hostel text,
    p_notification_prefs jsonb DEFAULT '{}'::jsonb
  )
  ```
- **Validation**:
  - Requires non-empty `p_full_name`, `p_department_id`, `p_batch`, `p_hostel`.
  - Rejects unknown department IDs with error `23503`.
  - Rejects non-object JSON for `p_notification_prefs`.
  - Sets `onboarding_completed = true` and updates `updated_at`.
- **Flutter Usage**:
  ```dart
  final updatedProfile = await supabase.rpc('complete_onboarding', params: {
    'p_full_name': 'Shashank Mergu',
    'p_department_id': 'CS',
    'p_batch': '2024-2028',
    'p_hostel': 'Mega Hostel Boys',
    'p_notification_prefs': {'bus_alerts': true, 'push_enabled': true},
  }).single();
  ```

### 5. `update_my_profile(...)`
- **Signature**:
  ```sql
  update_my_profile(
    p_full_name text DEFAULT NULL,
    p_department_id text DEFAULT NULL,
    p_batch text DEFAULT NULL,
    p_hostel text DEFAULT NULL,
    p_notification_prefs jsonb DEFAULT NULL
  )
  ```
- **Semantics**:
  - Partial updates: only provided non-null fields are updated.
  - Automatically updates `updated_at`.

---

## 6. Spatial PostGIS RPC Functions

All spatial RPCs use `EPSG:4326` coordinates, `ST_DWithin` with GiST spatial indexes, and `ST_Distance` in meters.

### 1. `get_nearby_stops(p_latitude, p_longitude, p_radius_meters, p_limit)`
- Returns stops sorted by walking distance from student coordinates.
- **Flutter Usage**:
  ```dart
  final List<dynamic> stops = await supabase.rpc('get_nearby_stops', params: {
    'p_latitude': 11.321743,
    'p_longitude': 75.933857,
    'p_radius_meters': 500.0,
    'p_limit': 5,
  });
  ```

### 2. `get_nearby_buses(p_latitude, p_longitude, p_radius_meters, p_limit)`
- Returns active buses within radius sorted by proximity.

### 3. `get_active_bus_positions()`
- Returns live position, heading, speed, and active trip/route for all active buses.

### 4. `get_route_geometry(p_route_id, p_variant)`
- Returns Mapbox/Flutter-ready GeoJSON `LineString` for drawing transit paths.
- **Flutter Usage**:
  ```dart
  final geometry = await supabase.rpc('get_route_geometry', params: {
    'p_route_id': '10000000-0000-4000-8000-000000000001',
    'p_variant': 'main',
  }).single();
  // geometry['geojson']['coordinates'] contains [[lng, lat], ...]
  ```

### 5. `get_campus_buildings_nearby(p_latitude, p_longitude, p_radius_meters, p_limit)`
- Proximity search across 100 campus landmarks.

---

## 7. Verification and Testing

To run the automated test suites against the database:

```bash
# Test 1: Transit schema and seed verification
psql "$DATABASE_URL" -f supabase/tests/database_schema_and_seed_test.sql

# Test 2: Departments, Hostels, Users, Auth Trigger & Profile RPC verification
psql "$DATABASE_URL" -f supabase/tests/departments_and_users_test.sql

# Test 3: PostGIS Spatial distance, radius, GiST indexes & GeoJSON tests
psql "$DATABASE_URL" -f supabase/tests/spatial_postgis_test.sql
```
