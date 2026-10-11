# LASER-Web v3 — User Manual

> **LASER-Web** is the official online portal of **Las Piñas East National High School (LPENHS)**.  
> It provides grade management, student profiles, and school information in one place.

---

## Table of Contents

1. [Accessing the Portal](#1-accessing-the-portal)
2. [Logging In](#2-logging-in)
3. [Admin Guide](#3-admin-guide)
4. [Teacher Guide](#4-teacher-guide)
5. [Adviser Guide](#5-adviser-guide)
6. [Student Guide](#6-student-guide)
7. [Logging Out](#7-logging-out)
8. [Public Pages](#8-public-pages)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Accessing the Portal

Open your web browser and go to the school portal URL. The homepage displays school announcements, a photo carousel, and navigation links to public information.

> The portal works best on modern browsers: Chrome, Edge, or Firefox.

---

## 2. Logging In

Click the **Login** button in the navigation bar or visit `/login`.

### For Teachers

1. Click **Sign in with Google**.
2. Use your **DepEd email** (`your.name@deped.gov.ph`).
3. You will be automatically taken to the Teacher Dashboard.

### For Students

1. Click **Sign in with Google**.
2. Use your **school-issued student email** (`your.name@depedlaspinas.ph`).
3. You will be taken to the Student Dashboard.

> **Test / non-domain accounts:** If your email is on the approved test list, you can sign in with email and password instead.

### For Administrators

1. Choose the **Admin** tab on the login page.
2. Enter your admin email and password.
3. Click **Login**.

> Admin accounts are created manually by the system administrator. You cannot self-register as admin.

### Login Errors

| Error | What to do |
|---|---|
| "Email not allowed for this role" | Make sure you are using the correct email address for your role |
| "Invalid login credentials" | Check your password. Contact the admin if locked out |
| Blank page after Google sign-in | Refresh the page; if it persists, clear browser cookies and try again |

---

## 3. Admin Guide

After logging in as admin, you are taken to the **Admin Dashboard** at `/admin`.

The dashboard has five tabs:

### Tab 1 — Teachers & Assignments

**What you can do:**
- View all registered teachers
- Add a new teacher (name, email, role: subject teacher or adviser)
- Delete a teacher record
- Assign a teacher to a section and subject
- Remove a subject assignment

**To add a teacher:**
1. Fill in the name, email, and role in the Add Teacher form.
2. Click **Add Teacher**.

**To assign a subject:**
1. Enter the teacher's email, the section name, and the subject.
2. Click **Assign**.

---

### Tab 2 — Advisers & Sections

**What you can do:**
- View all adviser-to-section mappings
- Assign an adviser to a section and school year
- Remove an adviser assignment

**To assign an adviser:**
1. Enter the teacher's email, section, and school year (e.g., `2026-2027`).
2. Click **Assign**.

---

### Tab 3 — Students Roster

**What you can do:**
- View all students, filtered by section
- Add a new student (LRN, name, sex, section, birthday)
- Transfer a student to a different section
- Delete a student record

**To add a student:**
1. Fill in the student form at the top of the tab.
2. Click **Add Student**.

**To filter by section:**
Use the section dropdown to show only students in a specific class.

---

### Tab 4 — Grades Registry

**What you can do:**
- View all grade submissions across all subjects, sections, and terms
- Filter by section, subject, and term

Use the dropdown filters to narrow the list. Each row shows the student's LRN, subject, term, grade, and which teacher submitted it.

---

### Tab 5 — Term Summary

**What you can do:**
- View a full term-grade matrix for a selected section and term
- See each student's grade per subject and their computed average

Select a section and a term from the dropdowns. The table shows one row per student with columns for all 9 subjects (Filipino, English, Mathematics, Science, AP, ValuesEd, TLE, MA, PEH) and a computed average.

---

## 4. Teacher Guide

After logging in as a teacher, you are taken to the **Teacher Dashboard** at `/teacher`.

### Entering Grades

1. In the **Grade Entry** section, choose the subject you teach from the dropdown.
2. Select the section.
3. The student list for that section appears.
4. Enter a numeric grade for each student.
5. Click **Submit Grades**.

> Grades are saved per term. Make sure the correct term is selected before submitting.

### User Manual

Click **View User Manual** to open an in-app guide that explains the grade entry process in detail.

### Adviser Link

If you are also an adviser, a button to **Go to Adviser Dashboard** will appear. Click it to manage your advisory section.

---

## 5. Adviser Guide

The Adviser Dashboard is at `/adviser`. It is accessible to teachers who have an advisory section assigned by the admin.

### Viewing Your Students

Your advisory students are listed in two columns: **Male** and **Female**.

Each row shows the student's:
- Name
- LRN (Learner Reference Number)
- Section
- Birthday
- Sex

### Editing Student Information

1. Click the **Edit** button on a student row.
2. Update the fields you want to change.
3. Click **Save**.

### Syncing to Google Sheets

Click **Sync to Google Sheets** to push the current student list to your linked Google Sheet.

> A confirmation message will appear. Note that the portal cannot confirm whether the sync fully succeeded — check your Google Sheet directly after syncing.

### Viewing Grade Sheets

Click **Go to GradeSheets** to open your linked Google Sheets grade book in a new tab.

If no link appears, contact the admin to set up your Google Sheet link.

### Term Grade Summary

Navigate to **Term Grade View** (`/term-grade`) to see a full matrix of grades for your advisory section across all subjects and a selected term.

1. Select the term (Term 1, 2, or 3).
2. View each student's subject grades and computed average.
3. Use the **Finalize** and **Transmit** actions when the term is complete.

---

## 6. Student Guide

After logging in, you are taken to the **Student Dashboard** at `/student`.

### Viewing Your Profile

Your current saved information is displayed:
- Full name
- Address
- Contact number
- Guardian name
- Year level
- Section

### Editing Your Profile

1. Click **Edit Profile**.
2. Update the fields you want to change.
3. Click **Save**.

A success message confirms your changes were saved.

> Contact your adviser or admin if your section or year level is incorrect.

---

## 7. Logging Out

Click your name or the **Logout** button in the navigation bar. You will be signed out and returned to the home page.

---

## 8. Public Pages

These pages are accessible without logging in.

| Page | What it shows |
|---|---|
| **Home** (`/`) | Welcome carousel, school highlights, "Get Started" guide |
| **About** (`/about`) | School history and profile |
| **Organizational Chart** (`/organizational-chart`) | Staff hierarchy |
| **Departments** (`/department/:subject`) | Information about each subject department |
| **Offices** (`/office/:name`) | Information about administrative offices (Principal, Guidance, Records, etc.) |
| **Contact** (`/contact`) | Support contact form |

---

## 9. Troubleshooting

### I can't log in with Google

- Make sure you are using the correct email address (DepEd email for teachers, school student email for students).
- Pop-ups must be allowed in your browser for Google OAuth to work.
- Try a different browser or clear your cookies.

### I was redirected to the wrong dashboard

- Sign out and sign in again.
- If the problem continues, contact the admin — your profile role may need to be corrected in the system.

### My grades are not showing

- Confirm the correct term and section are selected.
- Ask your teacher to check whether grades have been submitted for that term.

### The Google Sheets sync button does nothing

- The sync request was sent, but confirmation is not visible in the portal.
- Open your Google Sheet directly to verify whether the data arrived.
- If the sheet is not linked, ask the admin to add your sheet link in the system.

### The page is blank or shows an error

- Refresh the browser (F5 or Ctrl+R).
- Check your internet connection.
- Try signing out and signing back in.
- If the problem persists, report it to the school's IT coordinator.
