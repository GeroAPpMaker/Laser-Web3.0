<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '../supabase.js' // Updated to match your root src folder

// State
const loading = ref(false)
const saving = ref(false)
const statusMessage = ref({ type: '', text: '' })
let messageTimer = null

const teacherEmail = ref('')
const assignments = ref([])
const students = ref([])
const grades = ref({}) // Key: LRN, Value: numeric grade

// Selection Filters
const selectedAssignment = ref(null)
const selectedTerm = ref('term 1')
const schoolYear = ref('2026-2027') // Ideally fetched from a settings table

// Updated to term 3 only
const terms = ['term 1', 'term 2', 'term 3']

// Fetch Logged-in Teacher's Assignments
onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser()
  if (user?.email) {
    teacherEmail.value = user.email
    await fetchAssignments()
  } else {
    showMessage('error', 'Authentication error. Please log in again.')
  }
})

onUnmounted(() => {
  if (messageTimer) clearTimeout(messageTimer)
})

async function fetchAssignments() {
  loading.value = true
  const { data, error } = await supabase
    .from('teacher_subject_assignments')
    .select('*')
    .eq('teacher_email', teacherEmail.value)

  if (error) {
    showMessage('error', 'Failed to load teacher assignments.')
  } else {
    assignments.value = data || []
    if (data?.length) {
      selectedAssignment.value = data[0]
    }
  }
  loading.value = false
}

// Fetch Students & Existing Grades when selection changes
watch([selectedAssignment, selectedTerm], async () => {
  if (!selectedAssignment.value) return
  await loadClassData()
}, { deep: true })

async function loadClassData() {
  loading.value = true
  statusMessage.value = { type: '', text: '' }
  grades.value = {}
  students.value = []

  const { section: currentSection, subject: currentSubject } = selectedAssignment.value

  // 1. Fetch Students in Section
  const { data: studentData, error: studentErr } = await supabase
    .from('students')
    .select('lrn, name')
    .eq('section', currentSection)
    .order('name', { ascending: true })

  if (studentErr) {
    showMessage('error', 'Failed to load student list.')
    loading.value = false
    return
  }

  students.value = studentData || []

  // 2. Fetch Existing Grades
  const { data: gradeData, error: gradeErr } = await supabase
    .from('grades')
    .select('lrn, grade')
    .match({
      section: currentSection,
      subject: currentSubject,
      term: selectedTerm.value,
      school_year: schoolYear.value
    })

  if (!gradeErr && gradeData) {
    gradeData.forEach(item => {
      grades.value[item.lrn] = item.grade
    })
  }

  loading.value = false
}

// Save or Update Grades (Batch Upsert)
async function saveGrades() {
  saving.value = true
  statusMessage.value = { type: '', text: '' }

  const payload = []
  let hasValidationError = false

  students.value.forEach(s => {
    const rawGrade = grades.value[s.lrn]
    if (rawGrade !== undefined && rawGrade !== null && rawGrade !== '') {
      const parsedGrade = parseFloat(rawGrade)
      
      // Strict validation constraint before hitting the database
      if (isNaN(parsedGrade) || parsedGrade < 0 || parsedGrade > 100) {
        hasValidationError = true
      } else {
        payload.push({
          lrn: s.lrn,
          subject: selectedAssignment.value.subject,
          term: selectedTerm.value,
          section: selectedAssignment.value.section,
          teacher_email: teacherEmail.value,
          school_year: schoolYear.value,
          grade: parsedGrade,
          updated_at: new Date().toISOString()
        })
      }
    }
  })

  if (hasValidationError) {
    showMessage('error', 'Invalid input: Grades must be a number between 0 and 100.')
    saving.value = false
    return
  }

  if (payload.length === 0) {
    showMessage('error', 'No valid grades entered to save.')
    saving.value = false
    return
  }

  const { error } = await supabase
    .from('grades')
    .upsert(payload, { onConflict: 'lrn,subject,term,section,school_year' })

  if (error) {
    showMessage('error', `Failed to save grades: ${error.message}`)
  } else {
    showMessage('success', 'Grades saved successfully!')
  }
  
  saving.value = false
}

function showMessage(type, text) {
  statusMessage.value = { type, text }
  if (messageTimer) clearTimeout(messageTimer)
  
  // Auto-dismiss success messages after 4 seconds
  if (type === 'success') {
    messageTimer = setTimeout(() => {
      statusMessage.value = { type: '', text: '' }
    }, 4000)
  }
}
</script>

<template>
  <div class="max-w-5xl mx-auto p-6 bg-white rounded-xl shadow-md space-y-6">
    <div class="border-b pb-4 flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Teacher Grade Entry</h1>
        <p class="text-sm text-gray-500">Logged in as: <span class="font-semibold">{{ teacherEmail || 'Loading...' }}</span></p>
      </div>
      <span class="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-xs font-semibold">
        S.Y. {{ schoolYear }}
      </span>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 bg-gray-50 p-4 rounded-lg">
      <div>
        <label for="assignment-select" class="block text-xs font-semibold text-gray-600 uppercase mb-1">Class Assignment</label>
        <select 
          id="assignment-select"
          v-model="selectedAssignment" 
          :disabled="loading || saving"
          class="w-full border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring-blue-500 p-2 border disabled:bg-gray-100"
        >
          <option v-if="assignments.length === 0" disabled value="null">No assignments found</option>
          <option v-for="assign in assignments" :key="assign.id" :value="assign">
            {{ assign.section }} — {{ assign.subject }}
          </option>
        </select>
      </div>

      <div>
        <label for="term-select" class="block text-xs font-semibold text-gray-600 uppercase mb-1">Grading Term</label>
        <select 
          id="term-select"
          v-model="selectedTerm" 
          :disabled="loading || saving"
          class="w-full border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring-blue-500 p-2 border capitalize disabled:bg-gray-100"
        >
          <option v-for="t in terms" :key="t" :value="t" class="capitalize">{{ t }}</option>
        </select>
      </div>
    </div>

    <Transition name="fade">
      <div 
        v-if="statusMessage.text" 
        :class="statusMessage.type === 'error' ? 'bg-red-50 text-red-700 border-red-200' : 'bg-green-50 text-green-700 border-green-200'"
        class="p-3 rounded-md border text-sm font-medium transition-all"
        role="alert"
      >
        {{ statusMessage.text }}
      </div>
    </Transition>

    <div class="overflow-x-auto border rounded-lg">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-gray-100 text-gray-700 text-xs uppercase font-semibold border-b">
            <th class="p-3 w-1/4">LRN</th>
            <th class="p-3 w-2/4">Student Name</th>
            <th class="p-3 w-1/4 text-center">Grade (0 - 100)</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <tr v-if="loading">
            <td colspan="3" class="p-8 text-center text-gray-500 flex-col items-center">
              <svg class="animate-spin h-5 w-5 mr-3 text-blue-500 inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
              Loading roster...
            </td>
          </tr>
          <tr v-else-if="students.length === 0">
            <td colspan="3" class="p-6 text-center text-gray-500">No students found for this section.</td>
          </tr>
          <tr v-for="student in students" :key="student.lrn" class="hover:bg-gray-50 transition-colors">
            <td class="p-3 font-mono text-sm text-gray-600">{{ student.lrn }}</td>
            <td class="p-3 font-medium text-gray-800">{{ student.name }}</td>
            <td class="p-3 text-center">
              <input 
                type="number" 
                v-model.number="grades[student.lrn]" 
                :disabled="saving"
                min="0" 
                max="100" 
                step="0.01"
                placeholder="—"
                class="w-24 text-center border-gray-300 border rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-1.5 disabled:bg-gray-100 disabled:text-gray-500"
                :class="{'border-red-400 bg-red-50': grades[student.lrn] !== undefined && (grades[student.lrn] < 0 || grades[student.lrn] > 100)}"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="flex justify-end pt-4">
      <button 
        @click="saveGrades" 
        :disabled="saving || loading || students.length === 0"
        class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md shadow transition-all disabled:opacity-50 flex items-center gap-2"
      >
        <span v-if="saving">
          <svg class="animate-spin h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path></svg>
          Saving...
        </span>
        <span v-else>Save Grades</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>