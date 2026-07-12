-- ============================================================
-- Basin Collections Tracker — Supabase schema
-- Run this whole file once in Supabase: Dashboard > SQL Editor > New query > Run
-- ============================================================

create extension if not exists "pgcrypto";

-- Profiles: one row per login (Joel, Heather, Nick, Guest)
-- id must match the auth.users id created for that login
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  initials text not null,
  role text not null default 'editor' check (role in ('editor','guest'))
);

create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  name text unique not null
);

create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  document_number text unique not null,
  customer_id uuid not null references customers(id) on delete cascade,
  po_number text,
  invoice_date date,
  due_date date,
  age integer,
  open_balance numeric(14,2) not null default 0,
  is_priority boolean not null default false,
  priority_set_by text,
  priority_set_at timestamptz,
  last_seen_upload date,
  created_at timestamptz not null default now()
);

create table if not exists notes (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references invoices(id) on delete cascade,
  author_name text not null,
  author_initials text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists uploads_log (
  id uuid primary key default gen_random_uuid(),
  uploaded_by text,
  upload_label text,
  invoice_count integer,
  added_count integer,
  removed_count integer,
  created_at timestamptz not null default now()
);

create index if not exists idx_invoices_customer on invoices(customer_id);
create index if not exists idx_notes_invoice on notes(invoice_id);

-- ============================================================
-- Row Level Security
-- Everyone who is logged in (editor or guest) can READ everything.
-- Only 'editor' role rows can INSERT/UPDATE/DELETE.
-- ============================================================

alter table profiles enable row level security;
alter table customers enable row level security;
alter table invoices enable row level security;
alter table notes enable row level security;
alter table uploads_log enable row level security;

create policy "read profiles" on profiles for select using (auth.uid() is not null);

create policy "read customers" on customers for select using (auth.uid() is not null);
create policy "editors write customers" on customers for insert
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));
create policy "editors update customers" on customers for update
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));
create policy "editors delete customers" on customers for delete
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));

create policy "read invoices" on invoices for select using (auth.uid() is not null);
create policy "editors write invoices" on invoices for insert
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));
create policy "editors update invoices" on invoices for update
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));
create policy "editors delete invoices" on invoices for delete
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));

create policy "read notes" on notes for select using (auth.uid() is not null);
create policy "editors write notes" on notes for insert
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));
create policy "editors update notes" on notes for update
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));
create policy "editors delete notes" on notes for delete
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));

create policy "read uploads_log" on uploads_log for select using (auth.uid() is not null);
create policy "editors write uploads_log" on uploads_log for insert
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'editor'));

-- ============================================================
-- Realtime: let the app subscribe to live changes
-- ============================================================
alter publication supabase_realtime add table invoices;
alter publication supabase_realtime add table notes;
alter publication supabase_realtime add table customers;
