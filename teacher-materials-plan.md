# Teacher Learning Materials — Feature Plan

## Top-Level Overview

Teachers currently have no way to post learning materials. This plan adds a **"Learning Materials"** tab to `TeacherDashboard.vue` where teachers can post **ADM** and **Reviewer** links for their students, and delete only the rows they submitted.

The existing `AdminDashboard.vue` Learning Materials tab is updated so that:
- Admins can post **all three types** (ADM, Lesson Guide, Reviewer)
- All posted rows record a `submitted_by` email for ownership tracking
- Admins can delete any row; teachers can only delete their own

The `learning_materials` table gains a `submitted_by` column and its RLS policies are tightened to enforce type and ownership rules.

Students see all materials as before via `MaterialsList.vue` — no changes needed there.

---

## Sub-Tasks

---

### Sub-Task 1 — Migrate `learning_materials` table: add `submitted_by` column and replace RLS policies

**Intent**
Add the `submitted_by text` column so each row records the email of whoever posted it. Replace the existing RLS policies with ones that:
- Allow all authenticated users to SELECT
- Allow admins to INSERT/UPDATE/DELETE everything
- Allow teachers to INSERT only rows where `type IN ('adm', 'reviewer')`
- Allow teachers to DELETE only rows where `submitted_by = auth.jwt() ->> 'email'`
- Deny teachers from deleting or modifying rows they did not post

**Expected Outcomes**
- `learning_materials` has a `submitted_by text` column (nullable to stay compatible with existing rows)
- Old policies are dropped; new policies are in place
- SQL migration script is appended to `supabase_schema.sql`

**Todo List**
- [ ] Append an `ALTER TABLE` statement to add `submitted_by text` column to `learning_materials`
- [ ] Drop all four existing RLS policies on `learning_materials`
- [ ] Re-create SELECT policy: all authenticated users
- [ ] Re-create INSERT policy for admins: `profiles.role = 'admin'` — no type restriction
- [ ] Re-create INSERT policy for teachers: `profiles.role = 'teacher'` AND `type IN ('adm', 'reviewer')`
- [ ] Re-create DELETE policy for admins: `profiles.role = 'admin'` — no restriction
- [ ] Re-create DELETE policy for teachers: `profiles.role = 'teacher'` AND `submitted_by = auth.jwt() ->> 'email'`
- [ ] Re-create UPDATE policy for admins only (teachers have no update right)

**Relevant Context**
- Existing policies use `exists (select 1 from public.profiles where profiles.id = auth.uid() and profiles.role in ('admin','teacher'))` — split this into separate admin and teacher policies
- The `submitted_by` column should be `text` (email string), nullable, no FK
- `auth.jwt() ->> 'email'` returns the signed-in user's email from the JWT claim
- Appending to `supabase_schema.sql` keeps the migration history in one file

**Status:** `[x] done`

---

### Sub-Task 2 — Update `AdminDashboard.vue` Learning Materials tab to record `submitted_by`

**Intent**
The admin's existing add-material form does not write `submitted_by`. Update it so every row inserted by an admin records the admin's email. Also confirm the type dropdown includes all three types (ADM, Lesson Guide, Reviewer) — it already does, so no change needed there.

**Expected Outcomes**
- When admin adds a material, `submitted_by` is set to the admin's current auth email
- The materials list table gains a "Posted By" column showing `submitted_by`
- No other behaviour changes in the admin tab

**Todo List**
- [ ] In `addMaterial()` in `AdminDashboard.vue`, call `supabase.auth.getUser()` to get the current user's email and include `submitted_by: user.email` in the insert payload
- [ ] Add a "Posted By" column header and cell to the materials list table in the admin template
- [ ] No change needed to the type dropdown (already has all three types)

**Relevant Context**
- `addMaterial()` is defined around line 390 in `AdminDashboard.vue`
- The materials table is defined around line 862 in the same file (7 columns currently: Type, Subject, Term, Title, URL, Section, Action)
- Other admin fetch methods already call `supabase.auth.getUser()` patterns — follow same approach
- `activeMaterials` list already has all columns from `select('*')` so `submitted_by` will be present after the column is added to the DB

**Status:** `[x] done`

---

### Sub-Task 3 — Add "Learning Materials" tab to `TeacherDashboard.vue`

**Intent**
Give teachers a dedicated tab inside their dashboard to post ADM and Reviewer links for their students, and to view and delete only the materials they have posted.

**Expected Outcomes**
- `TeacherDashboard.vue` has a tab bar with: existing content in a "Grades" tab + a new "Learning Materials" tab
- The Learning Materials tab shows a form with: Type (dropdown restricted to ADM / Reviewer), Subject, Term (1/2/3), Title, URL, Section (optional)
- On submit, a row is inserted with `submitted_by` = teacher's current auth email
- The list below the form shows only rows where `submitted_by = teacher email`
- Teacher can delete any row in the list (their own rows only — enforced by both UI filter and RLS)
- Loading, error, and empty states are handled

**Todo List**
- [ ] Add `activeTab` ref defaulting to `'grades'` in `TeacherDashboard.vue`
- [ ] Wrap the existing dashboard content (Advisory banner + GradeEntry) in a `v-if="activeTab === 'grades'"` block
- [ ] Add a tab bar `<nav>` styled identically to `AdminDashboard.vue`'s tab bar with two buttons: "Grades" and "Learning Materials"
- [ ] Add reactive state: `myMaterials` (list), `materialForm` (object with type/subject/term/title/url/section), `materialLoading`, `materialError`, `teacherEmail` (string)
- [ ] On mount, resolve `teacherEmail` from `supabase.auth.getUser()` (already done for the adviser check — reuse that result)
- [ ] On tab switch to `'materials'`, call `fetchMyMaterials()`
- [ ] `fetchMyMaterials()`: `supabase.from('learning_materials').select('*').eq('submitted_by', teacherEmail).order('created_at', { ascending: false })`
- [ ] `addMaterial()`: validate required fields, insert with `submitted_by: teacherEmail`, refresh list
- [ ] `deleteMaterial(id)`: confirm + delete + refresh
- [ ] Render the add form: Type select (options: ADM only = `adm`, Reviewer only = `reviewer`), Subject input, Term select (1/2/3), Title input, URL input, Section input (optional)
- [ ] Render the materials list as a table: Type (badge), Subject, Term, Title, URL (link), Section, Delete action
- [ ] Handle empty-state, loading, and error messages

**Relevant Context**
- `TeacherDashboard.vue` currently has no tabs — existing content is a direct render inside `<main>`
- The `currentUserEmail` is already fetched in `onMounted` (line ~10-20 in TeacherDashboard) — reuse this ref for `submitted_by`
- Tab bar style: copy from `AdminDashboard.vue` lines 478-516 (the `<div class="flex border-b...">` block)
- Card/form pattern: copy from the admin Learning Materials tab (lines 833-886 in AdminDashboard.vue)
- Type dropdown must only show `adm` and `reviewer` — not `lesson_guide`
- The `supabase` import is already present in TeacherDashboard

**Status:** `[x] done`

---

## Implementation Notes

- **Sub-Task 1 must be applied in the Supabase SQL editor before Sub-Tasks 2 and 3** — the app code depends on the `submitted_by` column existing
- **Sub-Task 2 and Sub-Task 3 are independent** of each other and can be implemented in either order after Sub-Task 1
- **No StudentDashboard changes needed** — `MaterialsList.vue` already fetches all rows matching the student's section and type; the new `submitted_by` column is just extra data it ignores
- **No new routes needed** — the teacher tab lives inside the existing `/teacher` route

## File Impact Summary

| File | Change |
|---|---|
| `supabase_schema.sql` | Add `submitted_by` column migration + drop/recreate all learning_materials RLS policies |
| `src/views/AdminDashboard.vue` | Update `addMaterial()` to write `submitted_by`; add "Posted By" column to list |
| `src/views/TeacherDashboard.vue` | Add tab layout; add full Learning Materials tab UI |
| `src/components/MaterialsList.vue` | No change |
| `src/views/StudentDashboard.vue` | No change |
