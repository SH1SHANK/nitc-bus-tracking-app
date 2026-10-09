-- Tracklet NITC Bus Tracking initial transit schema
-- Minimal, intentional schema matching client domain models

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    roll_number TEXT,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student',
    department TEXT,
    username TEXT UNIQUE,
    branch TEXT,
    batch TEXT,
    semester TEXT,
    hostel TEXT,
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    location_permission_granted BOOLEAN NOT NULL DEFAULT false,
    has_completed_onboarding BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.routes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    description TEXT,
    path JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stops (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    walking_time_minutes INTEGER NOT NULL DEFAULT 5,
    is_major_hub BOOLEAN NOT NULL DEFAULT false,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.route_stops (
    route_id TEXT NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    stop_id TEXT NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
    stop_sequence INTEGER NOT NULL,
    PRIMARY KEY (route_id, stop_id)
);

CREATE TABLE IF NOT EXISTS public.buses (
    id TEXT PRIMARY KEY,
    number_plate TEXT NOT NULL,
    name TEXT NOT NULL,
    route_id TEXT REFERENCES public.routes(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'offline', -- 'live', 'delayed', 'due', 'offline'
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    heading DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    speed_kmh DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    occupancy TEXT DEFAULT 'seats_available',
    last_updated TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;

-- Read policies for transit data (publicly readable by campus members)
CREATE POLICY "Public routes are viewable by everyone" ON public.routes FOR SELECT USING (true);
CREATE POLICY "Public stops are viewable by everyone" ON public.stops FOR SELECT USING (true);
CREATE POLICY "Public route_stops are viewable by everyone" ON public.route_stops FOR SELECT USING (true);
CREATE POLICY "Active buses are viewable by everyone" ON public.buses FOR SELECT USING (true);
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Realtime replication setup
ALTER PUBLICATION supabase_realtime ADD TABLE public.buses;
