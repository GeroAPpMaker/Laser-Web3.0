<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '../supabase.js'
import { useRouter } from 'vue-router'

const router = useRouter()
const loading = ref(true)
const isRefreshing = ref(false)
const errorMessage = ref('')
const currentUserEmail = ref('')
const mySection = ref(null)

// Updated to 3 terms with exact matching strings
const termsList = ref(['term 1', 'term 2', 'term 3'])
const selectedTerm = ref('term 1')
const rawStudentsData = ref([])
let realtimeChannel = null

// Transmission States
const isReviewing = ref(false)
const isFinalized = ref(false)
const isTransmitting = ref(false)
const transmissionMessage = ref('')

// Reset transmission state if term changes
watch(selectedTerm, () => {
  isReviewing.value = false
  isFinalized.value = false
  transmissionMessage.value = ''
})

// Updated Core Subjects: Removed MAPEH, added MA and PEH
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

onMounted(async () => {
  await loadAdviserData()
  setupRealtimeSubscription()
})

onUnmounted(() => {
  if (realtimeChannel) {
    supabase.removeChannel(realtimeChannel)
  }
})

function setupRealtimeSubscription() {
  realtimeChannel = supabase
    .channel('grades-updates')
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'grades' },
      () => {
        refreshData()
      }
    )
    .subscribe()
}

async function refreshData() {
  isRefreshing.value = true
  await loadAdviserData()
  isRefreshing.value = false
}

async function loadAdviserData() {
  if (!isRefreshing.value) loading.value = true
  errorMessage.value = ''
  
  try {
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) throw new Error('Not authenticated.')
    currentUserEmail.value = user.email

    // 1. Get assigned section
    const { data: sectionData, error: sectionError } = await supabase
      .from('adviser_sections')
      .select('section')
      .eq('teacher_email', currentUserEmail.value)
      .maybeSingle()
      
    if (sectionError || !sectionData) {
      throw new Error(`No advisory section assigned to ${currentUserEmail.value}`)
    }
    mySection.value = sectionData.section

    // 2. Fetch students in this section
    const { data: students, error: studentError } = await supabase
      .from('students')
      .select('*')
      .eq('section', mySection.value)
      .order('name')

    if (studentError) throw studentError
    if (!students || students.length === 0) {
      rawStudentsData.value = []
      return
    }

    // 3. Fetch grades for these students
    const studentLrns = students.map(s => s.lrn)
    const { data: grades, error: gradeError } = await supabase
      .from('grades')
      .select('*')
      .in('lrn', studentLrns)

    if (gradeError) throw gradeError

    // 4. Combine students and grades in memory
    rawStudentsData.value = students.map(s => ({
      ...s,
      grades: (grades || []).filter(g => String(g.lrn).trim() === String(s.lrn).trim())
    }))

  } catch (err) {
    console.error('TermGradeView Error:', err)
    errorMessage.value = err.message
  } finally {
    loading.value = false
  }
}

// Map subject grades to columns per student with flexible string matching
const formattedStudents = computed(() => {
  return rawStudentsData.value.map(student => {
    // Case-insensitive & trim-safe term filtering
    const termGrades = student.grades.filter(
      g => String(g.term).toLowerCase().trim() === selectedTerm.value.toLowerCase().trim()
    )
    
    const subjectGrades = {}
    let total = 0
    let count = 0

    termGrades.forEach(g => {
      // Find matching subject from subjectList regardless of casing
      const matchedSubject = subjectsList.value.find(
        s => s.toLowerCase().trim() === String(g.subject).toLowerCase().trim()
      )

      const key = matchedSubject || g.subject
      subjectGrades[key] = g.grade

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

function goBack() {
  router.push({ name: 'adviser-dashboard' })
}

// --- Transmission Methods ---
function reviewGrades() {
  isReviewing.value = true
  alert(`Grades for ${selectedTerm.value} are now in review mode. Please verify all entries.`)
}

function finalizeGrades() {
  if (!confirm(`Are you sure you want to finalize ${selectedTerm.value}? This will lock further edits.`)) return
  isFinalized.value = true
  isReviewing.value = false
}

async function transmitGrades() {
  if (!isFinalized.value) {
    alert("Please finalize the grades before transmitting.")
    return
  }

  isTransmitting.value = true
  transmissionMessage.value = "Transmitting to Google Sheets..."

  const GOOGLE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbz2hsPLhUDIt8rPyiWq1VnzblbdwqGIXvw42okKIhibjnL44zVTiBZOeNHJRSU_xVbb/exec' 

  try {
    const payload = {
      section: mySection.value,
      teacherEmail: currentUserEmail.value,
      term: selectedTerm.value,
      grades: formattedStudents.value 
    }

    const response = await fetch(GOOGLE_SCRIPT_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      body: JSON.stringify(payload)
    })

    const result = await response.json()

    if (result.status === 'error') throw new Error(result.message)
    transmissionMessage.value = `✅ ${selectedTerm.value} Successfully transmitted!`
    
  } catch (error) {
    transmissionMessage.value = `❌ Transmission failed: ${error.message}`
  } finally {
    isTransmitting.value = false
  }
}
</script>

<template>
  <div class="max-w-7xl mx-auto p-6 space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between border-b pb-5 gap-4">
      <div>
        <div class="flex items-center space-x-4">
          <button @click="goBack" class="text-slate-500 hover:text-slate-800 text-sm font-medium">&larr; Back</button>
          <h1 class="text-3xl font-bold text-slate-800">Term Grades Summary</h1>
          
          <!-- Refresh Button -->
          <button @click="refreshData" class="text-slate-400 hover:text-blue-600 transition-colors" title="Force Refresh">
            <svg :class="{'animate-spin text-blue-600': isRefreshing}" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>
        </div>
        <p v-if="mySection" class="text-sm text-slate-600 mt-2">
          Advisory Section: <span class="font-bold text-blue-600">{{ mySection }}</span>
        </p>
      </div>
      
      <!-- 3-Term Selector -->
      <div class="flex bg-slate-100 p-1 rounded-lg self-start sm:self-auto">
        <button v-for="term in termsList" :key="term"
          @click="selectedTerm = term"
          :class="['px-4 py-2 rounded-md text-sm font-medium capitalize transition-colors', 
                  selectedTerm === term ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-600 hover:text-slate-800']">
          {{ term }}
        </button>
      </div>
    </div>

    <!-- TRANSMISSION TOOLBAR -->
    <div v-if="!loading && mySection" class="flex flex-wrap items-center gap-3 p-4 bg-white border border-slate-200 rounded-lg shadow-sm">
      <button 
        @click="reviewGrades" 
        :class="isReviewing ? 'bg-amber-100 text-amber-800 border-amber-300' : 'bg-white text-slate-700 border-slate-300 hover:bg-slate-50'"
        class="px-4 py-2 border rounded-md text-sm font-medium transition capitalize"
      >
        Review {{ selectedTerm }}
      </button>
      
      <button 
        @click="finalizeGrades" 
        :disabled="!isReviewing || isFinalized"
        class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-md text-sm font-medium transition capitalize"
      >
        Finalize {{ selectedTerm }}
      </button>
      
      <button 
        @click="transmitGrades" 
        :disabled="!isFinalized || isTransmitting"
        class="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-md text-sm font-medium transition flex items-center gap-2 capitalize"
      >
        <svg v-if="isTransmitting" class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Transmit {{ selectedTerm }}
      </button>

      <span v-if="transmissionMessage" class="ml-auto text-sm font-medium text-slate-600">
        {{ transmissionMessage }}
      </span>
    </div>

    <!-- State Messages -->
    <div v-if="loading" class="text-slate-500">Loading grades matrix...</div>
    <div v-if="errorMessage" class="p-4 bg-red-50 text-red-700 rounded-lg text-sm border border-red-200">
      {{ errorMessage }}
    </div>

    <!-- Data Table -->
    <div v-if="!loading && !errorMessage" class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-x-auto">
      <table class="w-full text-left border-collapse min-w-max">
        <thead>
          <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600 border-b border-slate-200">
            <th class="p-4 sticky left-0 bg-slate-50 border-r border-slate-200 z-10 w-64">Student Name</th>
            <th class="p-4 text-center" v-for="subject in subjectsList" :key="subject">
              {{ subject }}
            </th>
            <th class="p-4 text-center border-l border-slate-200 text-blue-700">Average</th>
          </tr>
        </thead>
        <tbody class="text-sm divide-y divide-slate-100">
          <tr v-for="s in formattedStudents" :key="s.id" class="hover:bg-slate-50">
            <!-- Pinned Name Column -->
            <td class="p-4 font-semibold text-slate-800 sticky left-0 bg-white border-r border-slate-200 z-10 group-hover:bg-slate-50">
              {{ s.name }}
              <div class="text-[10px] font-mono text-slate-400 font-normal mt-0.5">{{ s.lrn }}</div>
            </td>
            
            <!-- Dynamic Subject Columns -->
            <td class="p-4 text-center text-slate-700 font-medium" v-for="subject in subjectsList" :key="subject">
              {{ s[subject] || '-' }}
            </td>
            
            <!-- Calculated Average -->
            <td class="p-4 text-center font-bold text-blue-600 border-l border-slate-100 bg-blue-50/10">
              {{ s.average }}
            </td>
          </tr>
          
          <tr v-if="formattedStudents.length === 0">
            <td :colspan="subjectsList.length + 2" class="p-8 text-center text-slate-500 text-sm">
              No students found in {{ mySection }}.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>