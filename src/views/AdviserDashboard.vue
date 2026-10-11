<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase.js'

const loading = ref(true)
const errorMessage = ref('')
const currentUserEmail = ref('')
const mySection = ref(null)
const students = ref([])

// Split students into Male and Female arrays
const maleStudents = computed(() => students.value.filter(s => s.sex === 'M'))
const femaleStudents = computed(() => students.value.filter(s => s.sex === 'F'))

// Form states
const newStudent = ref({ lrn: '', name: '', sex: 'M', birthday: '', grade_level: '' })
const editingId = ref(null)
const editForm = ref({})

// Tab state
const activeTab = ref('roster')

// ─── Comments state ──────────────────────────────────────────
const TERMS = ['term 1', 'term 2', 'term 3']
const TERM_LABELS = { 'term 1': 'Term 1', 'term 2': 'Term 2', 'term 3': 'Term 3' }

// Suggested comments from SF9 (per term, per performance band)
const SUGGESTED_COMMENTS = {
  'term 1': [
    { band: '90–100 | Excellent', items: [
      'Demonstrates excellent academic performance and consistent effort.',
      'Shows strong mastery of the competencies and participates actively in class.',
      'Consistently produces high-quality work and completes tasks responsibly.',
      'Demonstrates excellent study habits and a positive attitude toward learning.',
      'Shows initiative, confidence, and commitment to achieving learning goals.',
    ]},
    { band: '85–89 | Very Good', items: [
      'Demonstrates very good academic performance and consistent effort.',
      'Shows good mastery of the competencies and participates actively in learning activities.',
      'Consistently completes assigned tasks and demonstrates responsibility.',
      'Shows a positive attitude toward learning and continues to make good progress.',
    ]},
    { band: '80–84 | Good', items: [
      'Demonstrates good academic performance and satisfactory progress.',
      'Shows adequate understanding of the competencies and learning tasks.',
      'Shows willingness to learn and improve academic performance.',
      'Demonstrates good potential and is encouraged to participate more actively.',
    ]},
    { band: '75–79 | Satisfactory', items: [
      'Demonstrates satisfactory progress toward the expected learning competencies.',
      'Completes learning tasks but needs more consistent effort.',
      'Shows basic understanding of the lessons and is encouraged to participate more.',
      'Needs to strengthen study habits and maintain regular participation.',
    ]},
    { band: 'Below 75 | Needs Improvement', items: [
      'Needs improvement in meeting the expected learning competencies.',
      'Requires more consistent effort and participation in learning activities.',
      'Is encouraged to review lessons regularly and complete assigned tasks.',
      'Needs additional practice to strengthen understanding of key concepts.',
    ]},
  ],
  'term 2': [
    { band: '90–100 | Excellent', items: [
      'Sustains excellent academic performance and demonstrates strong commitment to learning.',
      'Continues to demonstrate mastery of the expected competencies.',
      'Shows excellent participation, responsibility, and consistency in learning tasks.',
      'Demonstrates strong independent learning skills and initiative.',
    ]},
    { band: '85–89 | Very Good', items: [
      'Continues to demonstrate very good academic performance and progress.',
      'Shows strong understanding of the competencies and applies learning effectively.',
      'Demonstrates consistent effort and responsible completion of learning tasks.',
      'Shows very good progress and continues to develop effective learning habits.',
    ]},
    { band: '80–84 | Good', items: [
      'Demonstrates good progress and continues to develop mastery of the competencies.',
      'Shows consistent effort in completing learning activities.',
      'Demonstrates good understanding of the lessons and learning tasks.',
      'Shows improvement in academic performance and learning habits.',
    ]},
    { band: '75–79 | Satisfactory', items: [
      'Shows satisfactory progress but needs greater consistency in academic tasks.',
      'Demonstrates basic understanding and is encouraged to strengthen key competencies.',
      'Needs to improve study habits and regular participation in class.',
      'Is encouraged to complete all learning activities and assignments consistently.',
    ]},
    { band: 'Below 75 | Needs Improvement', items: [
      'Needs continued improvement in achieving the expected learning competencies.',
      'Requires additional practice and support to strengthen understanding of lessons.',
      'Needs to improve consistency in completing learning activities and assignments.',
      'Is encouraged to develop regular study routines and review lessons at home.',
    ]},
  ],
  'term 3': [
    { band: '90–100 | Excellent', items: [
      'Demonstrates excellent achievement and sustained commitment to learning.',
      'Consistently demonstrates mastery of the expected learning competencies.',
      'Shows outstanding performance, responsibility, and active participation.',
      'Demonstrates excellent application of knowledge and skills.',
    ]},
    { band: '85–89 | Very Good', items: [
      'Demonstrates very good achievement and consistent academic effort.',
      'Shows strong understanding of the competencies and learning concepts.',
      'Continues to perform well and demonstrates responsible learning habits.',
      'Demonstrates very good progress and a willingness to improve.',
    ]},
    { band: '80–84 | Good', items: [
      'Demonstrates good achievement and satisfactory mastery of the competencies.',
      'Shows steady progress and continues to develop academic skills.',
      'Demonstrates good understanding of the lessons and learning activities.',
      'Finishes the term with good performance and is encouraged to aim higher.',
    ]},
    { band: '75–79 | Satisfactory', items: [
      'Demonstrates satisfactory achievement but needs continued improvement.',
      'Shows basic mastery of the competencies and requires additional practice.',
      'Demonstrates progress but needs greater consistency in completing learning tasks.',
      'Needs continued focus and perseverance to achieve better results.',
    ]},
    { band: 'Below 75 | Needs Improvement', items: [
      'Needs continued support to meet the expected learning competencies.',
      'Requires additional practice and focused effort to improve academic performance.',
      'Needs to strengthen understanding of essential concepts and skills.',
      'Requires greater participation and attention during learning activities.',
    ]},
  ],
}

const commentSchoolYear = ref('2026-2027')
const selectedCommentTerm = ref('term 1')
// commentsMap[lrn] = comment string
const commentsMap = ref({})
const commentSaving = ref({})
const commentError = ref('')
// LRN of the student whose textarea is currently focused — used to apply suggested comments
const focusedCommentLrn = ref(null)

async function fetchCommentsData() {
  if (!mySection.value) return
  commentError.value = ''
  const { data, error } = await supabase
    .from('term_comments')
    .select('lrn, term, comment')
    .eq('section', mySection.value)
    .eq('school_year', commentSchoolYear.value)
    .eq('term', selectedCommentTerm.value)

  if (error) { commentError.value = `Failed to load comments: ${error.message}`; return }
  const cm = {}
  ;(data || []).forEach(r => { cm[r.lrn] = r.comment })
  commentsMap.value = cm
}

async function saveComment(lrn, rawValue) {
  const comment = (rawValue || '').trim()
  commentsMap.value[lrn] = comment
  commentSaving.value[lrn] = true
  const { error } = await supabase
    .from('term_comments')
    .upsert(
      { lrn, section: mySection.value, school_year: commentSchoolYear.value, term: selectedCommentTerm.value, comment },
      { onConflict: 'lrn,school_year,term' }
    )
  commentSaving.value[lrn] = false
  if (error) commentError.value = `Save failed: ${error.message}`
}

function insertSuggestedComment(lrn, text) {
  commentsMap.value[lrn] = text
}

// Apply a suggested comment to the currently-focused student's textarea and save immediately
async function applySuggestion(text) {
  if (!focusedCommentLrn.value) return
  const lrn = focusedCommentLrn.value
  commentsMap.value[lrn] = text
  await saveComment(lrn, text)
}

// ─── Attendance state ────────────────────────────────────────
const MONTHS = ['JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR']
const schoolYear = ref('2026-2027')
// classDays[month] = total school days entered by adviser
const classDays = ref({})
// attendanceMap[lrn][month] = days present
const attendanceMap = ref({})
// save indicator: key = 'lrn:month' or 'class:month'
const saving = ref({})
// attendance error
const attendanceError = ref('')

onMounted(async () => {
  await initializeAdviserData()
})

async function initializeAdviserData() {
  loading.value = true
  errorMessage.value = ''
  try {
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) throw new Error('Not authenticated. Please log in.')
    currentUserEmail.value = user.email

    const { data: sectionData, error: sectionError } = await supabase
      .from('adviser_sections')
      .select('section')
      .eq('teacher_email', currentUserEmail.value)
      .single()
      
    if (sectionError) throw new Error('No advisory section assigned to your account.')
    mySection.value = sectionData.section

    await fetchStudents()
    await fetchAttendanceData()
    await fetchCommentsData()
  } catch (err) {
    errorMessage.value = err.message
  } finally {
    loading.value = false
  }
}

async function fetchStudents() {
  if (!mySection.value) return
  const { data, error } = await supabase
    .from('students')
    .select('*')
    .eq('section', mySection.value)
    .order('name')
  
  if (error) errorMessage.value = `Failed to load students: ${error.message}`
  else students.value = data || []
}

async function fetchAttendanceData() {
  if (!mySection.value) return
  attendanceError.value = ''

  // Fetch class_days for section + schoolYear
  const { data: cdRows, error: cdErr } = await supabase
    .from('class_days')
    .select('month, total_days')
    .eq('section', mySection.value)
    .eq('school_year', schoolYear.value)

  if (cdErr) {
    attendanceError.value = `Failed to load class days: ${cdErr.message}`
    return
  }

  const cd = {}
  ;(cdRows || []).forEach(r => { cd[r.month] = r.total_days })
  classDays.value = cd

  // Fetch attendance_records for section + schoolYear
  const { data: arRows, error: arErr } = await supabase
    .from('attendance_records')
    .select('lrn, month, days_present')
    .eq('section', mySection.value)
    .eq('school_year', schoolYear.value)

  if (arErr) {
    attendanceError.value = `Failed to load attendance: ${arErr.message}`
    return
  }

  const am = {}
  ;(arRows || []).forEach(r => {
    if (!am[r.lrn]) am[r.lrn] = {}
    am[r.lrn][r.month] = r.days_present
  })
  attendanceMap.value = am
}

async function saveClassDays(month, rawValue) {
  const value = parseInt(rawValue, 10) || 0
  classDays.value[month] = value
  const key = `class:${month}`
  saving.value[key] = true

  const { error } = await supabase
    .from('class_days')
    .upsert(
      { section: mySection.value, school_year: schoolYear.value, month, total_days: value },
      { onConflict: 'section,school_year,month' }
    )

  saving.value[key] = false
  if (error) attendanceError.value = `Save failed: ${error.message}`
}

async function saveAttendance(lrn, month, rawValue) {
  const value = Math.max(0, parseInt(rawValue, 10) || 0)
  if (!attendanceMap.value[lrn]) attendanceMap.value[lrn] = {}
  attendanceMap.value[lrn][month] = value
  const key = `${lrn}:${month}`
  saving.value[key] = true

  const { error } = await supabase
    .from('attendance_records')
    .upsert(
      { lrn, section: mySection.value, school_year: schoolYear.value, month, days_present: value },
      { onConflict: 'lrn,school_year,month' }
    )

  saving.value[key] = false
  if (error) attendanceError.value = `Save failed: ${error.message}`
}

function getDaysPresent(lrn, month) {
  return attendanceMap.value[lrn]?.[month] ?? 0
}

function getDaysAbsent(lrn, month) {
  const total = classDays.value[month] ?? 0
  const present = getDaysPresent(lrn, month)
  return Math.max(0, total - present)
}

function getTotalPresent(lrn) {
  return MONTHS.reduce((sum, m) => sum + (attendanceMap.value[lrn]?.[m] ?? 0), 0)
}

function getTotalAbsent(lrn) {
  return MONTHS.reduce((sum, m) => sum + getDaysAbsent(lrn, m), 0)
}

function getTotalClassDays() {
  return MONTHS.reduce((sum, m) => sum + (classDays.value[m] ?? 0), 0)
}

// ─── Roster helpers ───────────────────────────────────────────
async function addStudent() {
  if (!newStudent.value.lrn || !newStudent.value.name) return
  
  const payload = { ...newStudent.value, section: mySection.value }
  const { error } = await supabase.from('students').insert([payload])
  
  if (error) {
    errorMessage.value = `Add failed: ${error.message}`
  } else {
    newStudent.value = { lrn: '', name: '', sex: 'M', birthday: '', grade_level: '' }
    fetchStudents()
  }
}

async function deleteStudent(id, name) {
  if (!confirm(`Permanently delete ${name}?`)) return
  const { error } = await supabase.from('students').delete().eq('id', id)
  if (error) errorMessage.value = `Delete failed: ${error.message}`
  else fetchStudents()
}

function startEdit(student) {
  editingId.value = student.id
  editForm.value = { ...student }
}

function cancelEdit() {
  editingId.value = null
  editForm.value = {}
}

async function saveEdit() {
  const { error } = await supabase
    .from('students')
    .update({
      lrn: editForm.value.lrn,
      name: editForm.value.name,
      sex: editForm.value.sex,
      birthday: editForm.value.birthday,
      grade_level: editForm.value.grade_level
    })
    .eq('id', editingId.value)

  if (error) {
    errorMessage.value = `Update failed: ${error.message}`
  } else {
    editingId.value = null
    fetchStudents()
  }
}

// ── Print Card (SF9) ──────────────────────────────────────────────────────
const printingStudent = ref(null)
const printCardGrades = ref([])
const printCardComments = ref({})
const printCardAttendance = ref({})
const printCardClassDays = ref({})
const printCardAdviser = ref('')
const printCardLoading = ref(false)

const SUBJECTS_SF9 = [
  { key: 'Filipino',    label: 'Filipino',                       sub: false },
  { key: 'English',     label: 'English',                        sub: false },
  { key: 'Mathematics', label: 'Mathematics',                    sub: false },
  { key: 'Science',     label: 'Science',                        sub: false },
  { key: 'AP',          label: 'Araling Panlipunan (AP)',         sub: false },
  { key: 'ValuesEd',    label: 'GMRC / Values Education',         sub: false },
  { key: 'TLE',         label: 'EPP/TLE',                        sub: false },
  { key: 'MAPEH',       label: 'MAPEH',                           sub: false, composite: true },
  { key: 'MA',          label: '  Music and Arts',                sub: true  },
  { key: 'PEH',         label: '  Physical Education and Health', sub: true  },
  { key: 'SPFL',        label: 'SPFL (Korean)',                   sub: false },
]

const SF9_MONTHS = ['Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar','Apr']
const SF9_MONTH_KEYS = ['JUN','JUL','AUG','SEP','OCT','NOV','DEC','JAN','FEB','MAR','APR']

function gradeVal(lrn, subject, term) {
  const g = printCardGrades.value.find(
    r => String(r.lrn).trim() === String(lrn).trim()
      && r.subject === subject
      && String(r.term).toLowerCase().trim() === term
  )
  return g ? g.grade : ''
}

function subjectAvg(lrn, subject) {
  if (subject === 'MAPEH') {
    const maAvg = subjectAvg(lrn, 'MA')
    const pehAvg = subjectAvg(lrn, 'PEH')
    const vals = [maAvg, pehAvg].map(Number).filter(v => v > 0)
    if (!vals.length) return ''
    return (vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(0)
  }
  const vals = ['term 1','term 2','term 3'].map(t => Number(gradeVal(lrn, subject, t))).filter(v => v > 0)
  if (!vals.length) return ''
  return (vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(0)
}

function finalAvg(lrn) {
  const forAvg = SUBJECTS_SF9.filter(s => !s.sub)
  const avgs = forAvg.map(s => Number(subjectAvg(lrn, s.key))).filter(v => v > 0)
  if (!avgs.length) return ''
  return (avgs.reduce((a, b) => a + b, 0) / avgs.length).toFixed(0)
}

function gradeRemarks(avg) {
  const n = Number(avg)
  if (!n) return ''
  return n >= 75 ? 'Passed' : 'Failed'
}

function finalRemarks(avg) {
  const n = Number(avg)
  if (!n) return ''
  return n >= 75 ? 'PROMOTED' : 'RETAINED'
}

function ageFrom(birthday) {
  if (!birthday) return ''
  const diff = Date.now() - new Date(birthday).getTime()
  return Math.floor(diff / (1000 * 60 * 60 * 24 * 365.25))
}

function pcPresent(month) { return printCardAttendance.value[month] ?? 0 }
function pcDays(month)    { return printCardClassDays.value[month] ?? 0 }
function pcAbsent(month)  { return Math.max(0, pcDays(month) - pcPresent(month)) }
function pcTotalPresent() { return SF9_MONTH_KEYS.reduce((s, m) => s + pcPresent(m), 0) }
function pcTotalAbsent()  { return SF9_MONTH_KEYS.reduce((s, m) => s + pcAbsent(m), 0) }
function pcTotalDays()    { return SF9_MONTH_KEYS.reduce((s, m) => s + pcDays(m), 0) }

async function openPrintCard(student) {
  printCardLoading.value = true
  printingStudent.value = student
  printCardGrades.value = []
  printCardComments.value = {}
  printCardAttendance.value = {}
  printCardClassDays.value = {}

  const [gradeRes, commentRes, attendRes, classDayRes, tRow] = await Promise.all([
    supabase.from('grades').select('*').eq('lrn', student.lrn),
    supabase.from('term_comments').select('term,comment').eq('lrn', student.lrn).eq('school_year', '2026-2027'),
    supabase.from('attendance_records').select('month,days_present').eq('lrn', student.lrn).eq('school_year', '2026-2027'),
    supabase.from('class_days').select('month,total_days').eq('section', mySection.value).eq('school_year', '2026-2027'),
    supabase.from('teachers').select('name').eq('email', currentUserEmail.value).maybeSingle(),
  ])

  printCardGrades.value = gradeRes.data || []

  const cm = {}
  ;(commentRes.data || []).forEach(r => { cm[r.term] = r.comment })
  printCardComments.value = cm

  const am = {}
  ;(attendRes.data || []).forEach(r => { am[r.month] = r.days_present })
  printCardAttendance.value = am

  const cd = {}
  ;(classDayRes.data || []).forEach(r => { cd[r.month] = r.total_days })
  printCardClassDays.value = cd

  printCardAdviser.value = tRow.data?.name || currentUserEmail.value

  printCardLoading.value = false
}

function printCard() {
  const el = document.getElementById('sf9-print-area')
  if (!el) return
  const win = window.open('', '_blank', 'width=1100,height=820')
  win.document.write(`<!DOCTYPE html><html><head>
    <base href="${window.location.origin}/">
    <title>SF9 – ${printingStudent.value?.name}</title>
    <style>
      @page { size: A4 landscape; margin: 8mm; }
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body { font-family: "Bookman Old Style", Georgia, serif; font-size: 9pt; color: #000; background: #fff; }
      table { border-collapse: collapse; width: 100%; }
      td, th { border: 1px solid #000; padding: 2px 4px; vertical-align: middle; }
      .nb { border: none !important; }
      .center { text-align: center; }
      .right  { text-align: right; }
      .bold   { font-weight: bold; }
      .dark-hdr { background: #002060; color: #fff; font-weight: bold; text-align: center; }
      .two-col { display: flex; gap: 6px; }
      .col-l  { flex: 0 0 52%; }
      .col-r  { flex: 1; }
      .bt2    { border-top: 2px solid #000; }
      .bb2    { border-bottom: 2px solid #000; }
      .bl2    { border-left: 2px solid #000; }
      .br2    { border-right: 2px solid #000; }
    </style>
  </head><body>${el.innerHTML}</body></html>`)
  win.document.close()
  win.focus()
  setTimeout(() => { win.print(); win.close() }, 500)
}
</script>

<template>
  <div class="max-w-screen-2xl mx-auto p-6 space-y-6">
    <!-- Header -->
    <div class="border-b pb-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-slate-800">My Advisory Section</h1>
        <p v-if="mySection" class="text-sm text-slate-600 mt-1">
          Currently managing <span class="font-bold text-blue-600">{{ mySection }}</span> | {{ students.length }} Students
        </p>
      </div>
      <div class="flex flex-col sm:flex-row gap-3">
        <router-link to="/term-grade" class="inline-flex items-center justify-center bg-emerald-600 hover:bg-emerald-700 text-white text-xs sm:text-sm font-semibold px-4 py-2.5 rounded-lg transition-colors shadow-sm">
          View Term Grades Summary &rarr;
        </router-link>
        <router-link to="/teacher" class="inline-flex items-center justify-center bg-indigo-600 hover:bg-indigo-700 text-white text-xs sm:text-sm font-semibold px-4 py-2.5 rounded-lg transition-colors shadow-sm">
          TEACHER DASHBOARD &rarr;
        </router-link>
      </div>
    </div>

    <!-- Tab Switcher -->
    <div v-if="!loading && mySection" class="flex bg-slate-100 p-1 rounded-lg self-start w-fit">
      <button
        @click="activeTab = 'roster'"
        :class="['px-5 py-2 rounded-md text-sm font-semibold transition-colors', activeTab === 'roster' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-800']"
      >
        📋 Student Roster
      </button>
      <button
        @click="activeTab = 'attendance'"
        :class="['px-5 py-2 rounded-md text-sm font-semibold transition-colors', activeTab === 'attendance' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-800']"
      >
        📅 Attendance Records
      </button>
      <button
        @click="activeTab = 'comments'; fetchCommentsData()"
        :class="['px-5 py-2 rounded-md text-sm font-semibold transition-colors', activeTab === 'comments' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-800']"
      >
        💬 Teacher's Comments
      </button>
    </div>

    <div v-if="loading" class="text-slate-500">Loading advisory data...</div>
    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{{ errorMessage }}</div>

    <!-- ══════════════════════════════ ROSTER TAB ══════════════════════════════ -->
    <template v-if="!loading && mySection && activeTab === 'roster'">
      <!-- Toolbar: Add Student -->
      <div class="bg-white p-4 border border-slate-200 rounded-lg shadow-sm flex flex-col xl:flex-row gap-4 items-center justify-between">
        <div class="flex flex-wrap items-center gap-2 w-full xl:w-auto">
          <span class="font-bold text-sm text-slate-700 mr-2">Add Student:</span>
          <input v-model="newStudent.lrn" placeholder="New LRN" class="p-2 border rounded text-xs w-32" />
          <input v-model="newStudent.name" placeholder="Full Name" class="p-2 border rounded text-xs w-48" />
          <select v-model="newStudent.sex" class="p-2 border rounded text-xs">
            <option value="M">M (Male)</option>
            <option value="F">F (Female)</option>
          </select>
          <input v-model="newStudent.birthday" type="date" class="p-2 border rounded text-xs w-36" />
          <select v-model="newStudent.grade_level" class="p-2 border rounded text-xs">
            <option value="">Grade</option>
            <option value="7">Grade 7</option>
            <option value="8">Grade 8</option>
            <option value="9">Grade 9</option>
            <option value="10">Grade 10</option>
            <option value="11">Grade 11</option>
            <option value="12">Grade 12</option>
          </select>
          <button @click="addStudent" class="bg-blue-600 text-white px-4 py-2 rounded text-xs hover:bg-blue-700 font-bold shadow-sm">
            Add +
          </button>
        </div>
      </div>

      <!-- Side-by-Side Tables -->
      <div class="grid grid-cols-1 xl:grid-cols-2 gap-8 items-start">
        
        <!-- MALE TABLE -->
        <div class="bg-white border border-slate-300 shadow-sm overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-max">
            <thead>
              <tr class="bg-[#002060] text-white text-xs font-bold uppercase tracking-wide">
                <th class="p-2 w-10 text-center border border-slate-400">#</th>
                <th class="p-2 border border-slate-400 w-48">MALE</th>
                <th class="p-2 text-center border border-slate-400 w-28">LRN</th>
                <th class="p-2 text-center border border-slate-400 w-16">GRADE</th>
                <th class="p-2 text-center border border-slate-400 w-28">BIRTHDATE</th>
                <th class="p-2 text-center border border-slate-400 w-32 bg-[#001848]">ACTIONS</th>
              </tr>
            </thead>
            <tbody class="text-sm divide-y divide-slate-200 bg-white">
              <tr v-for="(s, index) in maleStudents" :key="s.id" class="hover:bg-slate-50 border-b border-slate-200">
                <td class="p-2 text-center font-bold text-slate-500 border border-slate-300">{{ index + 1 }}</td>
                
                <template v-if="editingId !== s.id">
                  <td class="p-2 font-bold text-slate-800 border border-slate-300">{{ s.name }}</td>
                  <td class="p-2 text-center font-mono text-xs text-slate-700 border border-slate-300">{{ s.lrn }}</td>
                  <td class="p-2 text-center text-xs font-bold text-slate-700 border border-slate-300">{{ s.grade_level ? `G${s.grade_level}` : '-' }}</td>
                  <td class="p-2 text-center text-xs text-slate-700 border border-slate-300">{{ s.birthday || '-' }}</td>
                  <td class="p-2 text-center space-x-2 border border-slate-300">
                    <button @click="startEdit(s)" class="text-blue-600 text-xs hover:underline font-bold">Edit</button>
                    <button @click="deleteStudent(s.id, s.name)" class="text-red-600 text-xs hover:underline font-bold">Del</button>
                    <button @click="openPrintCard(s)" class="text-emerald-600 text-xs hover:underline font-bold">Print Card</button>
                  </td>
                </template>

                <template v-else>
                  <td class="p-1 border border-slate-300">
                    <div class="flex flex-col gap-1">
                      <input v-model="editForm.name" class="w-full p-1 border rounded text-xs border-emerald-400" placeholder="Name" />
                      <select v-model="editForm.sex" class="w-full p-1 border rounded text-xs border-emerald-400">
                        <option value="M">M (Male)</option>
                        <option value="F">F (Female)</option>
                      </select>
                    </div>
                  </td>
                  <td class="p-1 border border-slate-300"><input v-model="editForm.lrn" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                  <td class="p-1 border border-slate-300">
                    <select v-model="editForm.grade_level" class="w-full p-1 border rounded text-xs border-emerald-400">
                      <option value="">—</option>
                      <option value="7">Grade 7</option>
                      <option value="8">Grade 8</option>
                      <option value="9">Grade 9</option>
                      <option value="10">Grade 10</option>
                      <option value="11">Grade 11</option>
                      <option value="12">Grade 12</option>
                    </select>
                  </td>
                  <td class="p-1 border border-slate-300"><input v-model="editForm.birthday" type="date" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                  <td class="p-1 text-center space-x-1 border border-slate-300">
                    <button @click="saveEdit" class="bg-emerald-600 text-white px-2 py-1 rounded text-xs hover:bg-emerald-700">Save</button>
                    <button @click="cancelEdit" class="bg-slate-200 text-slate-700 px-2 py-1 rounded text-xs hover:bg-slate-300">Cancel</button>
                  </td>
                </template>
              </tr>
              <tr v-if="maleStudents.length === 0">
                <td colspan="6" class="p-4 text-center text-slate-400 text-xs font-medium border border-slate-300">No Male students recorded.</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- FEMALE TABLE -->
        <div class="bg-white border border-slate-300 shadow-sm overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-max">
            <thead>
              <tr class="bg-[#002060] text-white text-xs font-bold uppercase tracking-wide">
                <th class="p-2 w-10 text-center border border-slate-400">#</th>
                <th class="p-2 border border-slate-400 w-48">FEMALE</th>
                <th class="p-2 text-center border border-slate-400 w-28">LRN</th>
                <th class="p-2 text-center border border-slate-400 w-16">GRADE</th>
                <th class="p-2 text-center border border-slate-400 w-28">BIRTHDATE</th>
                <th class="p-2 text-center border border-slate-400 w-32 bg-[#001848]">ACTIONS</th>
              </tr>
            </thead>
            <tbody class="text-sm divide-y divide-slate-200 bg-white">
              <tr v-for="(s, index) in femaleStudents" :key="s.id" class="hover:bg-slate-50 border-b border-slate-200">
                <td class="p-2 text-center font-bold text-slate-500 border border-slate-300">{{ index + 1 }}</td>
                
                <template v-if="editingId !== s.id">
                  <td class="p-2 font-bold text-slate-800 border border-slate-300">{{ s.name }}</td>
                  <td class="p-2 text-center font-mono text-xs text-slate-700 border border-slate-300">{{ s.lrn }}</td>
                  <td class="p-2 text-center text-xs font-bold text-slate-700 border border-slate-300">{{ s.grade_level ? `G${s.grade_level}` : '-' }}</td>
                  <td class="p-2 text-center text-xs text-slate-700 border border-slate-300">{{ s.birthday || '-' }}</td>
                  <td class="p-2 text-center space-x-2 border border-slate-300">
                    <button @click="startEdit(s)" class="text-blue-600 text-xs hover:underline font-bold">Edit</button>
                    <button @click="deleteStudent(s.id, s.name)" class="text-red-600 text-xs hover:underline font-bold">Del</button>
                    <button @click="openPrintCard(s)" class="text-emerald-600 text-xs hover:underline font-bold">Print Card</button>
                  </td>
                </template>

                <template v-else>
                  <td class="p-1 border border-slate-300">
                    <div class="flex flex-col gap-1">
                      <input v-model="editForm.name" class="w-full p-1 border rounded text-xs border-emerald-400" placeholder="Name" />
                      <select v-model="editForm.sex" class="w-full p-1 border rounded text-xs border-emerald-400">
                        <option value="M">M (Male)</option>
                        <option value="F">F (Female)</option>
                      </select>
                    </div>
                  </td>
                  <td class="p-1 border border-slate-300"><input v-model="editForm.lrn" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                  <td class="p-1 border border-slate-300">
                    <select v-model="editForm.grade_level" class="w-full p-1 border rounded text-xs border-emerald-400">
                      <option value="">—</option>
                      <option value="7">Grade 7</option>
                      <option value="8">Grade 8</option>
                      <option value="9">Grade 9</option>
                      <option value="10">Grade 10</option>
                      <option value="11">Grade 11</option>
                      <option value="12">Grade 12</option>
                    </select>
                  </td>
                  <td class="p-1 border border-slate-300"><input v-model="editForm.birthday" type="date" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                  <td class="p-1 text-center space-x-1 border border-slate-300">
                    <button @click="saveEdit" class="bg-emerald-600 text-white px-2 py-1 rounded text-xs hover:bg-emerald-700">Save</button>
                    <button @click="cancelEdit" class="bg-slate-200 text-slate-700 px-2 py-1 rounded text-xs hover:bg-slate-300">Cancel</button>
                  </td>
                </template>
              </tr>
              <tr v-if="femaleStudents.length === 0">
                <td colspan="6" class="p-4 text-center text-slate-400 text-xs font-medium border border-slate-300">No Female students recorded.</td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>
    </template>

    <!-- ══════════════════════════════ ATTENDANCE TAB ══════════════════════════ -->
    <template v-if="!loading && mySection && activeTab === 'attendance'">

      <!-- Attendance toolbar: school year selector -->
      <div class="bg-white p-4 border border-slate-200 rounded-lg shadow-sm flex flex-wrap items-center gap-4">
        <label class="text-sm font-bold text-slate-700">School Year:</label>
        <select
          v-model="schoolYear"
          @change="fetchAttendanceData"
          class="p-2 border rounded text-sm"
        >
          <option>2024-2025</option>
          <option>2025-2026</option>
          <option>2026-2027</option>
          <option>2027-2028</option>
        </select>
        <span class="text-xs text-slate-500">Changes are saved automatically on blur.</span>
        <span v-if="attendanceError" class="text-xs text-red-600 font-medium">{{ attendanceError }}</span>
      </div>

      <!-- Attendance Grid -->
      <div class="bg-white border border-slate-300 shadow-sm overflow-x-auto">
        <table class="border-collapse text-xs" style="min-width: max-content;">
          <!-- ── Header ── -->
          <thead>
            <tr class="bg-[#002060] text-white font-bold uppercase tracking-wide">
              <th class="p-2 border border-slate-500 text-center w-8">#</th>
              <th class="p-2 border border-slate-500 text-left w-52">LEARNER'S NAME</th>
              <th v-for="m in MONTHS" :key="m" class="p-2 border border-slate-500 text-center w-16">{{ m }}</th>
              <th class="p-2 border border-slate-500 text-center w-16 bg-[#001848]">TOTAL<br>PRESENT</th>
              <th class="p-2 border border-slate-500 text-center w-16 bg-[#001848]">TOTAL<br>ABSENT</th>
            </tr>
          </thead>

          <tbody>
            <!-- ── Class Days row ── -->
            <tr class="bg-slate-100">
              <td class="p-1 border border-slate-400 text-center font-bold text-slate-500"></td>
              <td class="p-2 border border-slate-400 font-bold text-slate-700 text-right pr-3">No. of Class Days</td>
              <td v-for="m in MONTHS" :key="m" class="p-1 border border-slate-400 text-center">
                <div class="relative">
                  <input
                    type="number"
                    min="0"
                    max="31"
                    :value="classDays[m] ?? 0"
                    @blur="saveClassDays(m, $event.target.value)"
                    class="w-14 text-center border border-slate-300 rounded p-1 font-bold text-slate-800 bg-white focus:border-blue-400 focus:outline-none"
                  />
                  <span v-if="saving[`class:${m}`]" class="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
                </div>
              </td>
              <td class="p-2 border border-slate-400 text-center font-bold text-slate-700">{{ getTotalClassDays() }}</td>
              <td class="p-2 border border-slate-400"></td>
            </tr>

            <!-- ── MALE section divider ── -->
            <tr class="bg-[#002060] text-white">
              <td colspan="14" class="p-1.5 pl-3 border border-slate-500 font-bold text-xs tracking-widest">MALE</td>
            </tr>

            <tr v-for="(s, index) in maleStudents" :key="s.id" class="hover:bg-blue-50/40 border-b border-slate-200">
              <td class="p-2 border border-slate-300 text-center font-bold text-slate-500">{{ index + 1 }}</td>
              <td class="p-2 border border-slate-300 font-bold text-slate-800">{{ s.name }}</td>
              <td v-for="m in MONTHS" :key="m" class="p-1 border border-slate-300 text-center">
                <div class="relative flex flex-col items-center gap-0.5">
                  <input
                    type="number"
                    min="0"
                    :max="classDays[m] ?? 31"
                    :value="getDaysPresent(s.lrn, m)"
                    @blur="saveAttendance(s.lrn, m, $event.target.value)"
                    class="w-14 text-center border border-slate-300 rounded p-1 bg-white focus:border-emerald-400 focus:outline-none"
                    :class="{ 'border-amber-300 bg-amber-50': saving[`${s.lrn}:${m}`] }"
                  />
                  <span class="text-[9px] text-red-500 font-semibold leading-none">Abs: {{ getDaysAbsent(s.lrn, m) }}</span>
                  <span v-if="saving[`${s.lrn}:${m}`]" class="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
                </div>
              </td>
              <td class="p-2 border border-slate-300 text-center font-bold text-emerald-700">{{ getTotalPresent(s.lrn) }}</td>
              <td class="p-2 border border-slate-300 text-center font-bold text-red-600">{{ getTotalAbsent(s.lrn) }}</td>
            </tr>

            <tr v-if="maleStudents.length === 0">
              <td colspan="14" class="p-3 text-center text-slate-400 font-medium border border-slate-300">No Male students recorded.</td>
            </tr>

            <!-- ── FEMALE section divider ── -->
            <tr class="bg-[#002060] text-white">
              <td colspan="14" class="p-1.5 pl-3 border border-slate-500 font-bold text-xs tracking-widest">FEMALE</td>
            </tr>

            <tr v-for="(s, index) in femaleStudents" :key="s.id" class="hover:bg-pink-50/40 border-b border-slate-200">
              <td class="p-2 border border-slate-300 text-center font-bold text-slate-500">{{ index + 1 }}</td>
              <td class="p-2 border border-slate-300 font-bold text-slate-800">{{ s.name }}</td>
              <td v-for="m in MONTHS" :key="m" class="p-1 border border-slate-300 text-center">
                <div class="relative flex flex-col items-center gap-0.5">
                  <input
                    type="number"
                    min="0"
                    :max="classDays[m] ?? 31"
                    :value="getDaysPresent(s.lrn, m)"
                    @blur="saveAttendance(s.lrn, m, $event.target.value)"
                    class="w-14 text-center border border-slate-300 rounded p-1 bg-white focus:border-emerald-400 focus:outline-none"
                    :class="{ 'border-amber-300 bg-amber-50': saving[`${s.lrn}:${m}`] }"
                  />
                  <span class="text-[9px] text-red-500 font-semibold leading-none">Abs: {{ getDaysAbsent(s.lrn, m) }}</span>
                  <span v-if="saving[`${s.lrn}:${m}`]" class="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
                </div>
              </td>
              <td class="p-2 border border-slate-300 text-center font-bold text-emerald-700">{{ getTotalPresent(s.lrn) }}</td>
              <td class="p-2 border border-slate-300 text-center font-bold text-red-600">{{ getTotalAbsent(s.lrn) }}</td>
            </tr>

            <tr v-if="femaleStudents.length === 0">
              <td colspan="14" class="p-3 text-center text-slate-400 font-medium border border-slate-300">No Female students recorded.</td>
            </tr>
          </tbody>
        </table>
      </div>

    </template>

    <!-- ══════════════════════════════ COMMENTS TAB ══════════════════════════ -->
    <template v-if="!loading && mySection && activeTab === 'comments'">

      <!-- Toolbar -->
      <div class="bg-white p-4 border border-slate-200 rounded-lg shadow-sm flex flex-wrap items-center gap-4">
        <label class="text-sm font-bold text-slate-700">School Year:</label>
        <select v-model="commentSchoolYear" @change="fetchCommentsData" class="p-2 border rounded text-sm">
          <option>2024-2025</option>
          <option>2025-2026</option>
          <option>2026-2027</option>
          <option>2027-2028</option>
        </select>
        <label class="text-sm font-bold text-slate-700 ml-4">Term:</label>
        <div class="flex bg-slate-100 p-1 rounded-lg">
          <button
            v-for="t in TERMS" :key="t"
            @click="selectedCommentTerm = t; fetchCommentsData()"
            :class="['px-4 py-1.5 rounded-md text-xs font-semibold transition-colors capitalize', selectedCommentTerm === t ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-800']"
          >{{ TERM_LABELS[t] }}</button>
        </div>
        <span class="text-xs text-slate-500">Comments are saved automatically on blur.</span>
        <span v-if="commentError" class="text-xs text-red-600 font-medium">{{ commentError }}</span>
      </div>

      <!-- Suggested Comments reference panel -->
      <details class="bg-amber-50 border border-amber-200 rounded-lg text-xs">
        <summary class="p-3 font-semibold text-amber-800 cursor-pointer select-none">
          📋 Suggested Comments for {{ TERM_LABELS[selectedCommentTerm] }} (click to expand — focus a student's text box first, then click a suggestion to apply it)
        </summary>
        <div class="px-4 pb-2 pt-1">
          <div v-if="focusedCommentLrn" class="mb-3 text-[10px] font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded px-3 py-1.5">
            ✏️ Applying to: <span class="font-bold">{{ students.find(s => s.lrn === focusedCommentLrn)?.name || focusedCommentLrn }}</span>
          </div>
          <div v-else class="mb-3 text-[10px] text-slate-500 italic bg-white border border-slate-200 rounded px-3 py-1.5">
            👆 Click inside a student's comment box to select them, then click a suggestion below.
          </div>
        </div>
        <div class="px-4 pb-4 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div v-for="band in SUGGESTED_COMMENTS[selectedCommentTerm]" :key="band.band" class="space-y-1">
            <div class="font-bold text-amber-900 text-[10px] uppercase tracking-wide mb-1">{{ band.band }}</div>
            <button
              v-for="item in band.items" :key="item"
              class="block w-full text-left text-[10px] text-slate-700 bg-white border border-slate-200 rounded px-2 py-1 transition"
              :class="focusedCommentLrn ? 'hover:bg-emerald-50 hover:border-emerald-400 cursor-pointer' : 'opacity-50 cursor-not-allowed'"
              :disabled="!focusedCommentLrn"
              :title="focusedCommentLrn ? 'Click to apply to ' + (students.find(s => s.lrn === focusedCommentLrn)?.name || '') : 'Focus a student first'"
              @mousedown.prevent
              @click="applySuggestion(item)"
            >{{ item }}</button>
          </div>
        </div>
      </details>

      <!-- Comments table: all students in section -->
      <div class="bg-white border border-slate-300 shadow-sm overflow-x-auto rounded-lg">
        <table class="w-full border-collapse text-xs">
          <thead>
            <tr class="bg-[#002060] text-white font-bold uppercase tracking-wide">
              <th class="p-2 border border-slate-500 text-center w-8">#</th>
              <th class="p-2 border border-slate-500 text-left w-52">LEARNER'S NAME</th>
              <th class="p-2 border border-slate-500 text-left">TEACHER'S COMMENT / REMARK — {{ TERM_LABELS[selectedCommentTerm] }}</th>
              <th class="p-2 border border-slate-500 text-center w-16 bg-[#001848]">STATUS</th>
            </tr>
          </thead>
          <tbody>
            <!-- MALE divider -->
            <tr class="bg-[#002060] text-white">
              <td colspan="4" class="p-1.5 pl-3 border border-slate-500 font-bold text-xs tracking-widest">MALE</td>
            </tr>
            <tr v-for="(s, idx) in maleStudents" :key="s.id" class="hover:bg-blue-50/30 border-b border-slate-200" :class="{ 'ring-2 ring-inset ring-emerald-400': focusedCommentLrn === s.lrn }">
              <td class="p-2 border border-slate-300 text-center font-bold text-slate-500">{{ idx + 1 }}</td>
              <td class="p-2 border border-slate-300 font-bold text-slate-800">{{ s.name }}</td>
              <td class="p-1 border border-slate-300">
                <textarea
                  rows="2"
                  :value="commentsMap[s.lrn] ?? ''"
                  @focus="focusedCommentLrn = s.lrn"
                  @blur="saveComment(s.lrn, $event.target.value)"
                  placeholder="Type or paste a comment… (or focus here then click a suggestion above)"
                  class="w-full p-1.5 border border-slate-300 rounded text-[11px] text-slate-800 leading-snug resize-none focus:border-emerald-400 focus:outline-none bg-white"
                  :class="{ 'border-amber-300 bg-amber-50': commentSaving[s.lrn] }"
                ></textarea>
              </td>
              <td class="p-2 border border-slate-300 text-center">
                <span v-if="commentSaving[s.lrn]" class="text-amber-500 text-[10px]">saving…</span>
                <span v-else-if="commentsMap[s.lrn]" class="text-emerald-600 text-[10px] font-bold">✓ saved</span>
                <span v-else class="text-slate-300 text-[10px]">—</span>
              </td>
            </tr>
            <tr v-if="maleStudents.length === 0">
              <td colspan="4" class="p-3 text-center text-slate-400 font-medium border border-slate-300">No Male students recorded.</td>
            </tr>

            <!-- FEMALE divider -->
            <tr class="bg-[#002060] text-white">
              <td colspan="4" class="p-1.5 pl-3 border border-slate-500 font-bold text-xs tracking-widest">FEMALE</td>
            </tr>
            <tr v-for="(s, idx) in femaleStudents" :key="s.id" class="hover:bg-pink-50/30 border-b border-slate-200" :class="{ 'ring-2 ring-inset ring-emerald-400': focusedCommentLrn === s.lrn }">
              <td class="p-2 border border-slate-300 text-center font-bold text-slate-500">{{ idx + 1 }}</td>
              <td class="p-2 border border-slate-300 font-bold text-slate-800">{{ s.name }}</td>
              <td class="p-1 border border-slate-300">
                <textarea
                  rows="2"
                  :value="commentsMap[s.lrn] ?? ''"
                  @focus="focusedCommentLrn = s.lrn"
                  @blur="saveComment(s.lrn, $event.target.value)"
                  placeholder="Type or paste a comment… (or focus here then click a suggestion above)"
                  class="w-full p-1.5 border border-slate-300 rounded text-[11px] text-slate-800 leading-snug resize-none focus:border-emerald-400 focus:outline-none bg-white"
                  :class="{ 'border-amber-300 bg-amber-50': commentSaving[s.lrn] }"
                ></textarea>
              </td>
              <td class="p-2 border border-slate-300 text-center">
                <span v-if="commentSaving[s.lrn]" class="text-amber-500 text-[10px]">saving…</span>
                <span v-else-if="commentsMap[s.lrn]" class="text-emerald-600 text-[10px] font-bold">✓ saved</span>
                <span v-else class="text-slate-300 text-[10px]">—</span>
              </td>
            </tr>
            <tr v-if="femaleStudents.length === 0">
              <td colspan="4" class="p-3 text-center text-slate-400 font-medium border border-slate-300">No Female students recorded.</td>
            </tr>
          </tbody>
        </table>
      </div>

    </template>

  </div>

  <!-- ── STUDENT REPORT CARD (SF9) MODAL ──────────────────────────────── -->
  <div v-if="printingStudent" class="fixed inset-0 bg-black/50 z-50 flex items-start justify-center p-4 overflow-y-auto">
    <div class="bg-white rounded-xl shadow-2xl border w-full max-w-6xl my-6">

      <!-- Modal Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b no-print">
        <h2 class="text-base font-bold text-slate-800">
          SF9 – Learner's Performance Report
          <span class="ml-2 text-sm font-normal text-slate-500">{{ printingStudent.name }}</span>
        </h2>
        <div class="flex gap-2">
          <button @click="printCard" :disabled="printCardLoading"
            class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition">
            <span v-if="printCardLoading">Loading…</span>
            <span v-else>🖨 Print (A4 Landscape)</span>
          </button>
          <button @click="printingStudent = null" class="px-4 py-2 text-sm border rounded-lg hover:bg-slate-50">Close</button>
        </div>
      </div>

      <!-- Loading state -->
      <div v-if="printCardLoading" class="p-10 text-center text-slate-400">Loading data…</div>

      <!-- ══ SF9 Print Area — official two-column A4 landscape layout ══ -->
      <div v-if="!printCardLoading" id="sf9-print-area"
        style="padding:4mm;font-family:'Bookman Old Style',Georgia,serif;font-size:8.5pt;color:#000;background:#fff;line-height:1.2;">

        <!-- Outer border box -->
        <div style="border:2px solid #000;padding:3px;">

          <!-- ── TOP ROW: Left = school header | Right = attendance table ── -->
          <table style="border-collapse:collapse;width:100%;table-layout:fixed;border:none;margin-bottom:2px;">
            <colgroup><col style="width:48%"><col style="width:4%"><col style="width:48%"></colgroup>
            <tr>
              <td style="border:none;padding-right:2px;">
                <div style="display:flex;align-items:center;gap:2px;">
                  <img src="/images/leftlogo.png" alt="DepEd Logo" style="height:58px;width:58px;object-fit:contain;flex-shrink:0;margin-right:4px;" />
                  <div style="flex:1;text-align:center;">
                    <div style="font-size:8.5pt;">Republic of the Philippines</div>
                    <div style="font-size:8.5pt;">Department of Education</div>
                    <div style="font-size:8.5pt;">National Capital Region</div>
                    <div style="font-size:8.5pt;">City Schools Division of Las Pinas</div>
                    <div style="font-size:11pt;font-weight:bold;text-transform:uppercase;margin:1px 0;">LAS PINAS EAST NATIONAL HIGH SCHOOL</div>
                    <div style="font-size:7.5pt;">Kasoy St. Verdant Acres Subd., Pamplona III, Las Pinas City</div>
                  </div>
                  <img src="/images/rightlogo.png" alt="School Logo" style="height:58px;width:58px;object-fit:contain;flex-shrink:0;margin-left:4px;" />
                </div>
              </td>
              <td style="border:none;"></td>
              <!-- Attendance table top-right -->
              <td style="border:2px solid #000;vertical-align:top;padding:2px;">
                <table style="border-collapse:collapse;width:100%;font-size:7pt;table-layout:fixed;">
                  <tr>
                    <td style="border:1px solid #000;padding:1px 2px;font-weight:bold;white-space:nowrap;">Month</td>
                    <td v-for="m in SF9_MONTHS" :key="m" style="border:1px solid #000;padding:1px;text-align:center;font-weight:bold;">{{ m }}</td>
                    <td style="border:1px solid #000;padding:1px;text-align:center;font-weight:bold;">Total</td>
                  </tr>
                  <tr>
                    <td style="border:1px solid #000;padding:1px 2px;font-size:6.5pt;white-space:nowrap;">No. of Class Days</td>
                    <td v-for="k in SF9_MONTH_KEYS" :key="k" style="border:1px solid #000;padding:1px;text-align:center;">{{ pcDays(k) || '' }}</td>
                    <td style="border:1px solid #000;padding:1px;text-align:center;font-weight:bold;">{{ pcTotalDays() || '' }}</td>
                  </tr>
                  <tr>
                    <td style="border:1px solid #000;padding:1px 2px;font-size:6.5pt;white-space:nowrap;">No. of Days Present</td>
                    <td v-for="k in SF9_MONTH_KEYS" :key="k" style="border:1px solid #000;padding:1px;text-align:center;">{{ pcPresent(k) || '' }}</td>
                    <td style="border:1px solid #000;padding:1px;text-align:center;font-weight:bold;">{{ pcTotalPresent() || '' }}</td>
                  </tr>
                  <tr>
                    <td style="border:1px solid #000;padding:1px 2px;font-size:6.5pt;white-space:nowrap;">No. of Days Absent</td>
                    <td v-for="k in SF9_MONTH_KEYS" :key="k" style="border:1px solid #000;padding:1px;text-align:center;">{{ pcAbsent(k) || '' }}</td>
                    <td style="border:1px solid #000;padding:1px;text-align:center;font-weight:bold;">{{ pcTotalAbsent() || '' }}</td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>

          <!-- ── TWO-COLUMN BODY ── -->
          <table style="border-collapse:collapse;width:100%;table-layout:fixed;border:none;">
            <colgroup><col style="width:48%"><col style="width:4%"><col style="width:48%"></colgroup>
            <tr>

              <!-- ════ LEFT COLUMN ════ -->
              <td style="vertical-align:top;border:none;padding-right:6px;">

                <!-- Title block -->
                <div style="border:2px solid #000;text-align:center;padding:2px 0;margin-bottom:2px;">
                  <div style="font-size:11pt;font-weight:bold;text-transform:uppercase;letter-spacing:0.5px;">LEARNER'S PERFORMANCE REPORT</div>
                  <div style="font-size:8pt;">School Year 2026-2027</div>
                </div>

                <!-- Student info table -->
                <table style="border-collapse:collapse;width:100%;font-size:8pt;margin-bottom:2px;">
                  <tr>
                    <td style="border:1px solid #000;padding:1px 3px;font-weight:bold;white-space:nowrap;">Name:</td>
                    <td style="border:1px solid #000;padding:1px 3px;" colspan="5">{{ printingStudent.name }}</td>
                    <td style="border:1px solid #000;padding:1px 2px;font-weight:bold;white-space:nowrap;">Age:</td>
                    <td style="border:1px solid #000;padding:1px 2px;text-align:center;">{{ ageFrom(printingStudent.birthday) }}</td>
                    <td style="border:1px solid #000;padding:1px 2px;font-weight:bold;white-space:nowrap;">Sex:</td>
                    <td style="border:1px solid #000;padding:1px 2px;text-align:center;">{{ printingStudent.sex === 'M' ? 'Male' : 'Female' }}</td>
                  </tr>
                  <tr>
                    <td style="border:1px solid #000;padding:1px 3px;font-weight:bold;white-space:nowrap;">LRN:</td>
                    <td style="border:1px solid #000;padding:1px 3px;font-family:monospace;" colspan="5">{{ printingStudent.lrn }}</td>
                    <td style="border:1px solid #000;padding:1px 2px;font-weight:bold;white-space:nowrap;">Grade:</td>
                    <td style="border:1px solid #000;padding:1px 2px;text-align:center;">{{ printingStudent.grade_level || printingStudent.section?.match(/\d+/)?.[0] || '' }}</td>
                    <td style="border:1px solid #000;padding:1px 2px;font-weight:bold;white-space:nowrap;">Section:</td>
                    <td style="border:1px solid #000;padding:1px 2px;">{{ printingStudent.section }}</td>
                  </tr>
                  <tr>
                    <td style="border:1px solid #000;padding:1px 3px;font-weight:bold;" colspan="10">Track (SHS only): _______________________________________</td>
                  </tr>
                </table>

                <!-- Dear Parents letter -->
                <div style="font-size:7.5pt;margin-bottom:3px;border:1px solid #000;padding:2px 4px;">
                  <div style="font-weight:bold;">Dear Parents / Guardian,</div>
                  <div style="margin-top:1px;">&#160;&#160;This Performance Report presents your child's progress and achievement in the different learning areas.</div>
                  <div>&#160;&#160;The school welcomes you to reach out should you wish to know more about your child's learning and performance.</div>
                </div>

                <!-- Signatories -->
                <table style="border-collapse:collapse;width:100%;font-size:8pt;margin-bottom:3px;">
                  <tr>
                    <td style="border:none;text-align:center;padding-top:16px;width:48%;">
                      <div style="border-top:1px solid #000;padding-top:2px;font-weight:bold;text-transform:uppercase;">NELSON A. IMACULATA JR.</div>
                      <div>School Head</div>
                    </td>
                    <td style="border:none;width:4%;"></td>
                    <td style="border:none;text-align:center;padding-top:16px;width:48%;">
                      <div style="border-top:1px solid #000;padding-top:2px;font-weight:bold;text-transform:uppercase;">{{ printCardAdviser || '________________________' }}</div>
                      <div>Adviser</div>
                    </td>
                  </tr>
                </table>

                <!-- LEARNING PROGRESS AND ACHIEVEMENT table -->
                <table style="border-collapse:collapse;width:100%;font-size:7.5pt;">
                  <thead>
                    <tr>
                      <th style="background:#002060;color:#fff;border:1px solid #000;padding:2px 3px;text-align:left;" colspan="6">LEARNING PROGRESS AND ACHIEVEMENT</th>
                    </tr>
                    <tr>
                      <th style="border:1px solid #000;padding:2px 3px;text-align:left;">Learning Areas</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;width:28px;">T1</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;width:28px;">T2</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;width:28px;">T3</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;width:52px;">Final Grade</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;width:46px;">Remarks</th>
                    </tr>
                  </thead>
                  <tbody>
                    <template v-for="subj in SUBJECTS_SF9" :key="subj.key">
                      <tr v-if="subj.composite" style="background:#f0f4ff;">
                        <td style="border:1px solid #000;padding:2px 3px;font-weight:bold;">{{ subj.label }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;background:#e8ecf8;"></td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;background:#e8ecf8;"></td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;background:#e8ecf8;"></td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;font-weight:bold;">{{ subjectAvg(printingStudent.lrn, subj.key) || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;font-size:7pt;">{{ gradeRemarks(subjectAvg(printingStudent.lrn, subj.key)) }}</td>
                      </tr>
                      <tr v-else-if="subj.sub" style="background:#fafbff;">
                        <td style="border:1px solid #000;padding:2px 3px;padding-left:10px;font-style:italic;">{{ subj.label }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 1') || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 2') || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 3') || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;font-weight:bold;">{{ subjectAvg(printingStudent.lrn, subj.key) || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;font-size:7pt;">{{ gradeRemarks(subjectAvg(printingStudent.lrn, subj.key)) }}</td>
                      </tr>
                      <tr v-else>
                        <td style="border:1px solid #000;padding:2px 3px;">{{ subj.label }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 1') || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 2') || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 3') || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;font-weight:bold;">{{ subjectAvg(printingStudent.lrn, subj.key) || '' }}</td>
                        <td style="border:1px solid #000;padding:2px;text-align:center;font-size:7pt;">{{ gradeRemarks(subjectAvg(printingStudent.lrn, subj.key)) }}</td>
                      </tr>
                    </template>
                    <!-- General Average row -->
                    <tr style="font-weight:bold;background:#f0f8f0;">
                      <td style="border:1px solid #000;padding:2px 3px;">General Average</td>
                      <td style="border:1px solid #000;" colspan="3"></td>
                      <td style="border:1px solid #000;padding:2px;text-align:center;font-size:10pt;">{{ finalAvg(printingStudent.lrn) || '' }}</td>
                      <td style="border:1px solid #000;padding:2px;text-align:center;font-size:7pt;">{{ finalRemarks(finalAvg(printingStudent.lrn)) }}</td>
                    </tr>
                  </tbody>
                </table>

                <!-- Performance Descriptors -->
                <table style="border-collapse:collapse;width:100%;font-size:7pt;margin-top:3px;">
                  <thead>
                    <tr>
                      <th style="background:#002060;color:#fff;border:1px solid #000;padding:2px;text-align:center;" colspan="3">PERFORMANCE DESCRIPTORS</th>
                    </tr>
                    <tr>
                      <th style="border:1px solid #000;padding:2px;text-align:center;">Grading Scale</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;">Descriptors</th>
                      <th style="border:1px solid #000;padding:2px;text-align:center;">Remarks</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr><td style="border:1px solid #000;padding:1px;text-align:center;">90-100</td><td style="border:1px solid #000;padding:1px;text-align:center;">Advancing</td><td style="border:1px solid #000;padding:1px;text-align:center;">Passed</td></tr>
                    <tr><td style="border:1px solid #000;padding:1px;text-align:center;">80-89</td><td style="border:1px solid #000;padding:1px;text-align:center;">Benchmarking</td><td style="border:1px solid #000;padding:1px;text-align:center;">Passed</td></tr>
                    <tr><td style="border:1px solid #000;padding:1px;text-align:center;">75-79</td><td style="border:1px solid #000;padding:1px;text-align:center;">Connecting</td><td style="border:1px solid #000;padding:1px;text-align:center;">Passed</td></tr>
                    <tr><td style="border:1px solid #000;padding:1px;text-align:center;">65-74</td><td style="border:1px solid #000;padding:1px;text-align:center;">Developing</td><td style="border:1px solid #000;padding:1px;text-align:center;">Failed</td></tr>
                    <tr><td style="border:1px solid #000;padding:1px;text-align:center;">0-64</td><td style="border:1px solid #000;padding:1px;text-align:center;">Emerging</td><td style="border:1px solid #000;padding:1px;text-align:center;">Failed</td></tr>
                  </tbody>
                </table>

              </td><!-- end LEFT COLUMN -->

              <!-- VERTICAL DIVIDER -->
              <td style="padding:0;position:relative;">
                <div style="position:absolute;left:50%;top:0;bottom:0;border-left:2px solid #000;"></div>
              </td>

              <!-- ════ RIGHT COLUMN ════ -->
              <td style="vertical-align:top;border:none;padding-left:6px;">

                <!-- TEACHER'S COMMENTS / REMARKS -->
                <table style="border-collapse:collapse;width:100%;font-size:7.5pt;margin-bottom:8px;">
                  <thead>
                    <tr>
                      <th style="background:#002060;color:#fff;border:1px solid #000;padding:3px;text-align:center;" colspan="2">TEACHER'S COMMENTS / REMARKS</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td style="border:1px solid #000;padding:3px 4px;font-weight:bold;width:42px;vertical-align:top;white-space:nowrap;">Term 1</td>
                      <td style="border:1px solid #000;padding:4px;height:56px;vertical-align:top;">{{ printCardComments['term 1'] || '' }}</td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:3px 4px;font-weight:bold;vertical-align:top;white-space:nowrap;">Term 2</td>
                      <td style="border:1px solid #000;padding:4px;height:56px;vertical-align:top;">{{ printCardComments['term 2'] || '' }}</td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:3px 4px;font-weight:bold;vertical-align:top;white-space:nowrap;">Term 3</td>
                      <td style="border:1px solid #000;padding:4px;height:56px;vertical-align:top;">{{ printCardComments['term 3'] || '' }}</td>
                    </tr>
                  </tbody>
                </table>

                <!-- PARENT/S GUARDIAN'S SIGNATURE -->
                <table style="border-collapse:collapse;width:100%;font-size:7.5pt;margin-bottom:8px;">
                  <thead>
                    <tr>
                      <th style="background:#002060;color:#fff;border:1px solid #000;padding:3px;text-align:center;" colspan="2">PARENT/S GUARDIAN'S SIGNATURE</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td style="border:1px solid #000;padding:3px 4px;font-weight:bold;vertical-align:top;width:42px;white-space:nowrap;">Term 1</td>
                      <td style="border:1px solid #000;padding:4px;height:40px;"></td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:3px 4px;font-weight:bold;vertical-align:top;white-space:nowrap;">Term 2</td>
                      <td style="border:1px solid #000;padding:4px;height:40px;"></td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:3px 4px;font-weight:bold;vertical-align:top;white-space:nowrap;">Term 3</td>
                      <td style="border:1px solid #000;padding:4px;height:40px;"></td>
                    </tr>
                  </tbody>
                </table>

                <!-- CERTIFICATE OF TRANSFER -->
                <table style="border-collapse:collapse;width:100%;font-size:7pt;margin-bottom:8px;">
                  <thead>
                    <tr>
                      <th style="background:#002060;color:#fff;border:1px solid #000;padding:3px;text-align:center;" colspan="2">CERTIFICATE OF TRANSFER</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td style="border:1px solid #000;padding:4px 5px;line-height:1.5;" colspan="2">
                        This is to certify that the above-named learner has satisfactorily completed the requirements for the grade level indicated and is eligible for admission to the next grade level.
                      </td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:4px 5px;">Admitted to Grade: ___________</td>
                      <td style="border:1px solid #000;padding:4px 5px;">Eligible for Grade: ___________</td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:5px;text-align:center;padding-top:22px;" colspan="2">
                        <div style="border-top:1px solid #000;padding-top:3px;font-weight:bold;text-transform:uppercase;">NELSON A. IMACULATA JR.</div>
                        <div>School Head</div>
                      </td>
                    </tr>
                  </tbody>
                </table>

                <!-- CANCELLATION OF ELIGIBILITY TO TRANSFER -->
                <table style="border-collapse:collapse;width:100%;font-size:7pt;">
                  <thead>
                    <tr>
                      <th style="background:#002060;color:#fff;border:1px solid #000;padding:3px;text-align:center;" colspan="2">CANCELLATION OF ELIGIBILITY TO TRANSFER</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td style="border:1px solid #000;padding:4px 5px;">Admitted in: _______________</td>
                      <td style="border:1px solid #000;padding:4px 5px;">Date: _____________________</td>
                    </tr>
                    <tr>
                      <td style="border:1px solid #000;padding:5px;text-align:center;padding-top:22px;" colspan="2">
                        <div style="border-top:1px solid #000;padding-top:3px;font-weight:bold;text-transform:uppercase;">NELSON A. IMACULATA JR.</div>
                        <div>School Head</div>
                      </td>
                    </tr>
                  </tbody>
                </table>

              </td><!-- end RIGHT COLUMN -->
            </tr>
          </table><!-- end TWO-COLUMN BODY -->

        </div><!-- end outer border box -->
      </div><!-- end sf9-print-area -->

    </div>
  </div>

</template>

<style scoped>
@media print {
  .no-print { display: none !important; }
}
</style>
