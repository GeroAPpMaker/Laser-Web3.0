<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import DashboardHeader from '../components/DashboardHeader.vue'
import MaterialsList from '../components/MaterialsList.vue'
import { supabase } from '../supabase'
import { fetchCurrentProfile } from '../utils/auth'

// ── Tab navigation ────────────────────────────────────────────────────────────
const activeTab = ref('profile')

// ── Profile state ─────────────────────────────────────────────────────────────
const profileName = ref('')
const loadError = ref('')
const saveError = ref('')
const saveSuccess = ref('')
const isLoading = ref(true)
const isSaving = ref(false)

const form = reactive({
  name: '',
  address: '',
  contact_number: '',
  guardian: '',
  year: '',
  section: '',
})

const welcomeName = computed(() => profileName.value.trim() || 'Student')
const display = (value) => (value && String(value).trim()) || '—'

const saved = reactive({
  name: '',
  address: '',
  contact_number: '',
  guardian: '',
  year: '',
  section: '',
})

function applyProfile(profile) {
  form.name = profile?.name ?? ''
  form.address = profile?.address ?? ''
  form.contact_number = profile?.contact_number ?? ''
  form.guardian = profile?.guardian ?? ''
  form.year = profile?.year ?? ''
  form.section = profile?.section ?? ''
  profileName.value = form.name
  saved.name = form.name
  saved.address = form.address
  saved.contact_number = form.contact_number
  saved.guardian = form.guardian
  saved.year = form.year
  saved.section = form.section
}

onMounted(async () => {
  try {
    const profile = await fetchCurrentProfile()
    applyProfile(profile)
  } catch {
    loadError.value = 'Could not load your profile.'
  } finally {
    isLoading.value = false
  }
})

async function saveProfile() {
  saveError.value = ''
  saveSuccess.value = ''
  isSaving.value = true

  try {
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      saveError.value = 'You must be signed in to save your profile.'
      return
    }

    const { error } = await supabase
      .from('profiles')
      .update({
        name: form.name.trim() || null,
        address: form.address.trim() || null,
        contact_number: form.contact_number.trim() || null,
        guardian: form.guardian.trim() || null,
        year: form.year.trim() || null,
        section: form.section.trim() || null,
      })
      .eq('id', user.id)

    if (error) throw error

    const updated = await fetchCurrentProfile()
    applyProfile(updated)
    saveSuccess.value = 'Profile saved.'
  } catch {
    saveError.value = 'Could not save your profile. Please try again.'
  } finally {
    isSaving.value = false
  }
}

// ── Term Card state ───────────────────────────────────────────────────────────
const termCardLoading = ref(false)
const termCardError = ref('')
const termCardGrades = ref([])

// Subjects in the same order as the rest of the app
const subjectsList = [
  'Filipino', 'English', 'Mathematics', 'Science',
  'AP', 'ValuesEd', 'TLE', 'MA', 'PEH',
]

// Build { [subject]: { 1: grade, 2: grade, 3: grade } } from raw rows
const gradesMatrix = computed(() => {
  const matrix = {}
  for (const row of termCardGrades.value) {
    const subj = row.subject
    const term = Number(row.term)
    if (!matrix[subj]) matrix[subj] = {}
    matrix[subj][term] = row.grade
  }
  return matrix
})

// Sorted list of all subjects that appear in the fetched data
const termCardSubjects = computed(() => {
  const fromData = Object.keys(gradesMatrix.value)
  // Keep canonical order first, then any extras
  const ordered = subjectsList.filter(s => fromData.includes(s))
  const extras = fromData.filter(s => !subjectsList.includes(s))
  return [...ordered, ...extras]
})

function subjectAverage(subject) {
  const termMap = gradesMatrix.value[subject] || {}
  const vals = [1, 2, 3].map(t => termMap[t]).filter(v => v !== undefined && v !== null && v !== '')
  if (!vals.length) return '—'
  return (vals.reduce((a, b) => a + Number(b), 0) / vals.length).toFixed(2)
}

function termGrade(subject, term) {
  const val = (gradesMatrix.value[subject] || {})[term]
  return val !== undefined && val !== null && val !== '' ? val : '—'
}

async function fetchTermCard() {
  if (!saved.section) return
  termCardLoading.value = true
  termCardError.value = ''
  try {
    const { data, error } = await supabase
      .from('grades')
      .select('*')
      .eq('section', saved.section)
    if (error) throw error
    termCardGrades.value = data || []
  } catch (err) {
    termCardError.value = 'Could not load your grades.'
  } finally {
    termCardLoading.value = false
  }
}
</script>

<template>
  <div class="flex-1 bg-slate-50 text-slate-900">
    <DashboardHeader :title="`Welcome ${welcomeName}`" class="no-print" />

    <!-- Tab bar -->
    <nav class="no-print border-b border-slate-200 bg-white">
      <div class="mx-auto max-w-4xl px-4">
        <div class="flex space-x-6 overflow-x-auto">
          <button
            v-for="tab in [
              { id: 'profile', label: 'Profile' },
              { id: 'termcard', label: 'Term Card' },
              { id: 'adm', label: 'ADM' },
              { id: 'lesson_guide', label: 'Lesson Guides' },
              { id: 'reviewer', label: 'Reviewers' },
            ]"
            :key="tab.id"
            @click="activeTab = tab.id; tab.id === 'termcard' && fetchTermCard()"
            class="py-3 px-1 border-b-2 text-sm transition-colors whitespace-nowrap"
            :class="activeTab === tab.id
              ? 'border-[#000080] text-[#000080] font-semibold'
              : 'border-transparent text-slate-500 hover:text-slate-700'"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>
    </nav>

    <main class="mx-auto max-w-4xl px-4 py-8">

      <!-- ── PROFILE TAB ──────────────────────────────────────────────────── -->
      <template v-if="activeTab === 'profile'">
        <section class="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <h2 class="text-lg font-semibold tracking-tight">Your profile</h2>
          <p class="mt-1 text-sm text-slate-600">This is the information currently saved for your account.</p>

          <p v-if="isLoading" class="mt-4 text-sm text-slate-500">Loading your profile…</p>
          <dl v-else class="mt-6 grid gap-4 sm:grid-cols-2">
            <div>
              <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Name</dt>
              <dd class="mt-1 text-sm text-slate-900">{{ display(saved.name) }}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Contact Number</dt>
              <dd class="mt-1 text-sm text-slate-900">{{ display(saved.contact_number) }}</dd>
            </div>
            <div class="sm:col-span-2">
              <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Address</dt>
              <dd class="mt-1 text-sm text-slate-900">{{ display(saved.address) }}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Guardian</dt>
              <dd class="mt-1 text-sm text-slate-900">{{ display(saved.guardian) }}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Year</dt>
              <dd class="mt-1 text-sm text-slate-900">{{ display(saved.year) }}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Section</dt>
              <dd class="mt-1 text-sm text-slate-900">{{ display(saved.section) }}</dd>
            </div>
          </dl>
        </section>

        <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <h2 class="text-lg font-semibold tracking-tight">Edit Profile</h2>
          <p class="mt-1 text-sm text-slate-600">Update your student information.</p>

          <p v-if="loadError" class="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
            {{ loadError }}
          </p>

          <form class="mt-6 grid gap-4" @submit.prevent="saveProfile">
            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Name</span>
              <input
                v-model="form.name"
                type="text"
                name="name"
                autocomplete="name"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Address</span>
              <input
                v-model="form.address"
                type="text"
                name="address"
                autocomplete="street-address"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Contact Number</span>
              <input
                v-model="form.contact_number"
                type="tel"
                name="contact_number"
                autocomplete="tel"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Guardian</span>
              <input
                v-model="form.guardian"
                type="text"
                name="guardian"
                autocomplete="off"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <div class="grid gap-4 sm:grid-cols-2">
              <label class="block">
                <span class="mb-1.5 block text-sm font-medium text-slate-700">Year</span>
                <input
                  v-model="form.year"
                  type="text"
                  name="year"
                  class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                />
              </label>

              <label class="block">
                <span class="mb-1.5 block text-sm font-medium text-slate-700">Section</span>
                <input
                  v-model="form.section"
                  type="text"
                  name="section"
                  class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
                />
              </label>
            </div>

            <p
              v-if="saveError"
              class="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
              role="alert"
            >
              {{ saveError }}
            </p>

            <p
              v-if="saveSuccess"
              class="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800"
            >
              {{ saveSuccess }}
            </p>

            <button
              type="submit"
              class="mt-2 rounded-lg bg-slate-900 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="isLoading || isSaving"
            >
              {{ isSaving ? 'Saving…' : 'Save profile' }}
            </button>
          </form>
        </section>
      </template>

      <!-- ── TERM CARD TAB ───────────────────────────────────────────────── -->
      <template v-else-if="activeTab === 'termcard'">

        <!-- Print button – hidden when printing -->
        <div class="mb-4 flex justify-end no-print">
          <button
            @click="() => window.print()"
            class="rounded-lg bg-[#000080] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#00006a]"
          >
            Print Term Card
          </button>
        </div>

        <!-- ══════════════════════════════════════════════════
             SF9 CARD  – strict black-and-white, no colour
             font: Bookman Old Style / Georgia fallback
        ════════════════════════════════════════════════════ -->
        <div id="sf9-card" class="print-card bg-white" style="font-family:'Bookman Old Style','Georgia',serif; font-size:10px; color:#000; border:2px solid #000; max-width:900px; margin:0 auto;">

          <!-- ══ TOP HEADER: logos + address block ══ -->
          <!-- Right logo stays within the left half — won't cross the fold line -->
          <div style="display:flex; align-items:center; border-bottom:2px solid #000; padding:6px 8px; gap:0;">
            <img src="/images/leftlogo.png" alt="DepEd Logo" style="height:62px; width:62px; object-fit:contain; flex-shrink:0; margin-right:5px;" />
            <div style="flex:1; text-align:center; line-height:1.35;">
              <div style="font-size:8px;">Republic of the Philippines</div>
              <div style="font-size:8px;">Department of Education</div>
              <div style="font-size:8px;">National Capital Region</div>
              <div style="font-size:8px;">City Schools Division of Las Pinas</div>
              <div style="font-size:12px; font-weight:bold; margin-top:2px;">LAS PINAS EAST NATIONAL HIGH SCHOOL</div>
              <div style="font-size:8px;">Kasoy St. Verdant Acres Subd., Pamplona III, Las Pinas City</div>
            </div>
            <img src="/images/rightlogo.png" alt="School Logo" style="height:62px; width:62px; object-fit:contain; flex-shrink:0; margin-left:5px;" />
          </div>

          <!-- Loading / error states -->
          <p v-if="termCardLoading" style="padding:24px; text-align:center; color:#555;">Loading grades…</p>
          <p v-else-if="termCardError" style="margin:8px; border:1px solid #ccc; padding:6px; color:#900;">{{ termCardError }}</p>

          <!-- ══ MAIN TWO-COLUMN BODY ══ -->
          <template v-else>
            <div style="display:grid; grid-template-columns:1fr 16px 1fr; border-top:1px solid #000;">

              <!-- ╔══════════════════════════╗
                   ║  LEFT PANEL              ║
                   ╚══════════════════════════╝ -->
              <div style="padding-right:6px;">

                <!-- LEARNER'S PERFORMANCE REPORT title -->
                <div style="text-align:center; padding:5px 8px; border-bottom:1px solid #000;">
                  <div style="font-size:11px; font-weight:bold;">LEARNER'S PERFORMANCE REPORT</div>
                  <div style="font-size:8px;">School Year 2026–2027</div>
                </div>

                <!-- Student Info -->
                <div style="padding:4px 8px; border-bottom:1px solid #000; font-size:9px;">
                  <div style="display:flex; gap:6px; margin-bottom:2px;">
                    <span><strong>Name:</strong> {{ display(saved.name) }}</span>
                    <span style="margin-left:auto;"><strong>Age:</strong> &nbsp;&nbsp;&nbsp;<strong>Sex:</strong></span>
                  </div>
                  <div style="display:flex; gap:6px;">
                    <span><strong>LRN:</strong></span>
                    <span><strong>Grade:</strong> {{ display(saved.year) }}</span>
                    <span><strong>Section:</strong> {{ display(saved.section) }}</span>
                  </div>
                  <div style="margin-top:2px;"><strong>Track (SHS only):</strong></div>
                </div>

                <!-- Dear Parents -->
                <div style="padding:4px 8px; border-bottom:1px solid #000; font-size:8.5px; line-height:1.4;">
                  <div><strong>Dear Parents / Guardian,</strong></div>
                  <div style="margin-top:2px;">This Performance Report presents your child's progress and achievement in the different learning areas. The school welcomes you to reach out should you wish to know more about your child's learning and performance.</div>
                </div>

                <!-- School Head / Adviser signatures -->
                <div style="display:grid; grid-template-columns:1fr 1fr; padding:4px 8px; border-bottom:1px solid #000; font-size:8.5px; gap:8px;">
                  <div>
                    <div style="border-bottom:1px solid #000; padding-bottom:14px; font-weight:bold;">NELSON A. IMACULATA JR.</div>
                    <div style="text-align:center; margin-top:1px;">School Head</div>
                  </div>
                  <div>
                    <div style="border-bottom:1px solid #000; padding-bottom:14px;">&nbsp;</div>
                    <div style="text-align:center; margin-top:1px;">Adviser</div>
                  </div>
                </div>

                <!-- LEARNING PROGRESS AND ACHIEVEMENT header -->
                <div style="font-size:8px; font-weight:bold; text-align:center; padding:2px 8px; border-bottom:1px solid #000; letter-spacing:0.03em;">
                  LEARNING PROGRESS AND ACHIEVEMENT
                </div>

                <!-- Grades table -->
                <div v-if="termCardSubjects.length === 0" style="padding:12px 8px; text-align:center; font-size:9px; color:#555;">
                  No grades recorded yet.
                </div>
                <table v-else style="width:100%; border-collapse:collapse; font-size:9px;">
                  <thead>
                    <tr>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:left;" rowspan="2">Learning Areas</th>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:center;" colspan="3">TERM</th>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:center;" rowspan="2">Final<br>Grade</th>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:center;" rowspan="2">Remarks</th>
                    </tr>
                    <tr>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:center;">T1</th>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:center;">T2</th>
                      <th style="border:1px solid #000; padding:2px 4px; text-align:center;">T3</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="subject in termCardSubjects" :key="subject">
                      <td style="border:1px solid #000; padding:2px 4px;">{{ subject }}</td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center;">{{ termGrade(subject, 1) }}</td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center;">{{ termGrade(subject, 2) }}</td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center;">{{ termGrade(subject, 3) }}</td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center; font-weight:bold;">{{ subjectAverage(subject) }}</td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center;">
                        {{ subjectAverage(subject) === '—' ? '—' : (Number(subjectAverage(subject)) >= 75 ? 'Passed' : 'Failed') }}
                      </td>
                    </tr>
                    <!-- General Average -->
                    <tr>
                      <td style="border:1px solid #000; padding:2px 4px; font-weight:bold; text-align:right;" colspan="4">General Average</td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center; font-weight:bold;">
                        {{ (() => { const a=termCardSubjects.map(s=>subjectAverage(s)).filter(v=>v!=='—').map(Number); return a.length?(a.reduce((x,y)=>x+y,0)/a.length).toFixed(0):'—' })() }}
                      </td>
                      <td style="border:1px solid #000; padding:2px 4px; text-align:center; font-weight:bold;">
                        {{ (() => { const a=termCardSubjects.map(s=>subjectAverage(s)).filter(v=>v!=='—').map(Number); if(!a.length)return '—'; return (a.reduce((x,y)=>x+y,0)/a.length)>=75?'PROMOTED':'RETAINED' })() }}
                      </td>
                    </tr>
                  </tbody>
                </table>

                <!-- Performance Descriptors -->
                <div style="padding:4px 8px; border-top:1px solid #000;">
                  <div style="font-size:8px; font-weight:bold; margin-bottom:2px;">PERFORMANCE DESCRIPTORS</div>
                  <table style="width:100%; border-collapse:collapse; font-size:8px;">
                    <thead>
                      <tr>
                        <th style="border:1px solid #000; padding:1px 4px; text-align:center;">Grading Scale</th>
                        <th style="border:1px solid #000; padding:1px 4px; text-align:center;">Descriptors</th>
                        <th style="border:1px solid #000; padding:1px 4px; text-align:center;">Remarks</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr><td style="border:1px solid #000;padding:1px 4px;text-align:center;">90-100</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Advancing</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Passed</td></tr>
                      <tr><td style="border:1px solid #000;padding:1px 4px;text-align:center;">80-89</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Benchmarking</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Passed</td></tr>
                      <tr><td style="border:1px solid #000;padding:1px 4px;text-align:center;">75-79</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Connecting</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Passed</td></tr>
                      <tr><td style="border:1px solid #000;padding:1px 4px;text-align:center;">65-74</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Developing</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Failed</td></tr>
                      <tr><td style="border:1px solid #000;padding:1px 4px;text-align:center;">0-64</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Emerging</td><td style="border:1px solid #000;padding:1px 4px;text-align:center;">Failed</td></tr>
                    </tbody>
                  </table>
                </div>

              </div><!-- end left panel -->

              <!-- ╔══════════════════════════╗
                   ║  FOLD GUTTER             ║
                   ╚══════════════════════════╝ -->
              <div style="position:relative;">
                <div style="position:absolute; left:50%; top:0; bottom:0; border-left:2px solid #000;"></div>
              </div>

              <!-- ╔══════════════════════════╗
                   ║  RIGHT PANEL             ║
                   ╚══════════════════════════╝ -->
              <div style="padding-left:6px;">

                <!-- Attendance grid -->
                <table style="width:100%; border-collapse:collapse; font-size:8px; border-bottom:1px solid #000;">
                  <thead>
                    <tr>
                      <th style="border:1px solid #000; padding:2px 3px;">Month</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Jun</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Jul</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Aug</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Sep</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Oct</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Nov</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Dec</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Jan</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Feb</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Mar</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center;">Apr</th>
                      <th style="border:1px solid #000; padding:2px 3px; text-align:center; font-weight:bold;">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td style="border:1px solid #000; padding:2px 3px; font-size:7px; white-space:nowrap;">No. of Class Days</td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000; padding:2px 3px; font-size:7px; white-space:nowrap;">No. of Days Present</td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000; padding:2px 3px; font-size:7px; white-space:nowrap;">No. of Days Absent</td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                      <td style="border:1px solid #000; padding:2px 3px;"></td><td style="border:1px solid #000; padding:2px 3px;"></td>
                    </tr>
                  </tbody>
                </table>

                <!-- Teacher's Comments / Remarks -->
                <div style="border-bottom:1px solid #000; padding:5px 7px; margin-bottom:0;">
                  <div style="font-size:8px; font-weight:bold; text-align:center; border-bottom:1px solid #000; margin-bottom:5px; padding-bottom:3px;">TEACHER'S COMMENTS / REMARKS</div>
                  <div style="font-size:8px; margin-bottom:3px;"><strong>Term 1</strong></div>
                  <div style="border-bottom:1px solid #000; min-height:40px; margin-bottom:7px;"></div>
                  <div style="font-size:8px; margin-bottom:3px;"><strong>Term 2</strong></div>
                  <div style="border-bottom:1px solid #000; min-height:40px; margin-bottom:7px;"></div>
                  <div style="font-size:8px; margin-bottom:3px;"><strong>Term 3</strong></div>
                  <div style="border-bottom:1px solid #000; min-height:40px; margin-bottom:4px;"></div>
                </div>

                <!-- Parent/Guardian Signature -->
                <div style="border-bottom:1px solid #000; padding:5px 7px;">
                  <div style="font-size:8px; font-weight:bold; text-align:center; border-bottom:1px solid #000; margin-bottom:5px; padding-bottom:3px;">PARENT/S GUARDIAN'S SIGNATURE</div>
                  <div style="font-size:8px; margin-bottom:3px;"><strong>Term 1</strong></div>
                  <div style="border-bottom:1px solid #000; min-height:32px; margin-bottom:7px;"></div>
                  <div style="font-size:8px; margin-bottom:3px;"><strong>Term 2</strong></div>
                  <div style="border-bottom:1px solid #000; min-height:32px; margin-bottom:7px;"></div>
                  <div style="font-size:8px; margin-bottom:3px;"><strong>Term 3</strong></div>
                  <div style="border-bottom:1px solid #000; min-height:32px; margin-bottom:4px;"></div>
                </div>

                <!-- Certificate of Transfer -->
                <div style="border-bottom:1px solid #000; padding:5px 7px;">
                  <div style="font-size:8px; font-weight:bold; text-align:center; border-bottom:1px solid #000; margin-bottom:5px; padding-bottom:3px;">CERTIFICATE OF TRANSFER</div>
                  <div style="font-size:8px; line-height:1.6;">This is to certify that the above-named learner has satisfactorily completed the requirements for the grade level indicated.</div>
                  <div style="margin-top:6px; font-size:8px;">
                    Admitted to Grade: <span style="border-bottom:1px solid #000; display:inline-block; width:60px;">&nbsp;</span>
                  </div>
                  <div style="font-size:8px; margin-top:4px;">Eligible for Admission to Grade: <span style="border-bottom:1px solid #000; display:inline-block; width:40px;">&nbsp;</span></div>
                  <div style="text-align:center; margin-top:18px; font-size:8px;">
                    <div style="border-bottom:1px solid #000; padding-bottom:18px; font-weight:bold;">NELSON A. IMACULATA JR.</div>
                    <div>School Head</div>
                  </div>
                </div>

                <!-- Cancellation of Eligibility to Transfer -->
                <div style="padding:5px 7px;">
                  <div style="font-size:8px; font-weight:bold; text-align:center; border-bottom:1px solid #000; margin-bottom:5px; padding-bottom:3px;">CANCELLATION OF ELIGIBILITY TO TRANSFER</div>
                  <div style="display:flex; gap:12px; font-size:8px; margin-top:4px;">
                    <span>Admitted in: <span style="border-bottom:1px solid #000; display:inline-block; width:60px;">&nbsp;</span></span>
                    <span>Date: <span style="border-bottom:1px solid #000; display:inline-block; width:60px;">&nbsp;</span></span>
                  </div>
                  <div style="text-align:center; margin-top:18px; font-size:8px;">
                    <div style="border-bottom:1px solid #000; padding-bottom:18px; font-weight:bold;">NELSON A. IMACULATA JR.</div>
                    <div>School Head</div>
                  </div>
                </div>

              </div><!-- end right panel -->
            </div><!-- end two-column grid -->
          </template>

        </div><!-- end sf9-card -->
      </template>

      <!-- ── ADM TAB ─────────────────────────────────────────────────────── -->
      <template v-else-if="activeTab === 'adm'">
        <MaterialsList type="adm" :section="saved.section" title="Alternative Delivery Modules" />
      </template>

      <!-- ── LESSON GUIDES TAB ───────────────────────────────────────────── -->
      <template v-else-if="activeTab === 'lesson_guide'">
        <MaterialsList type="lesson_guide" :section="saved.section" title="Lesson Guides" />
      </template>

      <!-- ── REVIEWERS TAB ───────────────────────────────────────────────── -->
      <template v-else-if="activeTab === 'reviewer'">
        <MaterialsList type="reviewer" :section="saved.section" title="Reviewers" />
      </template>

    </main>
  </div>
</template>

<style>
@media print {
  .no-print { display: none !important; }
  body { background: white !important; margin: 0 !important; padding: 0 !important; }
  #sf9-card {
    max-width: 100% !important;
    margin: 0 !important;
    border: 2px solid #000 !important;
    box-shadow: none !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  /* keep the two-column grid visible in print */
  #sf9-card [style*="grid-template-columns:1fr 1fr"] {
    display: grid !important;
    grid-template-columns: 1fr 1fr !important;
  }
}
</style>
