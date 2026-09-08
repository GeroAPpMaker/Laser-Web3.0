<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabase.js'
import { useRouter } from 'vue-router'

const router = useRouter()
const loading = ref(true)
const errorMessage = ref('')
const currentUserEmail = ref('')
const mySection = ref(null)

const selectedTerm = ref('Term 1')
const rawStudentsData = ref([])

onMounted(async () => {
  await loadAdviserData()
})

async function loadAdviserData() {
  loading.value = true
  errorMessage.value = ''
  try {
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) throw new Error('Not authenticated.')
    currentUserEmail.value = user.email

    // 1. Get assigned section (using maybeSingle to prevent crash if empty)
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

    // 3. Fetch grades for these students (matches on LRN or ID)
    const studentLrns = students.map(s => s.lrn)
    const { data: grades, error: gradeError } = await supabase
      .from('grades')
      .select('*')
      .in('lrn', studentLrns) // Adjust column to 'student_id' if your grades table uses student_id

    if (gradeError) throw gradeError

    // 4. Combine students and grades in memory
    rawStudentsData.value = students.map(s => ({
      ...s,
      grades: (grades || []).filter(g => g.lrn === s.lrn)
    }))

  } catch (err) {
    console.error('TermGradeView Error:', err)
    errorMessage.value = err.message
  } finally {
    loading.value = false
  }
}

// Extract unique subjects for table headers based on the current term
const dynamicSubjects = computed(() => {
  const subjects = new Set()
  rawStudentsData.value.forEach(student => {
    student.grades.forEach(g => {
      if (g.term === selectedTerm.value) subjects.add(g.subject)
    })
  })
  return Array.from(subjects).sort()
})

// Pivot data to map subjects as columns per student
const formattedStudents = computed(() => {
  return rawStudentsData.value.map(student => {
    const termGrades = student.grades.filter(g => g.term === selectedTerm.value)
    const subjectGrades = {}
    let total = 0
    let count = 0

    termGrades.forEach(g => {
      subjectGrades[g.subject] = g.grade
      if (g.grade) {
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
</script>

<template>
  <div class="max-w-7xl mx-auto p-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between border-b pb-5">
      <div>
        <div class="flex items-center space-x-4">
          <button @click="goBack" class="text-slate-500 hover:text-slate-800 text-sm font-medium">&larr; Back</button>
          <h1 class="text-3xl font-bold text-slate-800">Term Grades Summary</h1>
        </div>
        <p v-if="mySection" class="text-sm text-slate-600 mt-2">
          Advisory Section: <span class="font-bold text-blue-600">{{ mySection }}</span>
        </p>
      </div>
      
      <!-- Term Selector -->
      <div class="flex bg-slate-100 p-1 rounded-lg">
        <button v-for="term in ['Term 1', 'Term 2', 'Term 3']" :key="term"
          @click="selectedTerm = term"
          :class="['px-4 py-2 rounded-md text-sm font-medium transition-colors', 
                  selectedTerm === term ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-600 hover:text-slate-800']">
          {{ term }}
        </button>
      </div>
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
            <th class="p-4 text-center" v-for="subject in dynamicSubjects" :key="subject">
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
            
            <!-- Dynamic Subject Grades -->
            <td class="p-4 text-center text-slate-700 font-medium" v-for="subject in dynamicSubjects" :key="subject">
              {{ s[subject] || '-' }}
            </td>
            
            <!-- Calculated Average -->
            <td class="p-4 text-center font-bold text-blue-600 border-l border-slate-100 bg-blue-50/10">
              {{ s.average }}
            </td>
          </tr>
          
          <tr v-if="formattedStudents.length === 0">
            <td :colspan="dynamicSubjects.length + 2" class="p-8 text-center text-slate-500 text-sm">
              No grades recorded for {{ selectedTerm }}.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>