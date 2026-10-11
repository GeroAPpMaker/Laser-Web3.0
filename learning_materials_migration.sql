-- ============================================================
-- learning_materials — Full Setup + Migration
-- Feature: Teacher / Admin Learning Materials
--
-- Run this entire script in the Supabase SQL editor.
-- It is safe to run on a fresh database OR on top of an
-- existing learning_materials table (all drops are guarded
-- with IF EXISTS).
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- STEP 1 — Create the table (skip if it already exists)
-- ──────────────────────────────────────────────────────────────

create table if not exists public.learning_materials (
  id          uuid        primary key default gen_random_uuid(),
  type        text        not null check (type in ('adm', 'lesson_guide', 'reviewer')),
  subject     text        not null,
  term        integer     not null check (term in (1, 2, 3)),
  title       text        not null,
  url         text        not null,
  section     text,                          -- NULL = visible to all sections
  submitted_by text,                         -- email of the teacher / admin who posted it
  created_at  timestamptz not null default now()
);


-- ──────────────────────────────────────────────────────────────
-- STEP 2 — Add submitted_by if upgrading from an older schema
--           (no-op if the column already exists)
-- ──────────────────────────────────────────────────────────────

alter table public.learning_materials
  add column if not exists submitted_by text;


-- ──────────────────────────────────────────────────────────────
-- STEP 3 — Enable Row-Level Security
-- ──────────────────────────────────────────────────────────────

alter table public.learning_materials enable row level security;


-- ──────────────────────────────────────────────────────────────
-- STEP 4 — Drop all previous policies (clean slate)
-- ──────────────────────────────────────────────────────────────

drop policy if exists "Authenticated users can read learning materials"  on public.learning_materials;
drop policy if exists "Admins and teachers can insert learning materials" on public.learning_materials;
drop policy if exists "Admins and teachers can update learning materials" on public.learning_materials;
drop policy if exists "Admins and teachers can delete learning materials" on public.learning_materials;
drop policy if exists "Anyone authenticated can read learning materials"  on public.learning_materials;
drop policy if exists "Admins can insert any learning material"           on public.learning_materials;
drop policy if exists "Teachers can insert adm and reviewer materials"    on public.learning_materials;
drop policy if exists "Admins can update any learning material"           on public.learning_materials;
drop policy if exists "Admins can delete any learning material"           on public.learning_materials;
drop policy if exists "Teachers can delete their own learning materials"  on public.learning_materials;


-- ──────────────────────────────────────────────────────────────
-- STEP 5 — Recreate RLS policies
-- ──────────────────────────────────────────────────────────────

-- 5a. SELECT — every authenticated user (students, teachers, admins) can read
create policy "Anyone authenticated can read learning materials"
  on public.learning_materials
  for select
  to authenticated
  using (true);


-- 5b. INSERT — admins may post any type (adm, lesson_guide, reviewer)
create policy "Admins can insert any learning material"
  on public.learning_materials
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );


-- 5c. INSERT — teachers may only post adm or reviewer (not lesson_guide)
create policy "Teachers can insert adm and reviewer materials"
  on public.learning_materials
  for insert
  to authenticated
  with check (
    type in ('adm', 'reviewer')
    and exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'teacher'
    )
  );


-- 5d. UPDATE — admins only (teachers cannot edit existing rows)
create policy "Admins can update any learning material"
  on public.learning_materials
  for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );


-- 5e. DELETE — admins may delete any row regardless of type or author
create policy "Admins can delete any learning material"
  on public.learning_materials
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );


-- 5f. DELETE — teachers may only delete rows they personally submitted
create policy "Teachers can delete their own learning materials"
  on public.learning_materials
  for delete
  to authenticated
  using (
    submitted_by = (auth.jwt() ->> 'email')
    and exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'teacher'
    )
  );


-- ──────────────────────────────────────────────────────────────
-- POLICY SUMMARY
-- ──────────────────────────────────────────────────────────────
--
--  Role     │ SELECT │ INSERT types            │ UPDATE │ DELETE
--  ─────────┼────────┼─────────────────────────┼────────┼──────────────────────
--  student  │  yes   │ —                       │ —      │ —
--  teacher  │  yes   │ adm, reviewer only      │ —      │ own rows only
--  admin    │  yes   │ adm, lesson_guide,      │ any    │ any
--           │        │ reviewer (all)          │        │
--
-- ──────────────────────────────────────────────────────────────
