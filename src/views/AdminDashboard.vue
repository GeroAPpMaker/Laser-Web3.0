<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../supabase.js'

// Tab navigation state ('teachers' | 'advisers' | 'students' | 'grades' | 'summary' | 'materials')
const activeTab = ref('teachers')
const loading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
let successTimer = null

function showSuccess(msg) {
  successMessage.value = msg
  clearTimeout(successTimer)
  successTimer = setTimeout(() => { successMessage.value = '' }, 3500)
}

// Data Collections
const teachers = ref([])
const assignments = ref([])
const adviserSections = ref([])
const students = ref([])
const grades = ref([])
const matrixGrades = ref([]) // Grades for the summary matrix tab
const activeMaterials = ref([])
const materialForm = ref({ type: 'adm', subject: '', term: 1, title: '', url: '', section: '' })
const materialLoading = ref(false)
const materialError = ref('')

// Core 8 Subjects List
const subjectsList = ref([
  'Filipino',
  'English',
  'Mathematics',
  'Science',
  'AP',
  'ValuesEd',
  'TLE',
  'MA',
  'PEH'
])

// Filters
const searchTeacher = ref('')
const selectedStudentSection = ref('ALL')
const selectedGradeSection = ref('ALL')
const selectedGradeTerm = ref('term 1')
const selectedGradeSubject = ref('ALL')
const terms = ['term 1', 'term 2', 'term 3']

// Collapsed teacher rows — Set of teacher IDs that are minimised
const collapsedTeachers = ref(new Set())

function toggleTeacher(id) {
  const s = new Set(collapsedTeachers.value)
  if (s.has(id)) { s.delete(id) } else { s.add(id) }
  collapsedTeachers.value = s
}

// Summary Tab Filters
const selectedSummarySection = ref('')

// New Record States (for inline Add forms)
const newTeacher = ref({ name: '', email: '', role: 'teacher' })
const newAssignment = ref({ teacher_email: '', section: '', subject: '', school_year: '2026-2027' })
const newAdviserSection = ref({ teacher_email: '', section: '', school_year: '2026-2027' })
const newStudent = ref({ lrn: '', name: '', sex: 'M', section: '', birthday: '', grade_level: '' })
const newGrade = ref({ lrn: '', subject: '', section: '', term: 'term 1', grade: '', teacher_email: '' })

// Distinct options for filter dropdowns
const uniqueSections = computed(() => {
  const allSec = [
    ...students.value.map(s => s.section),
    ...assignments.value.map(a => a.section),
    ...adviserSections.value.map(a => a.section)
  ]
  return [...new Set(allSec)].filter(Boolean).sort()
})

const uniqueSubjects = computed(() => {
  return [...new Set(assignments.value.map(a => a.subject))].sort()
})

// Auto-select first available section for summary matrix when sections load
watch(uniqueSections, (secs) => {
  if (secs.length > 0 && !selectedSummarySection.value) {
    selectedSummarySection.value = secs[0]
  }
}, { immediate: true })

// ── Edit Teacher ──────────────────────────────────────────────────────────────
const editingTeacher = ref(null)
const editTeacherForm = ref({ name: '', email: '', role: 'teacher' })

function openEditTeacher(teacher) {
  editingTeacher.value = teacher
  editTeacherForm.value = { name: teacher.name, email: teacher.email, role: teacher.role }
}

async function saveEditTeacher() {
  errorMessage.value = ''
  const { error } = await supabase
    .from('teachers')
    .update({ name: editTeacherForm.value.name, email: editTeacherForm.value.email, role: editTeacherForm.value.role })
    .eq('id', editingTeacher.value.id)
  if (error) { errorMessage.value = `Update failed: ${error.message}`; return }
  editingTeacher.value = null
  await fetchTeachers()
}

// ── Edit Student ──────────────────────────────────────────────────────────────
const editingStudent = ref(null)
const editStudentForm = ref({ lrn: '', name: '', sex: 'M', section: '', birthday: '', grade_level: '' })

function openEditStudent(student) {
  editingStudent.value = student
  editStudentForm.value = { lrn: student.lrn, name: student.name, sex: student.sex, section: student.section, birthday: student.birthday, grade_level: student.grade_level || '' }
}

async function saveEditStudent() {
  errorMessage.value = ''
  const { error } = await supabase
    .from('students')
    .update({ lrn: editStudentForm.value.lrn, name: editStudentForm.value.name, sex: editStudentForm.value.sex, section: editStudentForm.value.section, birthday: editStudentForm.value.birthday, grade_level: editStudentForm.value.grade_level })
    .eq('id', editingStudent.value.id)
  if (error) { errorMessage.value = `Update failed: ${error.message}`; return }
  editingStudent.value = null
  await fetchStudents()
}

// ── Edit Adviser Section ──────────────────────────────────────────────────────
const editingAdviser = ref(null)
const editAdviserForm = ref({ teacher_email: '', section: '', school_year: '' })

function openEditAdviser(adv) {
  editingAdviser.value = adv
  editAdviserForm.value = { teacher_email: adv.teacher_email, section: adv.section, school_year: adv.school_year }
}

async function saveEditAdviser() {
  errorMessage.value = ''
  const { error } = await supabase
    .from('adviser_sections')
    .update({ teacher_email: editAdviserForm.value.teacher_email, section: editAdviserForm.value.section, school_year: editAdviserForm.value.school_year })
    .eq('id', editingAdviser.value.id)
  if (error) { errorMessage.value = `Update failed: ${error.message}`; return }
  editingAdviser.value = null
  await fetchAdviserSections()
}

// ── Edit Assignment ───────────────────────────────────────────────────────────
const editingAssignment = ref(null)
const editAssignmentForm = ref({ teacher_email: '', section: '', subject: '', school_year: '2026-2027' })

function openEditAssignment(a) {
  editingAssignment.value = a
  editAssignmentForm.value = { teacher_email: a.teacher_email, section: a.section, subject: a.subject, school_year: a.school_year || '2026-2027' }
}

async function saveEditAssignment() {
  errorMessage.value = ''
  const { error } = await supabase
    .from('teacher_subject_assignments')
    .update({ teacher_email: editAssignmentForm.value.teacher_email, section: editAssignmentForm.value.section, subject: editAssignmentForm.value.subject, school_year: editAssignmentForm.value.school_year })
    .eq('id', editingAssignment.value.id)
  if (error) { errorMessage.value = `Update failed: ${error.message}`; return }
  editingAssignment.value = null
  await fetchAssignments()
}

// Combined Teacher + Assignments View Model
const teacherOverview = computed(() => {
  return teachers.value.map(teacher => {
    const subjectAssignments = assignments.value.filter(a => a.teacher_email === teacher.email)

    // Group assignments by section → { [section]: [{ id, subject }] }
    const bySection = {}
    subjectAssignments.forEach(a => {
      if (!bySection[a.section]) bySection[a.section] = []
      bySection[a.section].push(a)
    })

    return {
      ...teacher,
      subjectAssignments,
      assignmentsBySection: bySection
    }
  }).filter(t => {
    const query = searchTeacher.value.toLowerCase()
    return t.name.toLowerCase().includes(query) || t.email.toLowerCase().includes(query)
  })
})

const filteredStudents = computed(() => {
  if (selectedStudentSection.value === 'ALL') return students.value
  return students.value.filter(s => s.section === selectedStudentSection.value)
})

// Computed Matrix Data for the Term Summary Tab — All-Terms Side-by-Side
const formattedSummaryStudents = computed(() => {
  if (!selectedSummarySection.value) return []

  const sectionStudents = students.value.filter(s => s.section === selectedSummarySection.value)

  return sectionStudents.map(student => {
    const studentGrades = matrixGrades.value.filter(g => g.lrn === student.lrn)

    const row = { id: student.id, lrn: student.lrn, name: student.name }
    let grandTotal = 0
    let grandCount = 0

    subjectsList.value.forEach(subject => {
      let subTotal = 0
      let subCount = 0
      ;['term 1', 'term 2', 'term 3'].forEach((term, i) => {
        const g = studentGrades.find(r => r.subject === subject && r.term?.toLowerCase() === term)
        const val = g && g.grade !== null && g.grade !== undefined && g.grade !== '' ? Number(g.grade) : null
        row[`${subject}_t${i + 1}`] = val !== null ? val : ''
        if (val !== null) { subTotal += val; subCount++ }
      })
      const subAvg = subCount > 0 ? (subTotal / subCount).toFixed(2) : ''
      row[`${subject}_avg`] = subAvg
      if (subAvg !== '') { grandTotal += Number(subAvg); grandCount++ }
    })

    row.finalAverage = grandCount > 0 ? (grandTotal / grandCount).toFixed(2) : 'N/A'
    return row
  })
})

onMounted(async () => {
  await loadAllData()
})

async function loadAllData() {
  loading.value = true
  errorMessage.value = ''
  try {
    await Promise.all([
      fetchTeachers(),
      fetchAssignments(),
      fetchAdviserSections(),
      fetchStudents(),
      fetchGrades()
    ])
    if (activeTab.value === 'summary') {
      await fetchSummaryGrades()
    }
  } catch (err) {
    errorMessage.value = `Failed to load admin data: ${err.message || err}`
  } finally {
    loading.value = false
  }
}

// --- FETCH METHODS ---
async function fetchTeachers() {
  const { data, error } = await supabase.from('teachers').select('*').order('name')
  if (error) throw error
  teachers.value = data || []
}

async function fetchAssignments() {
  const { data, error } = await supabase.from('teacher_subject_assignments').select('*')
  if (error) throw error
  assignments.value = data || []
}

async function fetchAdviserSections() {
  const { data, error } = await supabase.from('adviser_sections').select('*')
  if (error) throw error
  adviserSections.value = data || []
}

async function fetchStudents() {
  const { data, error } = await supabase.from('students').select('*').order('section').order('name')
  if (error) throw error
  students.value = data || []
}

async function fetchGrades() {
  let query = supabase.from('grades').select('*').order('created_at', { ascending: false })
  if (selectedGradeTerm.value) query = query.ilike('term', selectedGradeTerm.value)
  if (selectedGradeSection.value !== 'ALL') query = query.eq('section', selectedGradeSection.value)
  if (selectedGradeSubject.value !== 'ALL') query = query.eq('subject', selectedGradeSubject.value)
  
  const { data, error } = await query
  if (error) throw error
  grades.value = data || []
}

async function fetchSummaryGrades() {
  if (!selectedSummarySection.value) return
  const { data, error } = await supabase
    .from('grades')
    .select('*')
    .eq('section', selectedSummarySection.value)

  if (error) {
    errorMessage.value = `Failed to fetch term summary: ${error.message}`
  } else {
    matrixGrades.value = data || []
  }
}

// Watchers for tab transitions and filter changes
watch([selectedGradeSection, selectedGradeTerm, selectedGradeSubject], () => {
  if (activeTab.value === 'grades') fetchGrades()
})

watch([selectedSummarySection, activeTab], () => {
  if (activeTab.value === 'summary') fetchSummaryGrades()
})

// --- GENERIC CRUD METHODS ---
async function deleteRecord(table, id, fetchCallback) {
  if (!confirm(`Are you sure you want to delete this record from ${table}?`)) return
  errorMessage.value = ''
  const { error } = await supabase.from(table).delete().eq('id', id)
  if (error) {
    errorMessage.value = `Delete failed: ${error.message}`
  } else {
    await fetchCallback()
  }
}

// --- SPECIFIC ADD METHODS ---
async function addTeacher() {
  if (!newTeacher.value.name || !newTeacher.value.email) return
  errorMessage.value = ''
  const { error } = await supabase.from('teachers').insert([newTeacher.value])
  if (error) {
    errorMessage.value = `Failed to add teacher: ${error.message}`
    return
  }
  newTeacher.value = { name: '', email: '', role: 'teacher' }
  await fetchTeachers()
}

async function addAssignment() {
  if (!newAssignment.value.teacher_email || !newAssignment.value.section) return
  errorMessage.value = ''
  const { error } = await supabase.from('teacher_subject_assignments').insert([newAssignment.value])
  if (error) {
    errorMessage.value = `Failed to assign subject: ${error.message}`
    return
  }
  newAssignment.value = { teacher_email: '', section: '', subject: '', school_year: '2026-2027' }
  await fetchAssignments()
  showSuccess('Subject assignment saved successfully.')
}

async function addAdviserSection() {
  if (!newAdviserSection.value.teacher_email || !newAdviserSection.value.section || !newAdviserSection.value.school_year) return
  errorMessage.value = ''
  const { error } = await supabase.from('adviser_sections').insert([newAdviserSection.value])
  if (error) {
    errorMessage.value = `Failed to add adviser mapping: ${error.message}`
    return
  }
  newAdviserSection.value = { teacher_email: '', section: '', school_year: '2026-2027' }
  await fetchAdviserSections()
}

async function addStudent() {
  if (!newStudent.value.lrn || !newStudent.value.name) return
  errorMessage.value = ''
  const { error } = await supabase.from('students').insert([newStudent.value])
  if (error) {
    errorMessage.value = `Failed to add student: ${error.message}`
    return
  }
  newStudent.value = { lrn: '', name: '', sex: 'M', section: '', birthday: '', grade_level: '' }
  await fetchStudents()
}

async function addGrade() {
  if (!newGrade.value.lrn || !newGrade.value.grade) return
  errorMessage.value = ''
  const { error } = await supabase.from('grades').insert([newGrade.value])
  if (error) {
    errorMessage.value = `Failed to add grade: ${error.message}`
    return
  }
  newGrade.value = { lrn: '', subject: '', section: '', term: 'term 1', grade: '', teacher_email: '' }
  await fetchGrades()
  if (activeTab.value === 'summary') fetchSummaryGrades()
}

async function fetchMaterials() {
  const { data, error } = await supabase
    .from('learning_materials')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) { materialError.value = `Failed to load materials: ${error.message}`; return }
  activeMaterials.value = data || []
}

async function addMaterial() {
  materialError.value = ''
  const f = materialForm.value
  if (!f.subject || !f.title || !f.url) { materialError.value = 'Subject, Title and URL are required.'; return }
  materialLoading.value = true
  const { data: { user } } = await supabase.auth.getUser()
  const payload = {
    type: f.type,
    subject: f.subject.trim(),
    term: Number(f.term),
    title: f.title.trim(),
    url: f.url.trim(),
    section: f.section.trim() || null,
    submitted_by: user?.email ?? null,
  }
  const { error } = await supabase.from('learning_materials').insert([payload])
  materialLoading.value = false
  if (error) { materialError.value = `Failed to add material: ${error.message}`; return }
  materialForm.value = { type: 'adm', subject: '', term: 1, title: '', url: '', section: '' }
  await fetchMaterials()
}

async function deleteMaterial(id) {
  if (!confirm('Delete this material?')) return
  const { error } = await supabase.from('learning_materials').delete().eq('id', id)
  if (error) { materialError.value = `Delete failed: ${error.message}`; return }
  await fetchMaterials()
}

// --- STUDENT TRANSFER ---
async function transferStudent(student) {
  const newSection = prompt(`Enter new section for ${student.name} (Current: ${student.section}):`, student.section)
  if (newSection !== null && newSection.trim() !== '' && newSection !== student.section) {
    errorMessage.value = ''
    const { error } = await supabase.from('students').update({ section: newSection.trim() }).eq('id', student.id)
    if (error) {
      errorMessage.value = `Transfer failed: ${error.message}`
    } else {
      await fetchStudents()
    }
  }
}

// --- STUDENT REPORT CARD PRINT ---
const printingStudent = ref(null)
const printCardGrades = ref([])
const printCardComments = ref({})   // { 'term 1': '...', 'term 2': '...', 'term 3': '...' }
const printCardAttendance = ref({}) // { JUN: present, JUL: present, ... }
const printCardClassDays = ref({})  // { JUN: total, JUL: total, ... }
const printCardAdviser = ref('')
const printCardLoading = ref(false)

// SF9 subjects — MAPEH is a composite row; MA + PEH are sub-rows
const SUBJECTS_SF9 = [
  { key: 'Filipino',    label: 'Filipino',                        sub: false },
  { key: 'English',     label: 'English',                         sub: false },
  { key: 'Mathematics', label: 'Mathematics',                     sub: false },
  { key: 'Science',     label: 'Science',                         sub: false },
  { key: 'AP',          label: 'Araling Panlipunan (AP)',          sub: false },
  { key: 'ValuesEd',    label: 'GMRC / Values Education',          sub: false },
  { key: 'TLE',         label: 'EPP/TLE',                         sub: false },
  { key: 'MAPEH',       label: 'MAPEH',                            sub: false, composite: true },
  { key: 'MA',          label: '  Music and Arts',                 sub: true  },
  { key: 'PEH',         label: '  Physical Education and Health',  sub: true  },
  { key: 'SPFL',        label: 'SPFL (Korean)',                    sub: false },
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
  // MAPEH average = average of MA and PEH averages
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
  // General average uses: Filipino, English, Math, Science, AP, ValuesEd, TLE, MAPEH, SPFL
  // MA and PEH sub-rows are excluded — MAPEH composite row is used instead
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

  const [gradeRes, advRow, commentRes, attendRes, classDayRes] = await Promise.all([
    supabase.from('grades').select('*').eq('lrn', student.lrn),
    supabase.from('adviser_sections').select('teacher_email').eq('section', student.section).maybeSingle(),
    supabase.from('term_comments').select('term,comment').eq('lrn', student.lrn).eq('school_year', '2026-2027'),
    supabase.from('attendance_records').select('month,days_present').eq('lrn', student.lrn).eq('school_year', '2026-2027'),
    supabase.from('class_days').select('month,total_days').eq('section', student.section).eq('school_year', '2026-2027'),
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

  if (advRow.data?.teacher_email) {
    const tRow = await supabase.from('teachers').select('name').eq('email', advRow.data.teacher_email).maybeSingle()
    printCardAdviser.value = tRow.data?.name || advRow.data.teacher_email
  } else {
    printCardAdviser.value = ''
  }

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
  <div class="max-w-7xl mx-auto p-6 space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b pb-5">
      <div>
        <h1 class="text-3xl font-bold text-slate-800">Admin Control Center</h1>
        <p class="text-sm text-slate-500">Overview of teachers, advisers, student rosters, grades registry, and term matrix</p>
      </div>
      <button 
        @click="loadAllData" 
        :disabled="loading"
        class="self-start sm:self-auto px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm font-medium rounded-lg border transition flex items-center gap-2"
      >
        Refresh Data
      </button>
    </div>

    <!-- Error Alert -->
    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm flex items-center justify-between">
      <span>{{ errorMessage }}</span>
      <button @click="errorMessage = ''" class="text-red-500 hover:text-red-700 font-bold ml-4">&times;</button>
    </div>

    <!-- Success Toast -->
    <Transition enter-active-class="transition duration-300 ease-out" enter-from-class="opacity-0 -translate-y-2" enter-to-class="opacity-100 translate-y-0" leave-active-class="transition duration-200 ease-in" leave-from-class="opacity-100 translate-y-0" leave-to-class="opacity-0 -translate-y-2">
      <div v-if="successMessage" class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-lg text-sm flex items-center justify-between shadow-sm">
        <span class="flex items-center gap-2">
          <span class="text-emerald-500 font-bold text-base">✓</span>
          {{ successMessage }}
        </span>
        <button @click="successMessage = ''" class="text-emerald-500 hover:text-emerald-700 font-bold ml-4">&times;</button>
      </div>
    </Transition>

    <!-- Tab Navigation -->
    <div class="flex border-b border-slate-200 space-x-6 sm:space-x-8 overflow-x-auto">
      <button @click="activeTab = 'teachers'" :class="activeTab === 'teachers' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'" class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2 whitespace-nowrap">
        <span>Teachers & Assignments</span>
        <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full text-xs font-mono">{{ teachers.length }}</span>
      </button>
      
      <button @click="activeTab = 'advisers'" :class="activeTab === 'advisers' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'" class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2 whitespace-nowrap">
        <span>Advisers & Sections</span>
      </button>
      
      <button @click="activeTab = 'students'" :class="activeTab === 'students' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'" class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2 whitespace-nowrap">
        <span>Students Roster</span>
        <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full text-xs font-mono">{{ students.length }}</span>
      </button>
      
      <button @click="activeTab = 'grades'; fetchGrades()" :class="activeTab === 'grades' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'" class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2 whitespace-nowrap">
        <span>Grades Registry</span>
      </button>

      <!-- NEW TAB: TERM SUMMARY MATRIX -->
      <button @click="activeTab = 'summary'; fetchSummaryGrades()" :class="activeTab === 'summary' ? 'border-emerald-600 text-emerald-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'" class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2 whitespace-nowrap">
        <span class="flex items-center gap-1.5">
          <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
          Term Summary Matrix
        </span>
      </button>

      <button @click="activeTab = 'materials'; fetchMaterials()" :class="activeTab === 'materials' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'" class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2 whitespace-nowrap">
        <span>Learning Materials</span>
        <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full text-xs font-mono">{{ activeMaterials.length }}</span>
      </button>
    </div>

    <!-- TAB 1: TEACHERS & ASSIGNMENTS -->
    <div v-if="activeTab === 'teachers'" class="space-y-6">

      <!-- Map Subject Assignment (TOP) -->
      <div>
        <h3 class="text-lg font-semibold text-slate-700 mb-2">Map Subject Assignment</h3>
        <div class="flex flex-wrap gap-2 items-center bg-white p-3 border rounded-lg shadow-sm">
          <select v-model="newAssignment.teacher_email" class="p-2 border rounded text-sm flex-1 min-w-[180px]">
            <option value="" disabled>— Teacher —</option>
            <option v-for="t in teachers" :key="t.id" :value="t.email">{{ t.name }} ({{ t.email }})</option>
          </select>
          <select v-model="newAssignment.section" class="p-2 border rounded text-sm flex-1 min-w-[140px]">
            <option value="" disabled>— Section —</option>
            <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
          </select>
          <select v-model="newAssignment.subject" class="p-2 border rounded text-sm flex-1 min-w-[140px]">
            <option value="" disabled>— Subject —</option>
            <option v-for="sub in subjectsList" :key="sub" :value="sub">{{ sub }}</option>
          </select>
          <button @click="addAssignment" class="bg-slate-800 text-white px-4 py-2 rounded text-sm hover:bg-slate-700 whitespace-nowrap">Assign Subject</button>
        </div>
      </div>

      <!-- Teachers Table -->
      <div>
        <div class="flex justify-between items-center mb-3">
          <input v-model="searchTeacher" type="text" placeholder="Search teacher..." class="w-80 p-2 border border-slate-300 rounded-md text-sm" />
        </div>
        <div class="bg-white rounded-xl border shadow-sm overflow-hidden">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-slate-50 text-xs uppercase text-slate-600">
                <th class="p-3">Teacher</th>
                <th class="p-3">Role</th>
                <th class="p-3">Subject Assignments</th>
                <th class="p-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="text-sm">
              <!-- Add Form Row -->
              <tr class="bg-blue-50/50">
                <td class="p-2">
                  <input v-model="newTeacher.name" placeholder="Name" class="w-full p-1 border rounded text-xs mb-1" />
                  <input v-model="newTeacher.email" placeholder="Email" class="w-full p-1 border rounded text-xs" />
                </td>
                <td class="p-2">
                  <select v-model="newTeacher.role" class="w-full p-1 border rounded text-xs">
                    <option value="teacher">Subject Teacher</option>
                    <option value="adviser">Adviser</option>
                  </select>
                </td>
                <td class="p-2 text-slate-400 italic text-xs">Assigned via form above</td>
                <td class="p-2 text-right">
                  <button @click="addTeacher" class="bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700">Add Teacher</button>
                </td>
              </tr>
              <!-- Data Rows -->
              <template v-for="teacher in teacherOverview" :key="teacher.id">
                <!-- Summary row (always visible) -->
                <tr class="border-t hover:bg-slate-50 cursor-pointer" @click="toggleTeacher(teacher.id)">
                  <td class="p-3">
                    <div class="flex items-center gap-2">
                      <span class="text-slate-400 text-xs select-none transition-transform" :class="collapsedTeachers.has(teacher.id) ? 'rotate-0' : 'rotate-90'">▶</span>
                      <div>
                        <div class="font-semibold text-slate-800">{{ teacher.name }}</div>
                        <div class="text-xs text-slate-500">{{ teacher.email }}</div>
                      </div>
                    </div>
                  </td>
                  <td class="p-3"><span class="px-2 py-1 bg-slate-100 rounded text-xs">{{ teacher.role }}</span></td>
                  <td class="p-3 text-xs text-slate-500">
                    <span v-if="teacher.subjectAssignments.length === 0" class="italic">No assignments</span>
                    <span v-else class="font-medium text-slate-700">
                      {{ teacher.subjectAssignments.length }} assignment{{ teacher.subjectAssignments.length !== 1 ? 's' : '' }}
                      across {{ Object.keys(teacher.assignmentsBySection).length }} section{{ Object.keys(teacher.assignmentsBySection).length !== 1 ? 's' : '' }}
                    </span>
                  </td>
                  <td class="p-3 text-right space-x-3" @click.stop>
                    <button @click="openEditTeacher(teacher)" class="text-blue-600 text-xs hover:underline">Edit</button>
                    <button @click="deleteRecord('teachers', teacher.id, fetchTeachers)" class="text-red-600 text-xs hover:underline">Delete</button>
                  </td>
                </tr>
                <!-- Expanded detail row -->
                <tr v-if="!collapsedTeachers.has(teacher.id)" class="bg-slate-50/60 border-b border-slate-100">
                  <td colspan="4" class="px-6 pb-3 pt-1">
                    <div v-if="Object.keys(teacher.assignmentsBySection).length === 0" class="text-slate-400 italic text-xs py-2">No subject assignments yet — use the form above to add one.</div>
                    <div v-else class="flex flex-wrap gap-4 pt-1">
                      <div v-for="(sectionAssignments, section) in teacher.assignmentsBySection" :key="section" class="bg-white border border-slate-200 rounded-lg px-3 py-2 min-w-[140px]">
                        <div class="text-[10px] font-bold uppercase text-slate-500 mb-1.5 tracking-wide">{{ section }}</div>
                        <div class="flex flex-wrap gap-1">
                          <span v-for="a in sectionAssignments" :key="a.id" class="bg-blue-50 border border-blue-200 text-blue-800 text-xs px-2 py-0.5 rounded flex items-center gap-1">
                            {{ a.subject }}
                            <button @click="openEditAssignment(a)" class="text-blue-400 hover:text-blue-700" title="Edit">✎</button>
                            <button @click="deleteRecord('teacher_subject_assignments', a.id, fetchAssignments)" class="text-red-400 hover:text-red-700">&times;</button>
                          </span>
                        </div>
                      </div>
                    </div>
                  </td>
                </tr>
              </template>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- TAB 2: ADVISERS -->
    <div v-if="activeTab === 'advisers'" class="space-y-4">
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600">
              <th class="p-4">Teacher Email</th>
              <th class="p-4">Section Handled</th>
              <th class="p-4">School Year</th>
              <th class="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200 text-sm">
            <!-- Add Row -->
            <tr class="bg-blue-50/50">
              <td class="p-2">
                <select v-model="newAdviserSection.teacher_email" class="w-full p-2 border rounded text-xs">
                  <option value="" disabled>— Select Teacher —</option>
                  <option v-for="t in teachers" :key="t.id" :value="t.email">{{ t.name }} ({{ t.email }})</option>
                </select>
              </td>
              <td class="p-2"><input v-model="newAdviserSection.section" placeholder="Section" class="w-full p-2 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newAdviserSection.school_year" placeholder="e.g. 2026-2027" class="w-full p-2 border rounded text-xs" /></td>
              <td class="p-2 text-right"><button @click="addAdviserSection" class="bg-blue-600 text-white px-3 py-1.5 rounded text-xs hover:bg-blue-700">Add Adviser Mapping</button></td>
            </tr>
            <!-- Data -->
            <tr v-for="adv in adviserSections" :key="adv.id" class="hover:bg-slate-50">
              <td class="p-4 font-mono text-slate-600 text-xs">{{ adv.teacher_email }}</td>
              <td class="p-4 font-semibold">{{ adv.section }}</td>
              <td class="p-4 text-xs text-slate-500">{{ adv.school_year || 'N/A' }}</td>
              <td class="p-4 text-right space-x-3">
                <button @click="openEditAdviser(adv)" class="text-blue-600 text-xs hover:underline">Edit</button>
                <button @click="deleteRecord('adviser_sections', adv.id, fetchAdviserSections)" class="text-red-600 text-xs hover:underline">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 3: STUDENTS ROSTER -->
    <div v-if="activeTab === 'students'" class="space-y-4">
      <div class="flex items-center justify-between bg-white p-4 rounded-lg border">
        <div class="flex items-center gap-3">
          <label class="text-xs font-semibold uppercase">Filter Section:</label>
          <select v-model="selectedStudentSection" class="p-2 border rounded-md text-sm">
            <option value="ALL">All Sections</option>
            <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
          </select>
        </div>
      </div>

      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600">
              <th class="p-3">LRN</th>
              <th class="p-3">Name</th>
              <th class="p-3">Sex</th>
              <th class="p-3">Section</th>
              <th class="p-3">Grade</th>
              <th class="p-3">Birthday</th>
              <th class="p-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="text-sm">
            <!-- Add Form -->
            <tr class="bg-blue-50/50">
              <td class="p-2"><input v-model="newStudent.lrn" placeholder="LRN" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newStudent.name" placeholder="Full Name" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2">
                <select v-model="newStudent.sex" class="w-full p-1 border rounded text-xs">
                  <option value="M">Male</option><option value="F">Female</option>
                </select>
              </td>
              <td class="p-2"><input v-model="newStudent.section" placeholder="Section" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2">
                <select v-model="newStudent.grade_level" class="w-full p-1 border rounded text-xs">
                  <option value="">—</option>
                  <option value="7">Grade 7</option>
                  <option value="8">Grade 8</option>
                  <option value="9">Grade 9</option>
                  <option value="10">Grade 10</option>
                  <option value="11">Grade 11</option>
                  <option value="12">Grade 12</option>
                </select>
              </td>
              <td class="p-2"><input v-model="newStudent.birthday" type="date" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2 text-right"><button @click="addStudent" class="bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700">Add Student</button></td>
            </tr>
            <!-- Data -->
            <tr v-for="s in filteredStudents" :key="s.id" class="border-t hover:bg-slate-50">
              <td class="p-3 font-mono text-xs">{{ s.lrn }}</td>
              <td class="p-3 font-semibold">{{ s.name }}</td>
              <td class="p-3 text-xs">{{ s.sex }}</td>
              <td class="p-3">{{ s.section }}</td>
              <td class="p-3 text-xs font-semibold">{{ s.grade_level ? `Grade ${s.grade_level}` : '—' }}</td>
              <td class="p-3 text-xs">{{ s.birthday }}</td>
              <td class="p-3 text-right space-x-3">
                <button @click="openEditStudent(s)" class="text-blue-600 text-xs hover:underline">Edit</button>
                <button @click="transferStudent(s)" class="text-indigo-600 text-xs hover:underline">Transfer</button>
                <button @click="openPrintCard(s)" class="text-emerald-600 text-xs hover:underline font-bold">Print Card</button>
                <button @click="deleteRecord('students', s.id, fetchStudents)" class="text-red-600 text-xs hover:underline">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 4: GRADES REGISTRY -->
    <div v-if="activeTab === 'grades'" class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 bg-white p-4 rounded-lg border">
        <div><label class="block text-xs font-semibold mb-1">Term</label><select v-model="selectedGradeTerm" class="w-full p-2 border rounded-md text-sm"><option v-for="t in terms" :key="t" :value="t">{{ t }}</option></select></div>
        <div><label class="block text-xs font-semibold mb-1">Section</label><select v-model="selectedGradeSection" class="w-full p-2 border rounded-md text-sm"><option value="ALL">All Sections</option><option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option></select></div>
        <div><label class="block text-xs font-semibold mb-1">Subject</label><select v-model="selectedGradeSubject" class="w-full p-2 border rounded-md text-sm"><option value="ALL">All Subjects</option><option v-for="sub in uniqueSubjects" :key="sub" :value="sub">{{ sub }}</option></select></div>
      </div>

      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600">
              <th class="p-3">LRN</th>
              <th class="p-3">Subject</th>
              <th class="p-3">Section</th>
              <th class="p-3">Term</th>
              <th class="p-3 text-center">Grade</th>
              <th class="p-3">Submitted By</th>
              <th class="p-3 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="text-sm">
            <!-- Add Row -->
            <tr class="bg-blue-50/50">
              <td class="p-2"><input v-model="newGrade.lrn" placeholder="LRN" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newGrade.subject" placeholder="Subject" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newGrade.section" placeholder="Section" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2">
                <select v-model="newGrade.term" class="w-full p-1 border rounded text-xs">
                  <option v-for="t in terms" :key="t">{{t}}</option>
                </select>
              </td>
              <td class="p-2"><input v-model="newGrade.grade" type="number" placeholder="0" class="w-full p-1 border rounded text-xs text-center" /></td>
              <td class="p-2"><input v-model="newGrade.teacher_email" placeholder="Email" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2 text-right"><button @click="addGrade" class="bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700">Add</button></td>
            </tr>
            <!-- Data -->
            <tr v-for="g in grades" :key="g.id" class="border-t hover:bg-slate-50">
              <td class="p-3 font-mono text-xs">{{ g.lrn }}</td>
              <td class="p-3 font-semibold">{{ g.subject }}</td>
              <td class="p-3">{{ g.section }}</td>
              <td class="p-3 text-xs capitalize">{{ g.term }}</td>
              <td class="p-3 text-center font-bold">{{ g.grade }}</td>
              <td class="p-3 text-xs font-mono">{{ g.teacher_email }}</td>
              <td class="p-3 text-right">
                <button @click="deleteRecord('grades', g.id, fetchGrades)" class="text-red-600 text-xs hover:underline">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 5: FULL TERM REPORT -->
    <div v-if="activeTab === 'summary'" class="space-y-4">
      <!-- Section Selector + Print -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between bg-white p-4 rounded-lg border gap-4 no-print">
        <div class="flex items-center gap-3">
          <label class="text-xs font-semibold uppercase text-slate-600">Select Section:</label>
          <select v-model="selectedSummarySection" class="p-2 border rounded-md text-sm font-semibold text-slate-800 bg-slate-50">
            <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
          </select>
        </div>
        <button @click="() => window.print()" class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-medium rounded-lg transition no-print">
          🖨 Print Report
        </button>
      </div>

      <!-- All-Terms Matrix Table -->
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-x-auto">
        <table class="w-full text-left border-collapse min-w-max text-xs">
          <thead>
            <!-- Subject group header row -->
            <tr class="bg-slate-100 text-slate-600 border-b border-slate-200">
              <th class="p-3 sticky left-0 bg-slate-100 border-r border-slate-200 z-10 w-52" rowspan="2">Student</th>
              <th v-for="subject in subjectsList" :key="subject" class="p-2 text-center font-semibold border-l border-slate-200" colspan="4">
                {{ subject }}
              </th>
              <th class="p-3 text-center border-l-2 border-slate-300 bg-emerald-50 text-emerald-700 font-bold" rowspan="2">Final Avg</th>
            </tr>
            <!-- T1 / T2 / T3 / Avg sub-header row -->
            <tr class="bg-slate-50 text-slate-500 border-b border-slate-200">
              <template v-for="subject in subjectsList" :key="subject">
                <th class="p-2 text-center font-medium border-l border-slate-200 w-10">T1</th>
                <th class="p-2 text-center font-medium w-10">T2</th>
                <th class="p-2 text-center font-medium w-10">T3</th>
                <th class="p-2 text-center font-medium text-blue-600 w-12">Avg</th>
              </template>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="s in formattedSummaryStudents" :key="s.id" class="hover:bg-slate-50">
              <td class="p-3 font-semibold text-slate-800 sticky left-0 bg-white border-r border-slate-200 z-10">
                {{ s.name }}
                <div class="text-[10px] font-mono text-slate-400 font-normal">{{ s.lrn }}</div>
              </td>
              <template v-for="subject in subjectsList" :key="subject">
                <td class="p-2 text-center text-slate-700 border-l border-slate-100">{{ s[`${subject}_t1`] || '-' }}</td>
                <td class="p-2 text-center text-slate-700">{{ s[`${subject}_t2`] || '-' }}</td>
                <td class="p-2 text-center text-slate-700">{{ s[`${subject}_t3`] || '-' }}</td>
                <td class="p-2 text-center font-semibold text-blue-700 bg-blue-50/40">{{ s[`${subject}_avg`] || '-' }}</td>
              </template>
              <td class="p-3 text-center font-bold text-emerald-600 border-l-2 border-slate-200 bg-emerald-50/20">{{ s.finalAverage }}</td>
            </tr>
            <tr v-if="formattedSummaryStudents.length === 0">
              <td :colspan="subjectsList.length * 4 + 2" class="p-8 text-center text-slate-500">
                No students or grades recorded for section <span class="font-bold">{{ selectedSummarySection }}</span>.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 6: LEARNING MATERIALS -->
    <div v-if="activeTab === 'materials'" class="space-y-4">
      <div v-if="materialError" class="p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{{ materialError }}</div>

      <!-- Add Form -->
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-4 space-y-3">
        <h3 class="text-sm font-semibold text-slate-700">Add Learning Material</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Type</label>
            <select v-model="materialForm.type" class="w-full p-2 border rounded-md text-sm">
              <option value="adm">ADM</option>
              <option value="lesson_guide">Lesson Guide</option>
              <option value="reviewer">Reviewer</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Subject</label>
            <input v-model="materialForm.subject" placeholder="e.g. Mathematics" class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Term</label>
            <select v-model="materialForm.term" class="w-full p-2 border rounded-md text-sm">
              <option :value="1">1st Term</option>
              <option :value="2">2nd Term</option>
              <option :value="3">3rd Term</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Title</label>
            <input v-model="materialForm.title" placeholder="e.g. Q1 Reviewer" class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">URL</label>
            <input v-model="materialForm.url" type="url" placeholder="https://..." class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Section <span class="font-normal text-slate-400">(leave blank for all)</span></label>
            <input v-model="materialForm.section" placeholder="e.g. Grade 7 - Narra" class="w-full p-2 border rounded-md text-sm" />
          </div>
        </div>
        <div class="flex justify-end">
          <button @click="addMaterial" :disabled="materialLoading" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition">
            {{ materialLoading ? 'Adding…' : 'Add Material' }}
          </button>
        </div>
      </div>

      <!-- Materials List -->
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600">
              <th class="p-3">Type</th>
              <th class="p-3">Subject</th>
              <th class="p-3">Term</th>
              <th class="p-3">Title</th>
              <th class="p-3">URL</th>
              <th class="p-3">Section</th>
              <th class="p-3">Posted By</th>
              <th class="p-3 text-right">Action</th>
            </tr>
          </thead>
          <tbody class="text-sm divide-y divide-slate-100">
            <tr v-if="activeMaterials.length === 0">
              <td colspan="8" class="p-8 text-center text-slate-500 italic">No materials yet. Use the form above to add one.</td>
            </tr>
            <tr v-for="m in activeMaterials" :key="m.id" class="hover:bg-slate-50">
              <td class="p-3">
                <span class="px-2 py-0.5 rounded-full text-xs font-medium"
                  :class="m.type === 'adm' ? 'bg-blue-100 text-blue-700' : m.type === 'lesson_guide' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'">
                  {{ m.type === 'adm' ? 'ADM' : m.type === 'lesson_guide' ? 'Lesson Guide' : 'Reviewer' }}
                </span>
              </td>
              <td class="p-3 font-semibold">{{ m.subject }}</td>
              <td class="p-3 text-xs">{{ m.term === 1 ? '1st' : m.term === 2 ? '2nd' : '3rd' }} Term</td>
              <td class="p-3">{{ m.title }}</td>
              <td class="p-3 max-w-xs truncate">
                <a :href="m.url" target="_blank" rel="noopener" class="text-blue-600 hover:underline text-xs">{{ m.url }}</a>
              </td>
              <td class="p-3 text-xs text-slate-500">{{ m.section || 'All sections' }}</td>
              <td class="p-3 text-xs font-mono text-slate-500">{{ m.submitted_by || '—' }}</td>
              <td class="p-3 text-right">
                <button @click="deleteMaterial(m.id)" class="text-red-600 text-xs hover:underline">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ── EDIT TEACHER MODAL ─────────────────────────────────────────────── -->
    <div v-if="editingTeacher" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-xl shadow-lg border w-full max-w-md p-6 space-y-4">
        <h2 class="text-lg font-bold text-slate-800">Edit Teacher</h2>
        <div class="space-y-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Name</label>
            <input v-model="editTeacherForm.name" class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Email</label>
            <input v-model="editTeacherForm.email" type="email" class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Role</label>
            <select v-model="editTeacherForm.role" class="w-full p-2 border rounded-md text-sm">
              <option value="teacher">Subject Teacher</option>
              <option value="adviser">Adviser</option>
            </select>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button @click="editingTeacher = null" class="px-4 py-2 text-sm border rounded-lg hover:bg-slate-50">Cancel</button>
          <button @click="saveEditTeacher" class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- ── EDIT STUDENT MODAL ─────────────────────────────────────────────── -->
    <div v-if="editingStudent" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-xl shadow-lg border w-full max-w-md p-6 space-y-4">
        <h2 class="text-lg font-bold text-slate-800">Edit Student</h2>
        <div class="space-y-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">LRN</label>
            <input v-model="editStudentForm.lrn" class="w-full p-2 border rounded-md text-sm font-mono" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Full Name</label>
            <input v-model="editStudentForm.name" class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold text-slate-600 mb-1">Sex</label>
              <select v-model="editStudentForm.sex" class="w-full p-2 border rounded-md text-sm">
                <option value="M">Male</option>
                <option value="F">Female</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-semibold text-slate-600 mb-1">Section</label>
              <input v-model="editStudentForm.section" class="w-full p-2 border rounded-md text-sm" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold text-slate-600 mb-1">Grade Level</label>
              <select v-model="editStudentForm.grade_level" class="w-full p-2 border rounded-md text-sm">
                <option value="">— Not set —</option>
                <option value="7">Grade 7</option>
                <option value="8">Grade 8</option>
                <option value="9">Grade 9</option>
                <option value="10">Grade 10</option>
                <option value="11">Grade 11</option>
                <option value="12">Grade 12</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-semibold text-slate-600 mb-1">Birthday</label>
              <input v-model="editStudentForm.birthday" type="date" class="w-full p-2 border rounded-md text-sm" />
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button @click="editingStudent = null" class="px-4 py-2 text-sm border rounded-lg hover:bg-slate-50">Cancel</button>
          <button @click="saveEditStudent" class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- ── EDIT ADVISER SECTION MODAL ────────────────────────────────────── -->
    <div v-if="editingAdviser" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-xl shadow-lg border w-full max-w-md p-6 space-y-4">
        <h2 class="text-lg font-bold text-slate-800">Edit Adviser Mapping</h2>
        <div class="space-y-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Teacher</label>
            <select v-model="editAdviserForm.teacher_email" class="w-full p-2 border rounded-md text-sm">
              <option v-for="t in teachers" :key="t.id" :value="t.email">{{ t.name }} ({{ t.email }})</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Section</label>
            <input v-model="editAdviserForm.section" class="w-full p-2 border rounded-md text-sm" />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">School Year</label>
            <input v-model="editAdviserForm.school_year" placeholder="e.g. 2026-2027" class="w-full p-2 border rounded-md text-sm" />
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button @click="editingAdviser = null" class="px-4 py-2 text-sm border rounded-lg hover:bg-slate-50">Cancel</button>
          <button @click="saveEditAdviser" class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Changes</button>
        </div>
      </div>
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

            <!-- ── TOP ROW: Left = school header text | Right = attendance table ── -->
            <!-- colgroup mirrors body: 48% left | 4% gutter | 48% right so columns align -->
            <table style="border-collapse:collapse;width:100%;table-layout:fixed;border:none;margin-bottom:2px;">
              <colgroup><col style="width:48%"><col style="width:4%"><col style="width:48%"></colgroup>
              <tr>
                <!-- School header with logos — logos hug the text, right logo stays fully inside this cell -->
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
                        <!-- MAPEH composite row: shows averaged final grade, no per-term values -->
                        <tr v-if="subj.composite" style="background:#f0f4ff;">
                          <td style="border:1px solid #000;padding:2px 3px;font-weight:bold;">{{ subj.label }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;background:#e8ecf8;"></td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;background:#e8ecf8;"></td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;background:#e8ecf8;"></td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;font-weight:bold;">{{ subjectAvg(printingStudent.lrn, subj.key) || '' }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;font-size:7pt;">{{ gradeRemarks(subjectAvg(printingStudent.lrn, subj.key)) }}</td>
                        </tr>
                        <!-- Sub-rows (Music and Arts / PEH) -->
                        <tr v-else-if="subj.sub" style="background:#fafbff;">
                          <td style="border:1px solid #000;padding:2px 3px;padding-left:10px;font-style:italic;">{{ subj.label }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 1') || '' }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 2') || '' }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;">{{ gradeVal(printingStudent.lrn, subj.key, 'term 3') || '' }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;font-weight:bold;">{{ subjectAvg(printingStudent.lrn, subj.key) || '' }}</td>
                          <td style="border:1px solid #000;padding:2px;text-align:center;font-size:7pt;">{{ gradeRemarks(subjectAvg(printingStudent.lrn, subj.key)) }}</td>
                        </tr>
                        <!-- Normal subject row -->
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

                <!-- VERTICAL DIVIDER (fold gutter) -->
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

    <!-- ── EDIT ASSIGNMENT MODAL ──────────────────────────────────────────── -->
    <div v-if="editingAssignment" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-xl shadow-lg border w-full max-w-md p-6 space-y-4">
        <h2 class="text-lg font-bold text-slate-800">Edit Subject Assignment</h2>
        <div class="space-y-3">
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Teacher</label>
            <select v-model="editAssignmentForm.teacher_email" class="w-full p-2 border rounded-md text-sm">
              <option v-for="t in teachers" :key="t.id" :value="t.email">{{ t.name }} ({{ t.email }})</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Section</label>
            <select v-model="editAssignmentForm.section" class="w-full p-2 border rounded-md text-sm">
              <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">Subject</label>
            <select v-model="editAssignmentForm.subject" class="w-full p-2 border rounded-md text-sm">
              <option v-for="sub in subjectsList" :key="sub" :value="sub">{{ sub }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-600 mb-1">School Year</label>
            <input v-model="editAssignmentForm.school_year" placeholder="e.g. 2026-2027" class="w-full p-2 border rounded-md text-sm" />
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button @click="editingAssignment = null" class="px-4 py-2 text-sm border rounded-lg hover:bg-slate-50">Cancel</button>
          <button @click="saveEditAssignment" class="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Changes</button>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
@media print {
  .no-print { display: none !important; }
}
/* SF9 card dark header — used in both preview and printed output */
.section-header th {
  background-color: #002060 !important;
  color: #ffffff !important;
  font-weight: bold;
}
</style>