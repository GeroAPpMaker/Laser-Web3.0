-- Profiles linked to auth.users. Run this in the Supabase SQL editor.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'student'
    check (role in ('admin', 'teacher', 'student')),
  name text,
  address text,
  contact_number text,
  guardian text,
  year text,
  section text
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Create a profile row when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role)
  values (
    new.id,
    case
      when lower(coalesce(new.email, '')) like '%@deped.gov.ph' then 'teacher'
      when lower(coalesce(new.email, '')) like '%@depedlaspinas.ph' then 'student'
      else 'student'
    end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- If profiles already exists, re-run only the function above in the SQL editor
-- so new @deped.gov.ph signups are created as teachers.

-- ============================================================
-- Students table: RLS policies
-- ============================================================

alter table public.students enable row level security;

-- Admins have full access
create policy "Admins have full access to students"
  on public.students
  for all
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

-- Teachers can SELECT students in their advisory section
create policy "Teachers can select their section students"
  on public.students
  for select
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = students.section
    )
  );

-- Teachers can INSERT students into their advisory section
create policy "Teachers can insert students into their section"
  on public.students
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = students.section
    )
  );

-- Teachers can UPDATE students in their advisory section
create policy "Teachers can update their section students"
  on public.students
  for update
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = students.section
    )
  )
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = students.section
    )
  );

-- Teachers can DELETE students in their advisory section
create policy "Teachers can delete their section students"
  on public.students
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = students.section
    )
  );

-- ============================================================
-- Learning Materials table: ADM, Lesson Guides, Reviewers
-- ============================================================

create table public.learning_materials (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('adm', 'lesson_guide', 'reviewer')),
  subject text not null,
  term integer not null check (term in (1, 2, 3)),
  title text not null,
  url text not null,
  section text,  -- null means available to all sections
  created_at timestamptz not null default now()
);

alter table public.learning_materials enable row level security;

-- All authenticated users can read materials
create policy "Authenticated users can read learning materials"
  on public.learning_materials
  for select
  to authenticated
  using (true);

-- Only admins and teachers can insert/update/delete
create policy "Admins and teachers can insert learning materials"
  on public.learning_materials
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role in ('admin', 'teacher')
    )
  );

create policy "Admins and teachers can update learning materials"
  on public.learning_materials
  for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role in ('admin', 'teacher')
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role in ('admin', 'teacher')
    )
  );

create policy "Admins and teachers can delete learning materials"
  on public.learning_materials
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role in ('admin', 'teacher')
    )
  );

-- ============================================================
-- learning_materials: add submitted_by + tighten RLS policies
-- Run this migration in the Supabase SQL editor.
-- ============================================================

-- 1. Add the submitted_by column (nullable — keeps existing rows valid)
alter table public.learning_materials
  add column if not exists submitted_by text;

-- 2. Drop all previous RLS policies on learning_materials
drop policy if exists "Authenticated users can read learning materials"   on public.learning_materials;
drop policy if exists "Admins and teachers can insert learning materials"  on public.learning_materials;
drop policy if exists "Admins and teachers can update learning materials"  on public.learning_materials;
drop policy if exists "Admins and teachers can delete learning materials"  on public.learning_materials;

-- 3. SELECT — all authenticated users may read
create policy "Anyone authenticated can read learning materials"
  on public.learning_materials
  for select
  to authenticated
  using (true);

-- 4. INSERT — admins may insert any type
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

-- 5. INSERT — teachers may only insert adm or reviewer
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

-- 6. UPDATE — admins only (teachers have no update right)
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

-- 7. DELETE — admins may delete any row
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

-- 8. DELETE — teachers may only delete their own rows
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

-- ============================================================
-- Attendance Tables: attendance_records and class_days
-- Run this migration in the Supabase SQL editor.
-- ============================================================

-- attendance_records: one row per student per month per school year
create table public.attendance_records (
  id serial primary key,
  lrn text not null,
  section text not null,
  school_year text not null,
  month text not null check (month in ('JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR')),
  days_present integer not null default 0,
  unique(lrn, school_year, month)
);

alter table public.attendance_records enable row level security;

-- Admins have full access to attendance_records
create policy "Admins have full access to attendance_records"
  on public.attendance_records
  for all
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

-- Advisers can select attendance_records for their section
create policy "Advisers can select their section attendance_records"
  on public.attendance_records
  for select
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = attendance_records.section
    )
  );

-- Advisers can insert attendance_records for their section
create policy "Advisers can insert their section attendance_records"
  on public.attendance_records
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = attendance_records.section
    )
  );

-- Advisers can update attendance_records for their section
create policy "Advisers can update their section attendance_records"
  on public.attendance_records
  for update
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = attendance_records.section
    )
  )
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = attendance_records.section
    )
  );

-- Advisers can delete attendance_records for their section
create policy "Advisers can delete their section attendance_records"
  on public.attendance_records
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = attendance_records.section
    )
  );

-- class_days: total school days per section per month per school year
create table public.class_days (
  id serial primary key,
  section text not null,
  school_year text not null,
  month text not null check (month in ('JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR')),
  total_days integer not null default 0,
  unique(section, school_year, month)
);

alter table public.class_days enable row level security;

-- Admins have full access to class_days
create policy "Admins have full access to class_days"
  on public.class_days
  for all
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

-- Advisers can select class_days for their section
create policy "Advisers can select their section class_days"
  on public.class_days
  for select
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = class_days.section
    )
  );

-- Advisers can insert class_days for their section
create policy "Advisers can insert their section class_days"
  on public.class_days
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = class_days.section
    )
  );

-- Advisers can update class_days for their section
create policy "Advisers can update their section class_days"
  on public.class_days
  for update
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = class_days.section
    )
  )
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = class_days.section
    )
  );

-- Advisers can delete class_days for their section
create policy "Advisers can delete their section class_days"
  on public.class_days
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = class_days.section
    )
  );

-- ============================================================
-- term_comments: adviser's per-student per-term comment
-- Run this migration in the Supabase SQL editor.
-- ============================================================

create table public.term_comments (
  id serial primary key,
  lrn text not null,
  section text not null,
  school_year text not null,
  term text not null check (term in ('term 1', 'term 2', 'term 3')),
  comment text not null default '',
  unique(lrn, school_year, term)
);

alter table public.term_comments enable row level security;

-- Admins have full access to term_comments
create policy "Admins have full access to term_comments"
  on public.term_comments
  for all
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

-- Advisers can select term_comments for their section
create policy "Advisers can select their section term_comments"
  on public.term_comments
  for select
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = term_comments.section
    )
  );

-- Advisers can insert term_comments for their section
create policy "Advisers can insert their section term_comments"
  on public.term_comments
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = term_comments.section
    )
  );

-- Advisers can update term_comments for their section
create policy "Advisers can update their section term_comments"
  on public.term_comments
  for update
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = term_comments.section
    )
  )
  with check (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = term_comments.section
    )
  );

-- Advisers can delete term_comments for their section
create policy "Advisers can delete their section term_comments"
  on public.term_comments
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.adviser_sections
      where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
        and adviser_sections.section = term_comments.section
    )
  );

-- ============================================================
-- students: add grade_level column
-- Run this migration in the Supabase SQL editor.
-- ============================================================

alter table public.students
  add column if not exists grade_level text;

-- ============================================================
-- PENDING MIGRATIONS — run these in the Supabase SQL editor
-- These objects exist in the app code but NOT yet in the live DB.
-- ============================================================

-- ── 1. students: grade_level column ─────────────────────────────────────────
-- (already appended above; kept here as the canonical ordered migration)

alter table public.students
  add column if not exists grade_level text;

-- ── 2. attendance_records ────────────────────────────────────────────────────

create table if not exists public.attendance_records (
  id serial primary key,
  lrn text not null,
  section text not null,
  school_year text not null,
  month text not null check (month in ('JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR')),
  days_present integer not null default 0,
  unique(lrn, school_year, month)
);

alter table public.attendance_records enable row level security;

create policy "Admins have full access to attendance_records"
  on public.attendance_records for all to authenticated
  using (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'))
  with check (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'));

create policy "Advisers can select their section attendance_records"
  on public.attendance_records for select to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = attendance_records.section
  ));

create policy "Advisers can insert their section attendance_records"
  on public.attendance_records for insert to authenticated
  with check (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = attendance_records.section
  ));

create policy "Advisers can update their section attendance_records"
  on public.attendance_records for update to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = attendance_records.section
  ))
  with check (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = attendance_records.section
  ));

create policy "Advisers can delete their section attendance_records"
  on public.attendance_records for delete to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = attendance_records.section
  ));

-- ── 3. class_days ────────────────────────────────────────────────────────────

create table if not exists public.class_days (
  id serial primary key,
  section text not null,
  school_year text not null,
  month text not null check (month in ('JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR')),
  total_days integer not null default 0,
  unique(section, school_year, month)
);

alter table public.class_days enable row level security;

create policy "Admins have full access to class_days"
  on public.class_days for all to authenticated
  using (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'))
  with check (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'));

create policy "Advisers can select their section class_days"
  on public.class_days for select to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = class_days.section
  ));

create policy "Advisers can insert their section class_days"
  on public.class_days for insert to authenticated
  with check (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = class_days.section
  ));

create policy "Advisers can update their section class_days"
  on public.class_days for update to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = class_days.section
  ))
  with check (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = class_days.section
  ));

create policy "Advisers can delete their section class_days"
  on public.class_days for delete to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = class_days.section
  ));

-- ── 4. term_comments ─────────────────────────────────────────────────────────

create table if not exists public.term_comments (
  id serial primary key,
  lrn text not null,
  section text not null,
  school_year text not null,
  term text not null check (term in ('term 1', 'term 2', 'term 3')),
  comment text not null default '',
  unique(lrn, school_year, term)
);

alter table public.term_comments enable row level security;

create policy "Admins have full access to term_comments"
  on public.term_comments for all to authenticated
  using (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'))
  with check (exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role = 'admin'));

create policy "Advisers can select their section term_comments"
  on public.term_comments for select to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = term_comments.section
  ));

create policy "Advisers can insert their section term_comments"
  on public.term_comments for insert to authenticated
  with check (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = term_comments.section
  ));

create policy "Advisers can update their section term_comments"
  on public.term_comments for update to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = term_comments.section
  ))
  with check (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = term_comments.section
  ));

create policy "Advisers can delete their section term_comments"
  on public.term_comments for delete to authenticated
  using (exists (
    select 1 from public.adviser_sections
    where adviser_sections.teacher_email = (auth.jwt() ->> 'email')
      and adviser_sections.section = term_comments.section
  ));
