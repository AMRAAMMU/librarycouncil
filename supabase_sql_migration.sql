-- ============================================================================
-- TALUK LIBRARY COUNCIL - SUPABASE POSTGRESQL SCHEMA MIGRATION (PRODUCTION)
-- ============================================================================
-- HOW TO USE:
--   1. Open Supabase Dashboard -> SQL Editor -> New Query, paste this file, and click "Run".
--   2. Go to Authentication -> Users -> "Add User" -> "Create New User"
--      (enable "Auto Confirm User") to create login accounts for council staff.
--   3. Go to Authentication -> Sign In / Providers (or User Signups) and
--      DISABLE "Allow new users to sign up" so only admin-created staff can log in.
-- ============================================================================

-- Enable UUID generation extension
create extension if not exists "uuid-ossp";

-- Shared trigger function to automatically maintain updated_at timestamps
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

-- ============================================================================
-- 1. OPENING BALANCE TABLE
-- ============================================================================
create table if not exists public.council_opening_balance (
  id uuid primary key default uuid_generate_v4(),
  balance_date date not null default current_date,
  cash_in_hand numeric(14,2) not null default 0.00,
  cash_in_bank numeric(14,2) not null default 0.00,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

drop trigger if exists trg_opening_balance_updated_at on public.council_opening_balance;
create trigger trg_opening_balance_updated_at
  before update on public.council_opening_balance
  for each row execute function public.set_updated_at();

-- Ensure singleton default row exists
insert into public.council_opening_balance (id, balance_date, cash_in_hand, cash_in_bank)
values ('00000000-0000-0000-0000-000000000001', current_date, 0.00, 0.00)
on conflict (id) do nothing;

-- ============================================================================
-- 2. LIBRARIES MANAGEMENT TABLE
-- ============================================================================
create table if not exists public.libraries (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  name text not null,
  grade text not null check (grade in ('A', 'B', 'C', 'D')),
  address text default '',
  secretary text default '',
  phone text default '',
  inspection text default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_libraries_code on public.libraries(code);
create index if not exists idx_libraries_grade on public.libraries(grade);

drop trigger if exists trg_libraries_updated_at on public.libraries;
create trigger trg_libraries_updated_at
  before update on public.libraries
  for each row execute function public.set_updated_at();

-- ============================================================================
-- 3. SCHEMES & GRANTS TABLE
-- ============================================================================
create table if not exists public.schemes (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  allocated numeric(14,2) not null default 0.00,
  disbursed numeric(14,2) not null default 0.00,
  beneficiaries text default '',
  status text not null default 'Active' check (status in ('Active', 'Completed', 'Planning')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

drop trigger if exists trg_schemes_updated_at on public.schemes;
create trigger trg_schemes_updated_at
  before update on public.schemes
  for each row execute function public.set_updated_at();

-- ============================================================================
-- 4. CASH BOOK TRANSACTIONS TABLE
-- ============================================================================
create table if not exists public.cashbook (
  id uuid primary key default uuid_generate_v4(),
  type text not null check (type in ('income', 'expense')),
  account text not null check (account in ('cash', 'bank')),
  transaction_date date not null default current_date,
  voucher text not null, -- Receipt No for income or Voucher No for expense
  party text default '',
  bank_ref text default '',
  amount numeric(14,2) not null check (amount > 0),
  head text not null,
  particulars text default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_cashbook_date on public.cashbook(transaction_date, created_at);
create index if not exists idx_cashbook_head on public.cashbook(head);
create index if not exists idx_cashbook_type on public.cashbook(type);

drop trigger if exists trg_cashbook_updated_at on public.cashbook;
create trigger trg_cashbook_updated_at
  before update on public.cashbook
  for each row execute function public.set_updated_at();

-- ============================================================================
-- 5. DOCUMENTS / LETTERS REGISTER TABLE (Inward / Outward)
-- ============================================================================
create table if not exists public.documents (
  id uuid primary key default uuid_generate_v4(),
  type text not null check (type in ('Inward', 'Outward')),
  ref_no text not null,
  doc_date date not null default current_date,
  party text not null default '',
  subject text not null,
  remarks text default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_documents_ref_no on public.documents(ref_no);
create index if not exists idx_documents_date on public.documents(doc_date, created_at);

drop trigger if exists trg_documents_updated_at on public.documents;
create trigger trg_documents_updated_at
  before update on public.documents
  for each row execute function public.set_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - AUTHENTICATED STAFF ONLY
-- Protects all tables when hosted publicly (e.g. GitHub Pages)
-- ============================================================================

alter table public.council_opening_balance enable row level security;
alter table public.libraries enable row level security;
alter table public.schemes enable row level security;
alter table public.cashbook enable row level security;
alter table public.documents enable row level security;

-- Remove legacy open-public policies if previously applied
drop policy if exists "Allow public read/write opening_balance" on public.council_opening_balance;
drop policy if exists "Allow public read/write libraries" on public.libraries;
drop policy if exists "Allow public read/write schemes" on public.schemes;
drop policy if exists "Allow public read/write cashbook" on public.cashbook;
drop policy if exists "Allow public read/write documents" on public.documents;

-- Remove existing staff policies before recreating (idempotent)
drop policy if exists "Authenticated staff full access opening_balance" on public.council_opening_balance;
drop policy if exists "Authenticated staff full access libraries" on public.libraries;
drop policy if exists "Authenticated staff full access schemes" on public.schemes;
drop policy if exists "Authenticated staff full access cashbook" on public.cashbook;
drop policy if exists "Authenticated staff full access documents" on public.documents;

-- Grant full CRUD access strictly to signed-in council staff (Supabase Auth)
create policy "Authenticated staff full access opening_balance"
  on public.council_opening_balance for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy "Authenticated staff full access libraries"
  on public.libraries for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy "Authenticated staff full access schemes"
  on public.schemes for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy "Authenticated staff full access cashbook"
  on public.cashbook for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

create policy "Authenticated staff full access documents"
  on public.documents for all
  to authenticated
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

-- ============================================================================
-- REALTIME SUBSCRIPTIONS (IDEMPOTENT)
-- Safely adds all 5 tables to supabase_realtime without failing on re-runs
-- ============================================================================
do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'council_opening_balance',
    'libraries',
    'schemes',
    'cashbook',
    'documents'
  ]
  loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = tbl
    ) then
      execute format('alter publication supabase_realtime add table public.%I', tbl);
    end if;
  end loop;
end;
$$;
