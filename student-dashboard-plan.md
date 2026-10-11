# Student Dashboard — Complete Feature Plan

## Top-Level Overview

The student dashboard at `/student` (`src/views/StudentDashboard.vue`) currently only shows a profile view and edit form. This plan completes the student-facing experience by adding:

1. **Tab-based navigation** within the dashboard (Profile, Term Card, ADM, Lesson Guides, Reviewers)
2. **Virtual Term Card** — a printable report card showing the student's grades per subject per term, pulled from the existing `grades` table
3. **Content sections** — ADM, Lesson Guides, and Reviewers displayed as clickable links organised by subject and term, uploaded by teachers/admins
4. **Content management** — a new `learning_materials` Supabase table and an upload UI added to the Admin dashboard for managing content entries

All new features follow the existing patterns: Vue 3 Composition API, Tailwind CSS, direct Supabase calls (no store), and the established blue/slate colour scheme.

---

## Sub-Tasks

---

### Sub-Task 1 — Add `learning_materials` table in Supabase

**Intent**
Create the database table that stores ADM, Lesson Guide, and Reviewer links so teachers/admins can upload them and students can view them.

**Expected Outcomes**
- A `learning_materials` table exists in Supabase with columns: `id`, `type` (adm | lesson_guide | reviewer), `subject`, `term` (1 | 2 | 3), `title`, `url`, `section` (nullable — null means all sections), `created_at`
- Row-Level Security (RLS): authenticated users can `SELECT`; only authenticated users with role `admin` or `teacher` can `INSERT`/`UPDATE`/`DELETE`
- The table is queryable by students filtered on `section` and `type`

**Todo List**
- [ ] In the Supabase dashboard SQL editor, run the `CREATE TABLE` statement for `learning_materials`
- [ ] Enable RLS on the table
- [ ] Add a `SELECT` policy for all authenticated users
- [ ] Add an `INSERT/UPDATE/DELETE` policy restricted to profiles with `role IN ('admin', 'teacher')`

**Relevant Context**
- Existing tables follow the same pattern (see `grades`, `students` in codebase references)
- The `section` column can be `NULL` to mean "all sections" — useful for school-wide materials
- `term` should be an integer (1, 2, 3) matching the existing `grades.term` values

**Status:** `[ ] pending`

---

### Sub-Task 2 — Content upload UI in Admin Dashboard

**Intent**
Allow admins (and teachers, if extended later) to add, view, and delete learning material entries (ADM, Lesson Guides, Reviewers) from the Admin dashboard, so students can find them.

**Expected Outcomes**
- A new tab "Learning Materials" (or section) appears in `AdminDashboard.vue`
- Admins can fill a form: Type (dropdown: ADM / Lesson Guide / Reviewer), Subject (text), Term (1/2/3), Title, URL, Section (optional)
- Submitted entries appear in a list with a delete button
- Uses the same inline-form pattern already present in `AdminDashboard.vue`

**Todo List**
- [ ] Add a "Learning Materials" tab button to the existing tab bar in `AdminDashboard.vue`
- [ ] Add reactive state: `activeMaterials` list, `materialForm` object, `materialLoading`, `materialError`
- [ ] On tab activation, fetch all rows from `learning_materials` ordered by `created_at desc`
- [ ] Render a form with fields: type (select), subject, term (select), title, URL, section (optional)
- [ ] On submit, insert a row into `learning_materials` and refresh the list
- [ ] Render the list as a table with columns: Type, Subject, Term, Title, URL (clickable), Section, Delete action
- [ ] On delete, call `.delete().eq('id', row.id)` and refresh the list

**Relevant Context**
- `src/views/AdminDashboard.vue` uses a `activeTab` ref and `v-if` blocks per tab
- Same Tailwind table/form pattern used in the existing Grades Registry tab
- `supabase` is already imported in AdminDashboard

**Status:** `[ ] pending`

---

### Sub-Task 3 — Refactor StudentDashboard to tab layout

**Intent**
Replace the current single-page profile layout with a tab-based layout (Profile | Term Card | ADM | Lesson Guides | Reviewers) so each feature has its own clean view. The existing profile content is moved into the "Profile" tab unchanged.

**Expected Outcomes**
- `StudentDashboard.vue` renders a horizontal tab bar at the top with 5 tabs
- Clicking each tab swaps the content area below
- The Profile tab shows the existing profile display + edit form exactly as before
- Other tabs are initially empty placeholders (filled in subsequent sub-tasks)
- No existing profile logic is broken

**Todo List**
- [ ] Add an `activeTab` ref defaulting to `'profile'`
- [ ] Add a tab bar `<nav>` with buttons for: Profile, Term Card, ADM, Lesson Guides, Reviewers
- [ ] Style active tab with bottom-border highlight using `#000080` (dark blue, consistent with project primary colour)
- [ ] Wrap the existing profile section in `v-if="activeTab === 'profile'"`
- [ ] Add `v-if` placeholder `<div>`s for each other tab

**Relevant Context**
- `src/views/AdminDashboard.vue` uses the exact same tab pattern — copy that style
- Keep `DashboardHeader` at the top outside the tabs
- Max width container is `max-w-3xl` in StudentDashboard; may need to widen to `max-w-4xl` for the term card table

**Status:** `[ ] pending`

---

### Sub-Task 4 — Virtual Term Card (printable report card)

**Intent**
Show the student's grades for all subjects across all three terms in a report card layout, and provide a print button that prints the card only (hiding navigation and tabs).

**Expected Outcomes**
- "Term Card" tab displays a styled report card with: school name header, student name, year, section, and a table of subjects × terms (columns: Subject, 1st Term, 2nd Term, 3rd Term, Average)
- Grades are fetched from the `grades` table filtered by the student's `section` (matched via `profiles.section`)
- If no LRN match exists, the card still shows the section's grades using `section` as the lookup key (matching how `grades` table stores data)
- A "Print" button triggers `window.print()`; CSS `@media print` hides everything except the card
- If no grades exist, an empty-state message is shown

**Todo List**
- [ ] In the Term Card tab block, fetch grades: `supabase.from('grades').select('*').eq('section', saved.section)`
- [ ] Group fetched grades by `subject`, then by `term`, building a matrix: `{ [subject]: { 1: grade, 2: grade, 3: grade } }`
- [ ] Compute a simple numeric average per subject across available terms
- [ ] Render a card `<div>` with school header, student info row, and the grades matrix `<table>`
- [ ] Add a "Print Term Card" `<button>` that calls `window.print()`
- [ ] Add a `<style>` block with `@media print` rules: hide `.no-print` elements (nav, tabs, header, footer), show only `.print-card`
- [ ] Apply `print-card` class to the card container, `no-print` to the tab bar and dashboard header

**Relevant Context**
- `grades` table columns: `id, lrn, subject, section, term, grade, teacher_email, created_at`
- `profiles.section` is already loaded via `fetchCurrentProfile()` into `saved.section`
- The `TermGradeView.vue` at `src/views/TermGradeView.vue` has a similar grades matrix — reference that for the grouping logic
- Print CSS should be scoped; use `<style scoped>` with `:global(@media print)` or a non-scoped `<style>` block

**Status:** `[ ] pending`

---

### Sub-Task 5 — ADM, Lesson Guides, and Reviewers content tabs

**Intent**
Display the three content types (ADM, Lesson Guides, Reviewers) as clickable link lists, fetched from `learning_materials`, filtered to the student's section and organised by term.

**Expected Outcomes**
- Each of the three content tabs (ADM, Lesson Guides, Reviewers) fetches `learning_materials` where `type` matches and `section` is either `null` (all) or equals the student's section
- Materials are grouped by term (1st, 2nd, 3rd), then listed as clickable link cards showing Title and Subject
- Links open in a new tab (`target="_blank"`)
- If no materials exist for a category, a friendly empty-state message is shown
- All three tabs share the same layout component/pattern (built once, used three times via a prop or reused block)

**Todo List**
- [ ] Create `src/components/MaterialsList.vue` — a reusable component accepting props: `type` (string), `section` (string), `title` (string)
- [ ] In `MaterialsList.vue`, on mount fetch: `supabase.from('learning_materials').select('*').eq('type', type).or('section.is.null,section.eq.' + section)`
- [ ] Group results by `term` (1, 2, 3) using a computed property
- [ ] Render each term group as a labelled section ("1st Term", "2nd Term", "3rd Term") with link cards below
- [ ] Each link card: Title (bold), Subject (muted text below), arrow/external-link icon, full row is an `<a>` tag
- [ ] Show a "No materials available yet" state when the list is empty
- [ ] In `StudentDashboard.vue`, place `<MaterialsList type="adm" :section="saved.section" title="Alternative Delivery Modules" />` in the ADM tab, and equivalent for Lesson Guides (`lesson_guide`) and Reviewers (`reviewer`)

**Relevant Context**
- `saved.section` is already in scope in `StudentDashboard.vue` from Sub-Task 3
- The component should re-fetch when `section` prop changes (use `watchEffect` or `watch`)
- Follow the same card style as the profile section: `rounded-2xl border border-slate-200 bg-white p-6 shadow-sm`
- `type` values must exactly match what is stored in `learning_materials.type`: `adm`, `lesson_guide`, `reviewer`

**Status:** `[ ] pending`

---

## Implementation Notes

- **No new routes needed** — all new features live inside the existing `/student` route via tabs
- **No new auth logic needed** — `fetchCurrentProfile()` already provides everything the student tabs need
- **Database first** — Sub-Task 1 (Supabase table) must be done before Sub-Tasks 2 and 5
- **Sub-Tasks 3 and 4 are independent** of the database work and can be implemented in parallel with Sub-Task 2
- **Print CSS** in Sub-Task 4 must not be scoped to avoid bleeding into other dashboard elements; use a bare `<style>` block or `:global` inside scoped

## File Impact Summary

| File | Change |
|---|---|
| `src/views/StudentDashboard.vue` | Major — add tabs, term card, content tab slots |
| `src/views/AdminDashboard.vue` | Add Learning Materials tab |
| `src/components/MaterialsList.vue` | New file |
| `src/router/index.js` | No change needed |
| `src/utils/auth.js` | No change needed |
| Supabase (manual) | Add `learning_materials` table |
