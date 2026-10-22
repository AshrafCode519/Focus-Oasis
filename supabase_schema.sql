-- ==============================================================================
-- Focus Oasis (واحة التركيز) - Supabase Database Schema & Hardened Security Setup
-- ==============================================================================
-- Run this script in the Supabase SQL Editor (Dashboard -> SQL Editor -> New query)

-- 1. Profiles table linked to Supabase Auth (with Community & Leaderboard Fields)
-- Note: User email is purposefully excluded to protect privacy from public scraping.
-- Supabase manages emails securely inside the auth.users table.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT DEFAULT 'مستكشف الواحة',
    avatar_icon TEXT DEFAULT '🌿',
    study_field TEXT DEFAULT 'عام',
    bio_status TEXT DEFAULT 'أركز بحماس وإصرار لبناء واحة إنتاجيتي ✨',
    coins_balance INT DEFAULT 120 CHECK (coins_balance >= 0 AND coins_balance <= 10000000),
    total_focus_minutes INT DEFAULT 0 CHECK (total_focus_minutes >= 0),
    today_focus_minutes INT DEFAULT 0 CHECK (today_focus_minutes >= 0),
    weekly_focus_minutes INT DEFAULT 0 CHECK (weekly_focus_minutes >= 0),
    trees_planted INT DEFAULT 0 CHECK (trees_planted >= 0),
    current_streak INT DEFAULT 0 CHECK (current_streak >= 0),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Auto-create profile on Supabase Auth signup (Security Definer)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_icon, study_field, bio_status, coins_balance)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(COALESCE(NEW.email, 'User'), '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_icon', '🌿'),
        COALESCE(NEW.raw_user_meta_data->>'study_field', 'عام'),
        COALESCE(NEW.raw_user_meta_data->>'bio_status', 'أركز بحماس لبناء واحة إنتاجيتي ✨'),
        120
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Focus Sessions Table
CREATE TABLE IF NOT EXISTS public.sessions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    duration_minutes INT NOT NULL CHECK (duration_minutes >= 1 AND duration_minutes <= 1440),
    session_type TEXT NOT NULL CHECK (session_type IN ('focus', 'shortBreak', 'longBreak')),
    status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'failed', 'idle')),
    tree_type_id TEXT NOT NULL,
    coins_earned INT DEFAULT 0 CHECK (coins_earned >= 0 AND coins_earned <= 5000),
    task_id TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE
);

-- 3. Planted Forest Grid Table
CREATE TABLE IF NOT EXISTS public.forest_grid (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT,
    tree_type TEXT NOT NULL,
    is_alive BOOLEAN NOT NULL DEFAULT TRUE,
    duration_minutes INT DEFAULT 25 CHECK (duration_minutes >= 1 AND duration_minutes <= 1440),
    grid_index INT DEFAULT 0 CHECK (grid_index >= 0),
    planted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tasks Table
CREATE TABLE IF NOT EXISTS public.tasks (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    estimated_pomodoros INT DEFAULT 1 CHECK (estimated_pomodoros >= 1 AND estimated_pomodoros <= 100),
    completed_pomodoros INT DEFAULT 0 CHECK (completed_pomodoros >= 0),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- Row Level Security (RLS) - Hardened Data Isolation & Access Controls
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forest_grid ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Profiles Policies:
-- 1) Anyone can read community leaderboard & badges (without sensitive private emails)
DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Public profiles are viewable by authenticated users" ON public.profiles
    FOR SELECT USING (true);

-- 2) Users can insert their own profile row if trigger didn't execute
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3) Users can ONLY update their own profile row
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Sessions Policies: Strict user isolation for SELECT, INSERT, UPDATE, DELETE
DROP POLICY IF EXISTS "Users can access their own sessions" ON public.sessions;
CREATE POLICY "Users can access their own sessions" ON public.sessions
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Forest Grid Policies: Strict user isolation for SELECT, INSERT, UPDATE, DELETE
DROP POLICY IF EXISTS "Users can access their own forest" ON public.forest_grid;
CREATE POLICY "Users can access their own forest" ON public.forest_grid
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Tasks Policies: Strict user isolation for SELECT, INSERT, UPDATE, DELETE
DROP POLICY IF EXISTS "Users can access their own tasks" ON public.tasks;
CREATE POLICY "Users can access their own tasks" ON public.tasks
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- Enable Supabase Realtime for Multi-Device Synchronisation
-- ------------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.forest_grid;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
