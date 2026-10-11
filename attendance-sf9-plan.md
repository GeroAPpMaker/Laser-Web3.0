# Attendance Records Feature & Google Sheets Removal Plan

## Overview

Replace the current Google Apps Script / Google Sheets integration with a native
in-app Attendance Records feature for advisers. The adviser will manage monthly
attendance (days present / days absent) per student entirely within this app,
matching the structure of the SF9 ATTENDANCE RECORD SUMMARY sheet.

**Scope**
- Remove all Google Sheets sync/transmit code from `AdviserDashboard.vue` and `TermGradeView.vue`
- Add a new `attendance_records` Supabase table (stores days-present per student per month)
- Add a new `class_days` Supabase table (stores total school days per month per section/year)
- Add an Attendance tab inside `AdviserDashboard.vue` with a months × students editable grid
- Students from the existing roster auto-populate the attendance grid

**Non-goals**
- No changes to the `adviser_sheets` table (kept as-is)
- No changes to the grades system or TermGradeView display logic
- No changes to AdminDashboard, TeacherDashboard, or StudentDashboard

---

## Sub-Tasks

---

### Sub-Task 1 — Database: New Attendance Tables

**Status:** [ ] pending

**Intent**
Create two new Supabase tables that the attendance grid will read from and write to:
- `attendance_records` — one row per (lrn, month, school_year), storing days_present
- `class_days` — one row per (section, month, school_year), storing total_days (the top row of the attendance grid)

**Expected Outcomes**
- Both tables exist in Supabase with RLS policies matching the existing students table pattern:
  advisers can read/insert/update/delete records for their own section; admins have full access
- Migration SQL is added to `supabase_schema.sql`

**Todo List**
1. Define `attendance_records` table:
   - `id` serial primary key
   - `lrn` text not null
   - `section` text not null
   - `school_year` text not null  (e.g. '2026-2027')
   - `month` text not null check (month in ('JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR'))
   - `days_present` integer not null default 0
   - unique(lrn, school_year, month)
2. Define `class_days` table:
   - `id` serial primary key
   - `section` text not null
   - `school_year` text not null
   - `month` text not null check (same 11 months)
   - `total_days` integer not null default 0
   - unique(section, school_year, month)
3. Enable RLS on both tables
4. Add RLS policies for admins (full access) and teachers/advisers (scoped to their section via `adviser_sections`)
5. Append the SQL migration to `supabase_schema.sql`

**Relevant Context**
- Pattern to copy: RLS policies on `students` table in `supabase_schema.sql` lines 63–142
- The `adviser_sections` table links `teacher_email` → `section`; same JOIN pattern used for scoping
- School year format used in the app: `'2026-2027'` (from INPUT DATA sheet F18)

---

### Sub-Task 2 — Remove Google Sheets Integration

**Status:** [ ] pending

**Intent**
Delete all Google Sheets / Google Apps Script code from `AdviserDashboard.vue` and
`TermGradeView.vue` so the app no longer depends on any external Google service.

**Expected Outcomes**
- `AdviserDashboard.vue`: "Sync to Google Sheets" button gone, "Go to GradeSheets" button gone,
  `syncRecordsToSheet()` and `printCard()` functions removed, `googleSheetLink` ref removed,
  `isSyncing` / `syncMessage` refs removed, `adviser_sheets` Supabase query removed
- `TermGradeView.vue`: Review → Finalize → Transmit buttons/workflow removed,
  `isReviewing`, `isFinalized`, `isTransmitting`, `transmissionMessage` refs removed,
  `reviewGrades()`, `finalizeGrades()`, `transmitGrades()` functions removed,
  hardcoded Google Script URL removed
- No broken template references; app loads without errors

**Todo List**
1. In `AdviserDashboard.vue`:
   a. Remove `googleSheetLink`, `isSyncing`, `syncMessage` refs (lines ~10, 22–23)
   b. Remove the `adviser_sheets` query block (lines ~46–55)
   c. Remove `syncRecordsToSheet()` function (lines ~128–165)
   d. Remove `printCard()` function (lines ~167–174)
   e. In the template, remove the "Sync to Google Sheets" button and "Go to GradeSheets" button
      and the `syncMessage` span from the toolbar (lines ~213–224)
2. In `TermGradeView.vue`:
   a. Remove `isReviewing`, `isFinalized`, `isTransmitting`, `transmissionMessage` refs
   b. Remove the `watch(selectedTerm, ...)` reset block that clears transmission state
   c. Remove `reviewGrades()`, `finalizeGrades()`, `transmitGrades()` functions (~lines 176–222)
   d. Remove the Google Script URL constant
   e. In the template, remove the Review / Finalize / Transmit buttons and the transmission message area

**Relevant Context**
- `src/views/AdviserDashboard.vue` — full file read above; changes touch lines 10, 22–23, 46–55, 127–174, and template lines 213–224
- `src/views/TermGradeView.vue` — relevant section lines 175–222 plus template buttons
- The grade display table in TermGradeView is **not** changed

---

### Sub-Task 3 — Attendance Tab UI in AdviserDashboard

**Status:** [ ] pending

**Intent**
Add a tab switcher (Roster | Attendance) to `AdviserDashboard.vue` and build the
Attendance tab as an editable month × student grid matching the SF9 ATTENDANCE RECORD
SUMMARY layout.

**Expected Outcomes**
- A "Roster" and "Attendance" tab button appear at the top of AdviserDashboard
- Switching to Attendance shows a grid:
  - **Top row (Class Days):** editable integer cells for JUN through APR — the adviser enters total school days per month; these values save to the `class_days` table
  - **Student rows:** one row per student (male section first, female section second, matching SF9 layout); each month cell shows an editable `days_present` integer; the `days_absent` is displayed as a computed read-only value (= class_days[month] - days_present[month])
  - **Total column:** sum of days_present across all months per student (auto-computed)
- Changes to any cell save immediately to Supabase (on blur) with a subtle save indicator
- Students come from the existing `students` table query (no manual add in attendance tab)
- A `school_year` selector (defaulting to current) allows the adviser to view/edit past years

**Todo List**
1. Add a `activeTab` ref (`'roster'` | `'attendance'`) and tab switcher buttons in the template header
2. Wrap the existing roster UI in `v-if="activeTab === 'roster'"`
3. Add attendance data refs: `classDays` (object: month → total_days), `attendanceMap` (object: lrn+month → days_present), `schoolYear` ref
4. Add `fetchAttendanceData()` function:
   - Query `class_days` for (section, schoolYear) → populate `classDays`
   - Query `attendance_records` for all students in section + schoolYear → populate `attendanceMap`
5. Call `fetchAttendanceData()` on mount alongside existing `fetchStudents()`
6. Add `saveClassDays(month, value)` function: upserts to `class_days`
7. Add `saveAttendance(lrn, month, value)` function: upserts to `attendance_records`
8. Compute `daysAbsent(lrn, month)` = `classDays[month] - attendanceMap[lrn][month]` (returns 0 if negative)
9. Compute `totalPresent(lrn)` = sum of `attendanceMap[lrn][m]` across all months
10. Build the attendance grid template:
    - Header row: # | LEARNER NAME | JUN | JUL | AUG | SEP | OCT | NOV | DEC | JAN | FEB | MAR | APR | TOTAL PRESENT
    - "Class Days" row (special row): label | editable inputs per month
    - Student rows with editable days_present + read-only days_absent shown below each cell
    - Male section divider then Female section divider (matching SF9 layout)
11. Style to match existing table aesthetic (bg-[#002060] headers, border-collapse, text-xs)

**Relevant Context**
- `src/views/AdviserDashboard.vue` — existing roster layout (lines 230–334) is the template to match in style
- SF9 ATTENDANCE RECORD SUMMARY rows 12–13: month header = JUN, JUL, AUG, SEP, OCT, NOV, DEC, JAN, FEB, MAR, APR
- SF9 shows Male students in rows 14–63, Female students in rows 65–114 (same Male/Female split already used in the roster)
- The months array is the 11-month school year calendar: `['JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR']`
- Each attendance cell should show two stacked values: "Present: X" (editable) and "Absent: Y" (computed)
- Sub-Task 1 must be complete before this task (the tables must exist)
- Sub-Task 2 should be complete before this task (clean up Google Sheets refs first)

---

## Implementation Notes for Agent

When implementing in agent mode:
- Process Sub-Task 1 first (SQL migration), then Sub-Task 2 (removal), then Sub-Task 3 (new UI)
- After Sub-Task 1: add the SQL to `supabase_schema.sql` and remind the user to run it in Supabase SQL editor
- After Sub-Task 2: verify the app still loads and no console errors from missing refs/functions
- After Sub-Task 3: test the attendance tab loads, class days can be saved, and student attendance can be saved
