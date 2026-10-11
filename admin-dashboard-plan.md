# Admin Dashboard — Missing Features Plan

## Overview

Complete the four outstanding admin capabilities in `src/views/AdminDashboard.vue`:

1. **Edit Teachers and Students** — modal dialog edit forms for existing records
2. **Edit Adviser Section Mapping** — modal dialog to update an adviser's section/year
3. **Edit Teacher Assignment (with dropdown inputs)** — upgrade the assignment form to use dropdowns; add modal edit for existing assignments
4. **Term Summary — All Terms View** — replace the single-term matrix with a side-by-side 3-term view per student plus a computed final average, with a print action

All changes are confined to `src/views/AdminDashboard.vue`. No new files, routes, or store modules are needed.

---

## Sub-Tasks

---

### Sub-Task 1 — Edit Teacher Modal

**Intent:** Allow the admin to correct a teacher's name, email, or role without deleting and re-adding them.

**Expected Outcomes:**
- Each teacher row in the Teachers & Assignments tab has an **Edit** button alongside Delete.
- Clicking Edit opens a modal pre-filled with the teacher's current name, email, and role.
- Submitting the modal calls `supabase.from('teachers').update(...).eq('id', id)` and refreshes the list.
- Cancelling dismisses the modal without changes.

**Todo List:**
- [ ] Add `editingTeacher` ref (null or the teacher object being edited).
- [ ] Add an `editTeacherForm` ref `{ name, email, role }` that is populated when Edit is clicked.
- [ ] Add `openEditTeacher(teacher)` function that sets both refs.
- [ ] Add `saveEditTeacher()` async function that calls Supabase update then clears refs and refetches.
- [ ] Add Edit button to each teacher data row in the template (next to existing Delete button).
- [ ] Add the modal markup (fixed overlay + card) that shows when `editingTeacher !== null`.

**Relevant Context:**
- Table: `teachers` — columns: `id`, `name`, `email`, `role`
- Pattern: follow the same `deleteRecord` confirm-then-fetch pattern, but for update
- File: `src/views/AdminDashboard.vue`, teachers tab template (~line 387–401)

**Status:** [ ] pending

---

### Sub-Task 2 — Edit Student Modal

**Intent:** Allow the admin to correct a student's LRN, name, sex, section, or birthday without deleting and re-adding.

**Expected Outcomes:**
- Each student row has an **Edit** button alongside Transfer and Delete.
- Clicking Edit opens a modal pre-filled with all student fields.
- Submitting calls `supabase.from('students').update(...).eq('id', id)` and refreshes.
- Cancelling closes the modal.

**Todo List:**
- [ ] Add `editingStudent` ref (null or the student being edited).
- [ ] Add `editStudentForm` ref `{ lrn, name, sex, section, birthday }`.
- [ ] Add `openEditStudent(student)` and `saveEditStudent()` functions.
- [ ] Add Edit button to each student data row (between Transfer and Delete).
- [ ] Add the modal markup that shows when `editingStudent !== null`.

**Relevant Context:**
- Table: `students` — columns: `id`, `lrn`, `name`, `sex`, `section`, `birthday`
- Sex field: use the same `<select>` with MALE/FEMALE options as the add form
- File: `src/views/AdminDashboard.vue`, students tab template (~line 490–499)

**Status:** [ ] pending

---

### Sub-Task 3 — Edit Adviser Section Modal + Dropdown

**Intent:** Allow the admin to change which teacher is mapped to an advisory section, or update the school year, without deleting and re-creating the mapping.

**Expected Outcomes:**
- Each adviser mapping row has an **Edit** button alongside Delete.
- Clicking Edit opens a modal pre-filled with teacher_email, section, and school_year.
- The teacher_email field in the modal is a `<select>` dropdown populated from `teachers.value`.
- Submitting calls `supabase.from('adviser_sections').update(...).eq('id', id)` and refreshes.
- The **Add Adviser Mapping** row's teacher_email input is also upgraded to a dropdown from the teachers list.

**Todo List:**
- [ ] Add `editingAdviser` and `editAdviserForm` refs.
- [ ] Add `openEditAdviser(adv)` and `saveEditAdviser()` functions.
- [ ] Add Edit button to each adviser row.
- [ ] Add the modal.
- [ ] Upgrade the Add row's `teacher_email` plain-text input to a `<select>` over `teachers.value`.

**Relevant Context:**
- Table: `adviser_sections` — columns: `id`, `teacher_email`, `section`, `school_year`
- Teachers list is already loaded in `teachers` ref
- File: `src/views/AdminDashboard.vue`, advisers tab template (~line 431–445)

**Status:** [ ] pending

---

### Sub-Task 4 — Edit Teacher Assignment Modal + Dropdowns

**Intent:** Allow editing an existing assignment and make the Add Assignment form use dropdowns instead of plain text inputs to prevent typos.

**Expected Outcomes:**
- The "Map Subject Assignment" add form uses:
  - `<select>` over `teachers.value` for teacher email
  - `<select>` over `uniqueSections` for section
  - `<select>` over `subjectsList` for subject
- Each assignment badge/chip in teacher rows has an **Edit** icon/link (alongside the existing × delete button).
- Clicking Edit opens a modal pre-filled with teacher_email, section, and subject — all as dropdowns.
- Submitting calls `supabase.from('teacher_subject_assignments').update(...).eq('id', id)` and refreshes.

**Todo List:**
- [ ] Add `editingAssignment` and `editAssignmentForm` refs.
- [ ] Add `openEditAssignment(assignment)` and `saveEditAssignment()` functions.
- [ ] Upgrade `newAssignment` add-form inputs (teacher_email, section, subject) to `<select>` dropdowns.
- [ ] Add an Edit pencil button to each assignment chip in the teachers table.
- [ ] Add the modal.

**Relevant Context:**
- Table: `teacher_subject_assignments` — columns: `id`, `teacher_email`, `section`, `subject`
- `subjectsList` ref (line 19–29) holds the 9 fixed subjects
- `uniqueSections` computed (line 51–58) holds all known sections
- `teachers` ref holds teacher objects with `.email` and `.name`
- File: `src/views/AdminDashboard.vue`, teachers tab add-form (~line 408–413) and assignment chips (~line 392–395)

**Status:** [ ] pending

---

### Sub-Task 5 — Term Summary: All-Terms Side-by-Side View + Print

**Intent:** Replace the current single-term-at-a-time matrix with a comprehensive report view that shows all three terms' subject grades and a final overall average in one table, and supports printing.

**Expected Outcomes:**
- The Term Summary tab no longer needs a term selector.
- The table has columns: `Student Name | LRN | [Subject] T1 | [Subject] T2 | [Subject] T3 | Subject Avg | ... | Final Average`
  — OR a simpler layout: one row per student, 9 subjects × 3 terms = 27 grade cells + a final average.
- Alternatively (simpler, more readable): group by subject-row with term columns. Confirm preferred layout in Step 3.
- A **Print** button triggers `window.print()`.
- `fetchSummaryGrades()` is updated to fetch all terms at once (remove the `ilike('term', ...)` filter).
- `formattedSummaryStudents` computed is updated to collect grades for all 3 terms and calculate a final average across all subjects and terms.

**Layout Decision (confirmed with user):**
- One row per student. Columns = Student Name + for each of the 9 subjects: T1 grade, T2 grade, T3 grade, subject average. Final column = overall average.
- A section selector remains so the admin can choose which class to view.
- Print button at the top of the tab.

**Todo List:**
- [ ] Remove the term selector buttons from the summary tab UI.
- [ ] Update `fetchSummaryGrades()` to remove the `.ilike('term', ...)` filter so all terms are fetched.
- [ ] Update `formattedSummaryStudents` to return per-student data with grades keyed as `subjectT1`, `subjectT2`, `subjectT3`, and a per-subject average.
- [ ] Compute `finalAverage` per student as the average of all non-empty subject-term grades.
- [ ] Rewrite the matrix table template with the new column structure (9 subjects × 3 terms + overall average).
- [ ] Add a Print button that calls `window.print()`.
- [ ] Add `@media print` CSS in `<style scoped>` to hide the tab nav and filters when printing.

**Relevant Context:**
- `formattedSummaryStudents` computed (~line 90–124)
- `fetchSummaryGrades()` function (~line 187–200)
- `selectedSummaryTerm` ref and watcher (~line 41, 207–209) — to be removed/replaced
- `subjectsList` ref (line 19–29) — the 9 subjects
- Summary tab template (~line 560–624)

**Status:** [ ] pending

---

## Implementation Notes

- All modals follow the same pattern: a fixed full-screen overlay (`position: fixed; inset: 0`) with a centered card. Use Tailwind classes consistent with the existing UI (`rounded-xl`, `shadow-sm`, `border`, `bg-white`).
- Reuse `errorMessage` ref for modal save errors — the existing error alert at the top of the page will display them.
- No new components are needed; all modal markup lives inline in the single-file component.
- Sub-tasks 1–4 are independent and can be implemented in any order. Sub-task 5 is also independent.
- After all sub-tasks: update the tab description text from "Term Summary Matrix" to "Full Term Report" or similar.
