-- ============================================
-- MediMinder – Supabase Schema
-- Run this script in the Supabase SQL Editor
-- ============================================

-- 1. Medications Table
create table if not exists medications (
  id text primary key,
  user_id uuid references auth.users not null,
  name text not null,
  dosage text not null,
  frequency text not null,
  times jsonb not null default '[]'::jsonb,
  notes text,
  created_at timestamptz default now()
);

-- 2. Medication Logs Table
create table if not exists med_logs (
  id text primary key,
  user_id uuid references auth.users not null,
  med_id text not null,
  date text not null, -- YYYY-MM-DD
  time text not null, -- HH:MM
  taken boolean default false,
  taken_at timestamptz,
  created_at timestamptz default now()
);

-- 3. Appointments Table
create table if not exists appointments (
  id text primary key,
  user_id uuid references auth.users not null,
  doctor_name text not null,
  specialty text,
  date text not null, -- YYYY-MM-DD
  time text not null, -- HH:MM
  location text,
  notes text,
  status text default 'pending', -- pending, done, missed
  created_at timestamptz default now()
);

-- 4. Enable Row Level Security (RLS)
alter table medications enable row level security;
alter table med_logs enable row level security;
alter table appointments enable row level security;

-- 5. Create Policies (CRUD for owner)

-- Medications
create policy "Users can view their own medications" on medications for select using (auth.uid() = user_id);
create policy "Users can insert their own medications" on medications for insert with check (auth.uid() = user_id);
create policy "Users can update their own medications" on medications for update using (auth.uid() = user_id);
create policy "Users can delete their own medications" on medications for delete using (auth.uid() = user_id);

-- Med Logs
create policy "Users can view their own med_logs" on med_logs for select using (auth.uid() = user_id);
create policy "Users can insert their own med_logs" on med_logs for insert with check (auth.uid() = user_id);
create policy "Users can update their own med_logs" on med_logs for update using (auth.uid() = user_id);
create policy "Users can delete their own med_logs" on med_logs for delete using (auth.uid() = user_id);

-- Appointments
create policy "Users can view their own appointments" on appointments for select using (auth.uid() = user_id);
create policy "Users can insert their own appointments" on appointments for insert with check (auth.uid() = user_id);
create policy "Users can update their own appointments" on appointments for update using (auth.uid() = user_id);
create policy "Users can delete their own appointments" on appointments for delete using (auth.uid() = user_id);

-- 6. Enable Realtime for these tables
-- This allows the app to listen for changes immediately
alter publication supabase_realtime add table medications, med_logs, appointments;
