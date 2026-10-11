# Adviser Add/Edit Student — Fix Plan

## Top-Level Overview

The Adviser Dashboard's add student and edit student operations fail with:
> `Add failed: new row violates row-level security policy for table "students"`

The `students` table has Row-Level Security (RLS) **enabled** in Supabase but has **no INSERT / UPDATE / DELETE policies**, so all writes are blocked for authenticated users including teachers/advisers.

The fix has three parts:
1. **Supabase SQL** — add RLS policies on `students` allowing admins full access and teachers access scoped to their own advisory section (via `adviser_sections`).
2. **`supabase_schema.sql`** — record the new policies so the file stays as the project source of truth.
3. **UX fix** — the inline edit form is missing a sex selector, so an adviser cannot change a student's sex after adding them. Add it.

---

## Schema Facts (confirmed from actual Supabase schema)

- `students.section` (text) links to `adviser_sections.section`
- `adviser_sections.teacher_email` (text) links to the signed-in user's email
- RLS email can be read in policies via `auth.jwt() ->> 'email'` (Supabase built-in, no `auth.users` subquery needed)
- `profiles.role` holds `'admin'` | `'teacher'` | `'student'`
- `students.sex` has a DB CHECK constraint: only `'M'` or `'F'` are valid — the adviser form already uses these values correctly

---

## Sub-Tasks

---

### Sub-Task 1 — Run RLS Policies in Supabase SQL Editor

**Status:** `[ ] pending`

**Intent**
Add the missing write policies on the `students` table so that:
- Admins (role = 'admin' in `profiles`) can do everything.
- Teachers/advisers can SELECT, INSERT, UPDATE, DELETE only students whose `section` matches their assigned section in `adviser_sections`.

**Expected Outcomes**
- Adviser clicks "Add +" → student is inserted, appears in the table.
- Adviser clicks "Save" on inline edit → row updates without error.
- Adviser clicks "Del" → row is deleted without error.
- Admin users retain full access to all students.
- No other authenticated user (student role) can write to `students`.

**Todo List**
1. Open the Supabase project → SQL Editor.
2. Run this SQL block exactly:

```sql
-- ============================================================
-- RLS Policies for the students table
-- ============================================================

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
```

**Relevant Context**
- Supabase SQL Editor (browser — not a code file change)
- `src/views/AdviserDashboard.vue` — `addStudent()` line 77, `saveEdit()` line 108, `deleteStudent()` line 91
- `adviser_sections.teacher_email` is matched against `auth.jwt() ->> 'email'` (the signed-in user's email from the JWT)

---

### Sub-Task 2 — Record RLS Policies in `supabase_schema.sql`

**Status:** `[ ] pending`

**Intent**
Keep `supabase_schema.sql` as the source of truth for the full database state. The policies from Sub-Task 1 must be appended to this file.

**Expected Outcomes**
- `supabase_schema.sql` contains a clearly commented `students` RLS section with the exact SQL from Sub-Task 1.

**Todo List**
1. Append the students RLS policy block (same SQL as Sub-Task 1) to the bottom of `supabase_schema.sql`.
2. Add a section comment `-- Students table: RLS policies`.

**Relevant Context**
- `supabase_schema.sql` — currently ends at line 58; append after that

---

### Sub-Task 3 — Add Sex Selector to the Inline Edit Form

**Status:** `[ ] pending`

**Intent**
The inline edit rows in both the male and female tables let an adviser change name, LRN, and birthday — but not sex. Since `saveEdit()` already sends `sex` to the DB (line 114), only a template change is needed. The simplest approach is to replace the plain name `<input>` in edit mode with a stacked layout: name input on top + sex dropdown below, so no new column is added.

**Expected Outcomes**
- In edit mode, a sex dropdown (M / F) appears in the Name cell for both male and female tables.
- The dropdown is pre-filled from `editForm.sex`.
- Changing sex and saving updates the DB, and the student moves to the correct table.

**Todo List**
1. In `AdviserDashboard.vue`, in the **male table** edit template (lines 259–267), replace the plain `<input v-model="editForm.name">` cell with a `<div class="flex flex-col gap-1">` containing both the name input and a sex `<select v-model="editForm.sex">`.
2. Do the same in the **female table** edit template (lines 302–310).

**Relevant Context**
- `src/views/AdviserDashboard.vue` lines 259–267 (male edit row)
- `src/views/AdviserDashboard.vue` lines 302–310 (female edit row)
- `saveEdit()` at line 108 already includes `sex: editForm.value.sex` — no script changes needed

---

## Implementation Order

```
Sub-Task 1 (Supabase SQL)  →  Sub-Task 2 (schema file)  →  Sub-Task 3 (Vue template)
```

Sub-Task 1 must be done first as it is the root cause. Sub-Tasks 2 and 3 are independent of each other and can be done in any order after Sub-Task 1.
