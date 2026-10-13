-- Repair rows omitted or renamed by the remote seed deployment.
INSERT INTO public.stops (
  id,
  code,
  name,
  latitude,
  longitude,
  nearest_node_id,
  is_active
)
VALUES (
  '444f8f96-e747-4382-a80f-a283539f0fec',
  'main_gate',
  'Main Gate',
  11.320083,
  75.932722,
  539386299,
  true
)
ON CONFLICT (id) DO UPDATE SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  nearest_node_id = EXCLUDED.nearest_node_id,
  is_active = EXCLUDED.is_active;

INSERT INTO public.hostels (hostel_id, hostel_name, short_code, gender)
VALUES ('MBH_1', 'Mega Hostel (MBH - Phase 1)', 'MBH-1', 'boys')
ON CONFLICT (hostel_id) DO UPDATE SET
  hostel_name = EXCLUDED.hostel_name,
  short_code = EXCLUDED.short_code,
  gender = EXCLUDED.gender;

INSERT INTO public.hostels (hostel_id, hostel_name, short_code, gender)
VALUES ('LH_MEGA', 'Ladies Hostel (LH - Mega Block)', 'LH-Mega', 'girls')
ON CONFLICT (hostel_id) DO UPDATE SET
  hostel_name = EXCLUDED.hostel_name,
  short_code = EXCLUDED.short_code,
  gender = EXCLUDED.gender;
