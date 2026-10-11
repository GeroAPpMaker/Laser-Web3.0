# LASER-Web v3 — Developer Guide

> **Project:** Las Piñas East National High School (LPENHS) digital portal  
> **Stack:** Vue 3 · Vite · Tailwind CSS v4 · Supabase (PostgreSQL + Auth)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Versions](#2-tech-stack--versions)
3. [Environment Setup](#3-environment-setup)
4. [Project Structure](#4-project-structure)
5. [Routing & Auth Guards](#5-routing--auth-guards)
6. [Authentication System](#6-authentication-system)
7. [Role Resolution Logic](#7-role-resolution-logic)
8. [Database Schema](#8-database-schema)
9. [Views & Components](#9-views--components)
10. [Utilities & Composables](#10-utilities--composables)
11. [Google Sheets Integration](#11-google-sheets-integration)
12. [Styling & Theming](#12-styling--theming)
13. [Known Limitations](#13-known-limitations)
14. [Build & Deployment](#14-build--deployment)

---

## 1. Project Overview

LASER-Web v3 is a browser-based school management portal for LPENHS. It provides:

- Multi-role authentication (Admin, Teacher, Student) via Google OAuth and password login
- Grade entry and term-grade summaries for teachers
- Adviser section management with Google Sheets sync
- Student profile viewing and editing
- Public informational pages (org chart, departments, offices)

---

## 2. Tech Stack & Versions

| Technology | Version | Purpose |
|---|---|---|
| Vue.js | 3.5.41 | Frontend framework |
| Vue Router | 5.3.0 | Client-side routing |
| Vite | 8.2.2 | Build tool & dev server |
| Tailwind CSS | 4.3.3 | Utility-first CSS |
| @tailwindcss/vite | 4.3.3 | Vite plugin for Tailwind |
| Supabase JS | 2.112.4 | Backend-as-a-service (DB + Auth) |

---

## 3. Environment Setup

### Prerequisites

- Node.js ≥ 18
- A Supabase project (free tier is sufficient)

### Steps

```sh
# 1. Install dependencies
npm install

# 2. Copy env template
cp .env.example .env

# 3. Fill in your Supabase credentials in .env
# 4. Apply database schema in Supabase SQL Editor (see Section 8)

# 5. Start dev server
npm run dev
```

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `VITE_SUPABASE_URL` | ✅ | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | ✅ | Supabase anon public key |
| `VITE_STUDENT_TEST_EMAILS` | Optional | Comma-separated emails for test student logins |
| `VITE_TEACHER_GOOGLE_DRIVE_URL` | Optional | Unused in current code |

`VITE_STUDENT_TEST_EMAILS` is for accounts that don't have a `@depedlaspinas.ph` email but should still log in as students (e.g., test accounts).

---

## 4. Project Structure

```
Laserv3/
├── public/                     # Static assets (images, CSV)
├── src/
│   ├── main.js                 # App entry point
│   ├── App.vue                 # Root component
│   ├── style.css               # Tailwind v4 @import
│   ├── supabase.js             # Supabase client singleton
│   ├── router/
│   │   └── index.js            # Routes + beforeEach guard
│   ├── views/                  # Page-level components (one per route)
│   │   ├── HomeView.vue
│   │   ├── Login.vue
│   │   ├── AdminDashboard.vue
│   │   ├── TeacherDashboard.vue
│   │   ├── AdviserDashboard.vue
│   │   ├── StudentDashboard.vue
│   │   ├── TermGradeView.vue
│   │   ├── About.vue
│   │   ├── Contact.vue
│   │   ├── OrgChart.vue
│   │   ├── Department.vue
│   │   └── Office.vue
│   ├── components/             # Reusable UI components
│   │   ├── PublicLayout.vue    # Navbar + Footer wrapper
│   │   ├── Navbar.vue
│   │   ├── Footer.vue
│   │   ├── DashboardHeader.vue
│   │   ├── GradeEntry.vue
│   │   └── GradeSheetUserManual.vue
│   ├── utils/
│   │   ├── auth.js             # Session helpers, profile fetch, role assignment
│   │   └── roleEmail.js        # Email-domain-to-role mapping
│   ├── composables/
│   │   └── useSiteTheme.js     # Dark mode toggle
│   └── data/
│       └── mapSections.js      # Section-to-sheet link map (partially used)
├── .env.example
├── supabase_schema.sql         # Run in Supabase SQL Editor to set up DB
├── vite.config.js
├── tailwind.config.js
└── package.json
```

The legacy `Laser-Web2.0/` directory contains the prior HTML/CSS/JS version and is kept for reference only.

---

## 5. Routing & Auth Guards

Routes are defined in [`src/router/index.js`](src/router/index.js).

### Route Table

| Path | Name | Auth Required | Role |
|---|---|---|---|
| `/` | home | No | Public |
| `/about` | about | No | Public |
| `/organizational-chart` | organizational-chart | No | Public |
| `/contact` | contact | No | Public |
| `/login` | login | No | Public |
| `/department/:subject` | department | No | Public |
| `/office/:name` | office | No | Public |
| `/admin` | admin-dashboard | ✅ | admin |
| `/teacher` | teacher-dashboard | ✅ | teacher |
| `/adviser` | adviser-dashboard | ✅ | teacher (admin also allowed) |
| `/student` | student-dashboard | ✅ | student |
| `/term-grade` | term-grade | ✅ | teacher |

### Guard Behaviour

The `router.beforeEach` hook:

1. Redirects unauthenticated users away from protected routes to `/login`.
2. Redirects authenticated users away from `/login` to their role-specific dashboard.
3. Redirects users who navigate to a dashboard that doesn't match their role.
4. Special case: both `admin` and `teacher` roles can access `/adviser`.

---

## 6. Authentication System

Three login paths exist, all handled in [`src/views/Login.vue`](src/views/Login.vue).

### Google OAuth (Teacher / Student)

- Triggers `supabase.auth.signInWithOAuth({ provider: 'google' })`.
- After redirect, the email domain is used to assign a role (see Section 7).
- The Supabase DB trigger ([`handle_new_user`](#database-schema)) auto-creates a profile on first login.

### Admin Password Login

- `supabase.auth.signInWithPassword({ email, password })`.
- The admin account must already exist in Supabase Auth and have `role = 'admin'` in the `profiles` table. This is set manually in Supabase.

### Student Test Login

- `supabase.auth.signInWithPassword({ email, password })`.
- Email must be listed in `VITE_STUDENT_TEST_EMAILS`.
- Allows non-`@depedlaspinas.ph` accounts to log in as students.

### Sign Out

Use [`signOutUser()`](src/utils/auth.js) from `src/utils/auth.js`. This clears sessionStorage keys and calls `supabase.auth.signOut()`.

---

## 7. Role Resolution Logic

Files involved: [`src/utils/auth.js`](src/utils/auth.js) and [`src/utils/roleEmail.js`](src/utils/roleEmail.js).

### Email Domain Rules

| Domain | Assigned Role |
|---|---|
| `@deped.gov.ph` | `teacher` |
| `@depedlaspinas.ph` | `student` |
| Listed in `VITE_STUDENT_TEST_EMAILS` | `student` |
| Any other email | `null` (cannot log in via Google OAuth) |

### `resolveSessionRole(session)`

Called on every protected route navigation:

1. Extracts email from session.
2. Calls `roleFromEmail()` — if it returns `'teacher'`:
   - Fetches current DB role.
   - If DB role is `'admin'`, returns `'admin'` (preserves admin override).
   - Otherwise ensures DB role is `'teacher'` and returns `'teacher'`.
3. For all other emails, returns the role directly from `profiles`.

This means the only way to be `admin` is to have the `profiles.role` column manually set to `'admin'` in Supabase for a `@deped.gov.ph` account.

---

## 8. Database Schema

Apply [`supabase_schema.sql`](supabase_schema.sql) in the Supabase SQL Editor to create the required tables and trigger.

### Tables

#### `profiles`
Linked 1:1 to `auth.users`. Row Level Security enabled.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | FK → `auth.users.id` |
| `role` | text | `'admin'` \| `'teacher'` \| `'student'` |
| `name` | text | |
| `address` | text | |
| `contact_number` | text | |
| `guardian` | text | |
| `year` | text | |
| `section` | text | |

RLS policies: authenticated users can read and update **their own row only**.

#### `teachers`

| Column | Type |
|---|---|
| `id` | serial PK |
| `name` | text |
| `email` | text |
| `role` | text (`'subject_teacher'` \| `'adviser'`) |

#### `teacher_subject_assignments`

| Column | Type |
|---|---|
| `id` | serial PK |
| `teacher_email` | text |
| `section` | text |
| `subject` | text |

#### `adviser_sections`

| Column | Type |
|---|---|
| `id` | serial PK |
| `teacher_email` | text |
| `section` | text |
| `school_year` | text |

#### `students`

| Column | Type | Notes |
|---|---|---|
| `id` | serial PK | |
| `lrn` | text | Learner Reference Number |
| `name` | text | |
| `sex` | text | `'M'` \| `'F'` |
| `section` | text | |
| `birthday` | date | |

#### `grades`

| Column | Type | Notes |
|---|---|---|
| `id` | serial PK | |
| `lrn` | text | |
| `subject` | text | |
| `section` | text | |
| `term` | text | `'term 1'` \| `'term 2'` \| `'term 3'` |
| `grade` | numeric | |
| `teacher_email` | text | |
| `created_at` | timestamptz | |

#### `adviser_sheets`

| Column | Type |
|---|---|
| `id` | serial PK |
| `email_address` | text |
| `google_sheet_link` | text |

### DB Trigger

`handle_new_user` fires after every insert to `auth.users`. It creates a `profiles` row and assigns `role = 'teacher'` for `@deped.gov.ph` emails, `role = 'student'` otherwise.

---

## 9. Views & Components

### Protected Views

| File | Purpose |
|---|---|
| [`AdminDashboard.vue`](src/views/AdminDashboard.vue) | 5-tab control: Teachers, Advisers, Students, Grades, Term Summary |
| [`TeacherDashboard.vue`](src/views/TeacherDashboard.vue) | Grade entry per subject/section/term |
| [`AdviserDashboard.vue`](src/views/AdviserDashboard.vue) | Student roster, inline edit, Google Sheets sync |
| [`StudentDashboard.vue`](src/views/StudentDashboard.vue) | Profile view and edit form |
| [`TermGradeView.vue`](src/views/TermGradeView.vue) | 9-subject grade matrix with averages; realtime subscription |

### Public Views

`HomeView.vue`, `About.vue`, `OrgChart.vue`, `Contact.vue`, `Department.vue`, `Office.vue`.

### Reusable Components

| Component | Description |
|---|---|
| `PublicLayout.vue` | Wraps public pages with Navbar + Footer |
| `Navbar.vue` | Top nav with dropdown menus, auth state |
| `DashboardHeader.vue` | Title + subtitle for dashboard pages |
| `GradeEntry.vue` | Grade input form used by Teacher Dashboard |
| `GradeSheetUserManual.vue` | Modal overlay with user instructions |

---

## 10. Utilities & Composables

### `src/utils/auth.js`

| Export | Type | Description |
|---|---|---|
| `ROLE_STORAGE_KEY` | const | sessionStorage key for pending role |
| `PENDING_STORAGE_KEY` | const | sessionStorage key for pending Google login |
| `DASHBOARD_BY_ROLE` | const | Maps role string → route name object |
| `fetchProfileRole(userId)` | async fn | Fetches `role` column from `profiles` |
| `fetchCurrentProfile()` | async fn | Returns full profile + `email` from auth |
| `dashboardRouteForRole(role)` | fn | Returns Vue Router location for a role |
| `assignProfileRole(userId, role)` | async fn | Updates `profiles.role` in DB |
| `resolveSessionRole(session)` | async fn | Full role resolution logic |
| `signOutUser()` | async fn | Clears storage + signs out from Supabase |

### `src/utils/roleEmail.js`

| Export | Description |
|---|---|
| `ROLE_EMAIL_DOMAINS` | Object mapping role → email domain |
| `roleFromEmail(email)` | Returns role or `null` based on email |
| `isStudentTestEmail(email)` | Checks against `VITE_STUDENT_TEST_EMAILS` |
| `emailMatchesRole(email, role)` | Validates email belongs to expected role |
| `resolveLoginRole(email, selectedRole)` | Combines domain and selected role |
| `domainErrorForRole(role, email)` | Returns user-facing error message string |

### `src/composables/useSiteTheme.js`

Provides dark mode toggle with `localStorage` persistence. Apply the `dark` class to `<html>` to activate Tailwind dark variants.

---

## 11. Google Sheets Integration

The Adviser Dashboard syncs student data to a Google Sheet via a Google Apps Script web app URL.

- The POST is made with `mode: 'no-cors'`, so no response body is readable.
- The UI always shows "Sync request sent" regardless of actual success.
- The Sheet URL per adviser is stored in the `adviser_sheets` table, keyed by `email_address`.

To set up: deploy a Google Apps Script as a web app and insert the adviser's email + sheet URL into `adviser_sheets` via the Admin Dashboard.

---

## 12. Styling & Theming

- **Primary brand color**: `#000080` (school navy blue), configured in `tailwind.config.js` as `school-primary`.
- **Background canvas**: `#E2E2E2`.
- **Font**: Montserrat (300–800 weights), loaded via Google Fonts in `index.html`.
- **Dark mode**: Class-based (`dark:` prefix in Tailwind). Toggled via `useSiteTheme.js`.

---

## 13. Known Limitations

| Area | Issue |
|---|---|
| Grade validation | No numeric range check (e.g., 0–100) enforced in UI or DB |
| Section ownership | Teachers can submit grades for any section — no enforcement |
| Google Sheets sync | No success confirmation possible (`no-cors`) |
| School year | Hardcoded as `'2026-2027'` in multiple files |
| Terms & subjects | Repeated literal strings across views — no shared constants file |
| Pagination | No pagination on grade or student lists |
| Testing | No unit or integration tests |
| TypeScript | Plain JavaScript — no type safety for DB shapes |
| Admin creation | Admin role must be set manually in Supabase |

---

## 14. Build & Deployment

```sh
# Production build → outputs to dist/
npm run build

# Preview production build locally
npm run preview
```

- The Vite config aliases `@` to `src/`.
- No CI/CD pipeline is currently configured.
- Ensure all four `.env` variables are set in your hosting environment before deploying.
- The `dist/` directory is gitignored and must be built fresh for each deployment.
