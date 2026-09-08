<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../supabase.js'

// Tab navigation state ('teachers' | 'advisers' | 'students' | 'grades' | 'summary')
const activeTab = ref('teachers') 
const loading = ref(false)
const errorMessage = ref('')

// Data Collections
const teachers = ref([])
const assignments = ref([])
const adviserSections = ref([])
const students = ref([])
const grades = ref([])
const matrixGrades = ref([]) // Grades for the summary matrix tab

// Core 8 Subjects List
const subjectsList = ref([
  'Filipino',
  'English',
  'Mathematics',
  'Science',
  'Araling Panlipunan',
  'EsP',
  'TLE',
  'MAPEH'
])

// Filters
const searchTeacher = ref('')
const selectedStudentSection = ref('ALL')
const selectedGradeSection = ref('ALL')
const selectedGradeTerm = ref('term 1')
const selectedGradeSubject = ref('ALL')
const terms = ['term 1', 'term 2', 'term 3']

// Summary Tab Filters
const selectedSummarySection = ref('')
const selectedSummaryTerm = ref('term 1')

// New Record States (for inline Add forms)
const newTeacher = ref({ name: '', email: '', role: 'subject_teacher' })
const newAssignment = ref({ teacher_email: '', section: '', subject: '' })
const newAdviserSection = ref({ teacher_email: '', section: '', school_year: '2026-2027' })
const newStudent = ref({ lrn: '', name: '', sex: 'MALE', section: '', birthday: '' })
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

// Combined Teacher + Assignments View Model
const teacherOverview = computed(() => {
  return teachers.value.map(teacher => {
    return {
      ...teacher,
      subjectAssignments: assignments.value.filter(a => a.teacher_email === teacher.email)
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

// Computed Matrix Data for the Term Summary Tab
const formattedSummaryStudents = computed(() => {
  if (!selectedSummarySection.value) return []

  const sectionStudents = students.value.filter(s => s.section === selectedSummarySection.value)

  return sectionStudents.map(student => {
    // Match grades for this student & selected term
    const studentGrades = matrixGrades.value.filter(g => 
      g.lrn === student.lrn && 
      g.term?.toLowerCase() === selectedSummaryTerm.value.toLowerCase()
    )

    const subjectGrades = {}
    let total = 0
    let count = 0

    studentGrades.forEach(g => {
      subjectGrades[g.subject] = g.grade
      if (g.grade !== null && g.grade !== undefined && g.grade !== '') {
        total += Number(g.grade)
        count++
      }
    })

    const average = count > 0 ? (total / count).toFixed(2) : 'N/A'

    return {
      id: student.id,
      lrn: student.lrn,
      name: student.name,
      average,
      ...subjectGrades
    }
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
    .ilike('term', selectedSummaryTerm.value)
    
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

watch([selectedSummarySection, selectedSummaryTerm, activeTab], () => {
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
  newTeacher.value = { name: '', email: '', role: 'subject_teacher' }
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
  newAssignment.value = { teacher_email: '', section: '', subject: '' }
  await fetchAssignments()
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
  newStudent.value = { lrn: '', name: '', sex: 'MALE', section: '', birthday: '' }
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
    </div>

    <!-- TAB 1: TEACHERS & ASSIGNMENTS -->
    <div v-if="activeTab === 'teachers'" class="space-y-8">
      <div>
        <div class="flex justify-between items-center mb-4">
          <input v-model="searchTeacher" type="text" placeholder="Search teacher..." class="w-80 p-2 border border-slate-300 rounded-md text-sm" />
        </div>
        <div class="bg-white rounded-xl border shadow-sm overflow-hidden mb-6">
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
                    <option value="subject_teacher">Subject Teacher</option>
                    <option value="adviser">Adviser</option>
                  </select>
                </td>
                <td class="p-2 text-slate-400 italic text-xs">Assigned separately below</td>
                <td class="p-2 text-right">
                  <button @click="addTeacher" class="bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700">Add Teacher</button>
                </td>
              </tr>
              <!-- Data Rows -->
              <tr v-for="teacher in teacherOverview" :key="teacher.id" class="border-t hover:bg-slate-50">
                <td class="p-3 font-semibold">{{ teacher.name }} <div class="text-xs text-slate-500">{{ teacher.email }}</div></td>
                <td class="p-3"><span class="px-2 py-1 bg-slate-100 rounded text-xs">{{ teacher.role }}</span></td>
                <td class="p-3">
                  <div class="flex flex-wrap gap-1">
                    <span v-for="a in teacher.subjectAssignments" :key="a.id" class="bg-slate-100 text-xs px-2 py-0.5 rounded border flex items-center gap-1">
                      {{ a.section }} ({{ a.subject }})
                      <button @click="deleteRecord('teacher_subject_assignments', a.id, fetchAssignments)" class="text-red-500 hover:text-red-700 ml-1">&times;</button>
                    </span>
                  </div>
                </td>
                <td class="p-3 text-right">
                  <button @click="deleteRecord('teachers', teacher.id, fetchTeachers)" class="text-red-600 text-xs hover:underline">Delete</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <!-- Add Assignment Section -->
        <h3 class="text-lg font-semibold text-slate-700 mb-2">Map Subject Assignment</h3>
        <div class="flex gap-2 items-center bg-white p-3 border rounded-lg shadow-sm">
          <input v-model="newAssignment.teacher_email" placeholder="Teacher Email" class="p-2 border rounded text-sm flex-1" />
          <input v-model="newAssignment.section" placeholder="Section" class="p-2 border rounded text-sm flex-1" />
          <input v-model="newAssignment.subject" placeholder="Subject" class="p-2 border rounded text-sm flex-1" />
          <button @click="addAssignment" class="bg-slate-800 text-white px-4 py-2 rounded text-sm hover:bg-slate-700">Assign Subject</button>
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
              <td class="p-2"><input v-model="newAdviserSection.teacher_email" placeholder="Teacher Email" class="w-full p-2 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newAdviserSection.section" placeholder="Section" class="w-full p-2 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newAdviserSection.school_year" placeholder="e.g. 2026-2027" class="w-full p-2 border rounded text-xs" /></td>
              <td class="p-2 text-right"><button @click="addAdviserSection" class="bg-blue-600 text-white px-3 py-1.5 rounded text-xs hover:bg-blue-700">Add Adviser Mapping</button></td>
            </tr>
            <!-- Data -->
            <tr v-for="adv in adviserSections" :key="adv.id" class="hover:bg-slate-50">
              <td class="p-4 font-mono text-slate-600 text-xs">{{ adv.teacher_email }}</td>
              <td class="p-4 font-semibold">{{ adv.section }}</td>
              <td class="p-4 text-xs text-slate-500">{{ adv.school_year || 'N/A' }}</td>
              <td class="p-4 text-right">
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
                  <option>MALE</option><option>FEMALE</option>
                </select>
              </td>
              <td class="p-2"><input v-model="newStudent.section" placeholder="Section" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2"><input v-model="newStudent.birthday" type="date" class="w-full p-1 border rounded text-xs" /></td>
              <td class="p-2 text-right"><button @click="addStudent" class="bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700">Add Student</button></td>
            </tr>
            <!-- Data -->
            <tr v-for="s in filteredStudents" :key="s.id" class="border-t hover:bg-slate-50">
              <td class="p-3 font-mono text-xs">{{ s.lrn }}</td>
              <td class="p-3 font-semibold">{{ s.name }}</td>
              <td class="p-3 text-xs">{{ s.sex }}</td>
              <td class="p-3">{{ s.section }}</td>
              <td class="p-3 text-xs">{{ s.birthday }}</td>
              <td class="p-3 text-right space-x-3">
                <button @click="transferStudent(s)" class="text-blue-600 text-xs hover:underline">Transfer</button>
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

    <!-- TAB 5: TERM SUMMARY MATRIX (NEW) -->
    <div v-if="activeTab === 'summary'" class="space-y-4">
      <!-- Section & Term Selector Controls -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between bg-white p-4 rounded-lg border gap-4">
        <div class="flex items-center gap-3">
          <label class="text-xs font-semibold uppercase text-slate-600">Select Section:</label>
          <select v-model="selectedSummarySection" class="p-2 border rounded-md text-sm font-semibold text-slate-800 bg-slate-50">
            <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
          </select>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs font-semibold uppercase text-slate-600 mr-2">Term:</span>
          <div class="flex bg-slate-100 p-1 rounded-lg">
            <button 
              v-for="term in terms" :key="term"
              @click="selectedSummaryTerm = term"
              :class="['px-3 py-1.5 rounded-md text-xs font-medium capitalize transition-colors', 
                      selectedSummaryTerm === term ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-600 hover:text-slate-800']"
            >
              {{ term }}
            </button>
          </div>
        </div>
      </div>

      <!-- Matrix Table -->
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-x-auto">
        <table class="w-full text-left border-collapse min-w-max">
          <thead>
            <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600 border-b border-slate-200">
              <th class="p-4 sticky left-0 bg-slate-50 border-r border-slate-200 z-10 w-64">Student Name</th>
              <th class="p-4 text-center" v-for="subject in subjectsList" :key="subject">
                {{ subject }}
              </th>
              <th class="p-4 text-center border-l border-slate-200 text-emerald-700 bg-emerald-50/40">Average</th>
            </tr>
          </thead>
          <tbody class="text-sm divide-y divide-slate-100">
            <tr v-for="s in formattedSummaryStudents" :key="s.id" class="hover:bg-slate-50">
              <!-- Pinned Student Name Column -->
              <td class="p-4 font-semibold text-slate-800 sticky left-0 bg-white border-r border-slate-200 z-10">
                {{ s.name }}
                <div class="text-[10px] font-mono text-slate-400 font-normal mt-0.5">{{ s.lrn }}</div>
              </td>
              
              <!-- 8 Fixed Subject Columns -->
              <td class="p-4 text-center text-slate-700 font-medium" v-for="subject in subjectsList" :key="subject">
                {{ s[subject] || '-' }}
              </td>
              
              <!-- Calculated Average -->
              <td class="p-4 text-center font-bold text-emerald-600 border-l border-slate-100 bg-emerald-50/20">
                {{ s.average }}
              </td>
            </tr>
            
            <tr v-if="formattedSummaryStudents.length === 0">
              <td :colspan="subjectsList.length + 2" class="p-8 text-center text-slate-500 text-sm">
                No students or grades recorded for section <span class="font-bold">{{ selectedSummarySection }}</span> in <span class="capitalize">{{ selectedSummaryTerm }}</span>.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

  </div>
</template>