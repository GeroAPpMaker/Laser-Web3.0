<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../supabase.js'

// Tab navigation state
const activeTab = ref('teachers') // 'teachers' | 'students' | 'grades'
const loading = ref(false)
const errorMessage = ref('')

// Data Collections
const teachers = ref([])
const assignments = ref([])
const students = ref([])
const grades = ref([])

// Filters
const searchTeacher = ref('')
const selectedStudentSection = ref('ALL')
const selectedGradeSection = ref('ALL')
const selectedGradeTerm = ref('term 1')
const selectedGradeSubject = ref('ALL')

const terms = ['term 1', 'term 2', 'term 3']

// Distinct options for filter dropdowns
const uniqueSections = computed(() => {
  const sectionsFromStudents = students.value.map(s => s.section)
  const sectionsFromAssignments = assignments.value.map(a => a.section)
  return [...new Set([...sectionsFromStudents, ...sectionsFromAssignments])].sort()
})

const uniqueSubjects = computed(() => {
  return [...new Set(assignments.value.map(a => a.subject))].sort()
})

// Combined Teacher + Assignments View Model
const teacherOverview = computed(() => {
  return teachers.value.map(teacher => {
    const teacherAssignments = assignments.value.filter(a => a.teacher_email === teacher.email)
    return {
      ...teacher,
      subjectAssignments: teacherAssignments
    }
  }).filter(t => {
    const query = searchTeacher.value.toLowerCase()
    return t.name.toLowerCase().includes(query) || t.email.toLowerCase().includes(query)
  })
})

// Filtered Students List
const filteredStudents = computed(() => {
  if (selectedStudentSection.value === 'ALL') return students.value
  return students.value.filter(s => s.section === selectedStudentSection.value)
})

// Fetch all initial data
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
      fetchStudents(),
      fetchGrades()
    ])
  } catch (err) {
    errorMessage.value = 'Failed to load admin data. Check Supabase connection or permissions.'
  } finally {
    loading.value = false
  }
}

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

async function fetchStudents() {
  const { data, error } = await supabase.from('students').select('*').order('section').order('name')
  if (error) throw error
  students.value = data || []
}

async function fetchGrades() {
  let query = supabase.from('grades').select('*').order('created_at', { ascending: false })

  if (selectedGradeTerm.value) {
    query = query.eq('term', selectedGradeTerm.value)
  }
  if (selectedGradeSection.value !== 'ALL') {
    query = query.eq('section', selectedGradeSection.value)
  }
  if (selectedGradeSubject.value !== 'ALL') {
    query = query.eq('subject', selectedGradeSubject.value)
  }

  const { data, error } = await query
  if (error) throw error
  grades.value = data || []
}

// Re-fetch grades when filter selections change
watch([selectedGradeSection, selectedGradeTerm, selectedGradeSubject], () => {
  if (activeTab.value === 'grades') {
    fetchGrades()
  }
})
</script>

<template>
  <div class="max-w-7xl mx-auto p-6 space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b pb-5">
      <div>
        <h1 class="text-3xl font-bold text-slate-800">Admin Control Center</h1>
        <p class="text-sm text-slate-500">Overview of teachers, student rosters, and system grades</p>
      </div>
      <button 
        @click="loadAllData" 
        :disabled="loading"
        class="self-start sm:self-auto px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm font-medium rounded-lg border transition flex items-center gap-2"
      >
        <svg :class="{'animate-spin': loading}" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Refresh Data
      </button>
    </div>

    <!-- Error Alert -->
    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">
      {{ errorMessage }}
    </div>

    <!-- Tab Navigation -->
    <div class="flex border-b border-slate-200 space-x-8">
      <button
        @click="activeTab = 'teachers'"
        :class="activeTab === 'teachers' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
        class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2"
      >
        <span>Teachers & Assignments</span>
        <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full text-xs font-mono">{{ teachers.length }}</span>
      </button>

      <button
        @click="activeTab = 'students'"
        :class="activeTab === 'students' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
        class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2"
      >
        <span>Students Roster</span>
        <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full text-xs font-mono">{{ students.length }}</span>
      </button>

      <button
        @click="activeTab = 'grades'; fetchGrades()"
        :class="activeTab === 'grades' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
        class="py-3 px-1 border-b-2 text-sm transition-colors flex items-center gap-2"
      >
        <span>Grades Registry</span>
      </button>
    </div>

    <!-- TAB 1: TEACHERS & ASSIGNMENTS -->
    <div v-if="activeTab === 'teachers'" class="space-y-4">
      <div class="flex justify-between items-center bg-white p-4 rounded-lg border">
        <input 
          v-model="searchTeacher"
          type="text"
          placeholder="Search teacher by name or email..."
          class="w-80 p-2 border border-slate-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <span class="text-xs text-slate-500">Showing {{ teacherOverview.length }} teachers</span>
      </div>

      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-600">
              <th class="p-4">Teacher</th>
              <th class="p-4">Role</th>
              <th class="p-4">Sections Handled</th>
              <th class="p-4">Subject Assignments</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200 text-sm">
            <tr v-if="loading"><td colspan="4" class="p-8 text-center text-slate-500">Loading records...</td></tr>
            <tr v-else-if="teacherOverview.length === 0"><td colspan="4" class="p-8 text-center text-slate-500">No teachers found.</td></tr>
            <tr v-for="teacher in teacherOverview" :key="teacher.id" class="hover:bg-slate-50">
              <td class="p-4">
                <div class="font-semibold text-slate-800">{{ teacher.name }}</div>
                <div class="text-xs font-mono text-slate-500">{{ teacher.email }}</div>
              </td>
              <td class="p-4">
                <span 
                  :class="teacher.role === 'adviser' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'" 
                  class="px-2.5 py-1 rounded-full text-xs font-semibold capitalize"
                >
                  {{ teacher.role }}
                </span>
              </td>
              <td class="p-4 text-slate-600">
                {{ teacher.sections_handled || '—' }}
              </td>
              <td class="p-4">
                <div v-if="teacher.subjectAssignments.length > 0" class="flex flex-wrap gap-1.5">
                  <span 
                    v-for="a in teacher.subjectAssignments" 
                    :key="a.id"
                    class="bg-slate-100 border border-slate-200 text-slate-700 text-xs px-2 py-0.5 rounded"
                  >
                    {{ a.section }} ({{ a.subject }})
                  </span>
                </div>
                <span v-else class="text-slate-400 text-xs italic">No subject mapped</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 2: STUDENTS ROSTER -->
    <div v-if="activeTab === 'students'" class="space-y-4">
      <div class="flex items-center justify-between bg-white p-4 rounded-lg border">
        <div class="flex items-center gap-3">
          <label class="text-xs font-semibold text-slate-600 uppercase">Filter Section:</label>
          <select 
            v-model="selectedStudentSection" 
            class="p-2 border border-slate-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="ALL">All Sections</option>
            <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
          </select>
        </div>
        <span class="text-xs text-slate-500">Showing {{ filteredStudents.length }} students</span>
      </div>

      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-600">
              <th class="p-4">LRN</th>
              <th class="p-4">Student Name</th>
              <th class="p-4">Sex</th>
              <th class="p-4">Section</th>
              <th class="p-4">Birthday</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200 text-sm">
            <tr v-if="loading"><td colspan="5" class="p-8 text-center text-slate-500">Loading student roster...</td></tr>
            <tr v-else-if="filteredStudents.length === 0"><td colspan="5" class="p-8 text-center text-slate-500">No students recorded.</td></tr>
            <tr v-for="s in filteredStudents" :key="s.id" class="hover:bg-slate-50">
              <td class="p-4 font-mono text-slate-600 text-xs">{{ s.lrn }}</td>
              <td class="p-4 font-semibold text-slate-800">{{ s.name }}</td>
              <td class="p-4">
                <span :class="s.sex === 'MALE' ? 'text-blue-600' : 'text-pink-600'" class="text-xs font-medium">
                  {{ s.sex }}
                </span>
              </td>
              <td class="p-4 text-slate-600">{{ s.section }}</td>
              <td class="p-4 text-slate-500 text-xs">{{ s.birthday }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 3: GRADES REGISTRY -->
    <div v-if="activeTab === 'grades'" class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 bg-white p-4 rounded-lg border">
        <div>
          <label class="block text-xs font-semibold text-slate-600 uppercase mb-1">Term</label>
          <select v-model="selectedGradeTerm" class="w-full p-2 border border-slate-300 rounded-md text-sm capitalize">
            <option v-for="t in terms" :key="t" :value="t">{{ t }}</option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-semibold text-slate-600 uppercase mb-1">Section</label>
          <select v-model="selectedGradeSection" class="w-full p-2 border border-slate-300 rounded-md text-sm">
            <option value="ALL">All Sections</option>
            <option v-for="sec in uniqueSections" :key="sec" :value="sec">{{ sec }}</option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-semibold text-slate-600 uppercase mb-1">Subject</label>
          <select v-model="selectedGradeSubject" class="w-full p-2 border border-slate-300 rounded-md text-sm">
            <option value="ALL">All Subjects</option>
            <option v-for="sub in uniqueSubjects" :key="sub" :value="sub">{{ sub }}</option>
          </select>
        </div>
      </div>

      <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-600">
              <th class="p-4">Student LRN</th>
              <th class="p-4">Subject</th>
              <th class="p-4">Section</th>
              <th class="p-4">Term</th>
              <th class="p-4 text-center">Grade</th>
              <th class="p-4">Submitted By</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200 text-sm">
            <tr v-if="loading"><td colspan="6" class="p-8 text-center text-slate-500">Querying submitted grades...</td></tr>
            <tr v-else-if="grades.length === 0"><td colspan="6" class="p-8 text-center text-slate-500">No grades match the current filters.</td></tr>
            <tr v-for="g in grades" :key="g.id" class="hover:bg-slate-50">
              <td class="p-4 font-mono text-slate-600 text-xs">{{ g.lrn }}</td>
              <td class="p-4 font-semibold text-slate-800">{{ g.subject }}</td>
              <td class="p-4 text-slate-600">{{ g.section }}</td>
              <td class="p-4 text-xs capitalize">{{ g.term }}</td>
              <td class="p-4 text-center font-bold text-slate-800 font-mono">{{ g.grade }}</td>
              <td class="p-4 text-xs font-mono text-slate-500">{{ g.teacher_email }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>