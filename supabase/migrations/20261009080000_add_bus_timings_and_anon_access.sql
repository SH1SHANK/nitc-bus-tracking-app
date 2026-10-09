-- Migration: Add bus_timings table and enable anonymous read access for public transit discovery

-- Table: public.bus_timings
CREATE TABLE IF NOT EXISTS public.bus_timings (
    timing_id uuid NOT NULL DEFAULT gen_random_uuid(),
    bus_id uuid NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
    departure_time time without time zone NOT NULL,
    is_special boolean NOT NULL DEFAULT false,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT bus_timings_pkey PRIMARY KEY (timing_id)
);

CREATE INDEX IF NOT EXISTS bus_timings_bus_id_idx ON public.bus_timings(bus_id);
CREATE INDEX IF NOT EXISTS bus_timings_departure_time_idx ON public.bus_timings(departure_time);

CREATE TRIGGER bus_timings_updated_at
    BEFORE UPDATE ON public.bus_timings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Enable RLS on bus_timings
ALTER TABLE public.bus_timings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'bus_timings' AND policyname = 'read_bus_timings'
    ) THEN
        CREATE POLICY "read_bus_timings" ON public.bus_timings
            FOR SELECT
            TO anon, authenticated
            USING (true);
    END IF;
END;
$$;

-- Allow anonymous access to transit information for campus discovery
DO $$
BEGIN
    -- stops
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'stops' AND policyname = 'read_stops_anon'
    ) THEN
        CREATE POLICY "read_stops_anon" ON public.stops FOR SELECT TO anon USING (true);
    END IF;

    -- routes
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'routes' AND policyname = 'read_routes_anon'
    ) THEN
        CREATE POLICY "read_routes_anon" ON public.routes FOR SELECT TO anon USING (true);
    END IF;

    -- route_stops
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'route_stops' AND policyname = 'read_route_stops_anon'
    ) THEN
        CREATE POLICY "read_route_stops_anon" ON public.route_stops FOR SELECT TO anon USING (true);
    END IF;

    -- buses
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'buses' AND policyname = 'read_buses_anon'
    ) THEN
        CREATE POLICY "read_buses_anon" ON public.buses FOR SELECT TO anon USING (true);
    END IF;

    -- bus_current_state
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'bus_current_state' AND policyname = 'read_bus_current_state_anon'
    ) THEN
        CREATE POLICY "read_bus_current_state_anon" ON public.bus_current_state FOR SELECT TO anon USING (true);
    END IF;
END;
$$;

-- Grant SELECT privileges to anon and authenticated
GRANT SELECT ON public.bus_timings TO anon, authenticated;
GRANT SELECT ON public.stops TO anon, authenticated;
GRANT SELECT ON public.routes TO anon, authenticated;
GRANT SELECT ON public.route_stops TO anon, authenticated;
GRANT SELECT ON public.buses TO anon, authenticated;
GRANT SELECT ON public.bus_current_state TO anon, authenticated;
