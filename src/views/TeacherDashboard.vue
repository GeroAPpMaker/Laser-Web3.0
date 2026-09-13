<script setup>
import { ref, onMounted, watch } from 'vue'
import { supabase } from '../supabase.js'

const loading = ref(true)
const saving = ref(false)
const syncMessage = ref('')
const isSyncing = ref(false)

const currentUserEmail = ref('')
const assignedSubjects = ref([])
const selectedAssignment = ref(null)
const selectedTerm = ref('term 1')

const students = ref([])
const gradeInputs = ref({})

// Explicitly includes MA and PEH
const ALL_SUBJECTS = ['Filipino', 'English', 'Mathematics', 'Science', 'AP', 'ValuesEd', 'TLE', 'MA', 'PEH']

onMounted(async () => {
  await loadTeacherAssignments()
})

async function loadTeacherAssignments() {
  loading.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    currentUserEmail.value = user.email

    const { data, error } = await supabase
      .from('teacher_subject_assignments')
      .select('section, subject, school_year')
      .eq('teacher_email', currentUserEmail.value)

    if (error) throw error
    assignedSubjects.value = data || []

    if (assignedSubjects.value.length > 0) {
      selectedAssignment.value = assignedSubjects.value[0]
      await loadGradesForSelection()
    }
  } catch (err) {
    console.error('Error loading assignments:', err.message)
  } finally {
    loading.value = false
  }
}

async function loadGradesForSelection() {
  if (!selectedAssignment.value) return
  loading.value = true
  
  const { section, subject } = selectedAssignment.value

  const { data: studentList } = await supabase
    .from('students')
    .select('lrn, name, sex')
    .eq('section', section)
    .order('name')

  students.value = studentList || []

  const { data: existingGrades } = await supabase
    .from('grades')
    .select('lrn, grade')
    .eq('section', section)
    .eq('subject', subject)
    .eq('term', selectedTerm.value)

  const map = {}
  existingGrades?.forEach(g => { map[g.lrn] = g.grade })
  gradeInputs.value = map
  loading.value = false
}

watch([selectedAssignment, selectedTerm], () => {
  loadGradesForSelection()
})

async function saveGradesToSupabase() {
  if (!selectedAssignment.value) return
  saving.value = true

  const { section, subject, school_year } = selectedAssignment.value
  const recordsToUpsert = []

  Object.entries(gradeInputs.value).forEach(([lrn, grade]) => {
    if (grade !== '' && grade !== null) {
      recordsToUpsert.push({
        lrn,
        subject,
        term: selectedTerm.value,
        section,
        school_year,
        teacher_email: currentUserEmail.value,
        grade: parseFloat(grade)
      })
    }
  })

  const { error } = await supabase
    .from('grades')
    .upsert(recordsToUpsert, { onConflict: 'lrn,subject,term,section,school_year' })

  saving.value = false
  if (error) {
    alert(`Failed to save grades: ${error.message}`)
  } else {
    alert(`Grades for ${subject} (${section}) saved successfully!`)
  }
}

async function syncGradesToGoogleSheets() {
  if (!selectedAssignment.value) return
  
  const GOOGLE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbz2hsPLhUDIt8rPyiWq1VnzblbdwqGIXvw42okKIhibjnL44zVTiBZOeNHJRSU_xVbb/exec'
  if (!GOOGLE_SCRIPT_URL) {
    syncMessage.value = "❌ Error: VITE_GOOGLE_SCRIPT_URL is missing."
    return
  }

  isSyncing.value = true
  syncMessage.value = "Building section matrix..."

  try {
    const targetSection = selectedAssignment.value.section

    const { data: sectionStudents } = await supabase
      .from('students')
      .select('lrn, name')
      .eq('section', targetSection)
      .order('name')

    const { data: allSectionGrades } = await supabase
      .from('grades')
      .select('lrn, subject, grade')
      .eq('section', targetSection)
      .eq('term', selectedTerm.value)

    const formattedGrades = sectionStudents.map(student => {
      const studentGrades = { lrn: student.lrn, name: student.name }
      let total = 0
      let count = 0

      ALL_SUBJECTS.forEach(subj => {
        const match = allSectionGrades?.find(g => g.lrn === student.lrn && g.subject === subj)
        if (match && match.grade !== null) {
          studentGrades[subj] = match.grade
          total += Number(match.grade)
          count++
        } else {
          studentGrades[subj] = ''
        }
      })

      studentGrades.average = count > 0 ? (total / count).toFixed(2) : ''
      return studentGrades
    })

    const payload = {
      action: 'sync_grades',
      section: targetSection,
      term: selectedTerm.value,
      grades: formattedGrades
    }

    await fetch(GOOGLE_SCRIPT_URL, {
      method: 'POST',
      mode: 'no-cors',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      body: JSON.stringify(payload)
    })

    syncMessage.value = `✅ Grades synced to ${selectedTerm.value} tab!`
  } catch (err) {
    syncMessage.value = `❌ Sync failed: ${err.message}`
  } finally {
    isSyncing.value = false
  }
}
</script>

<template>
  <div class="max-w-7xl mx-auto p-6 space-y-6">
    <h1 class="text-2xl font-bold text-slate-800">Teacher Grade Entry</h1>

    <div class="flex flex-wrap gap-4 bg-white p-4 border rounded-lg shadow-sm items-center justify-between">
      <div class="flex gap-4 items-center">
        <div>
          <label class="block text-xs font-bold text-slate-600 mb-1">Subject & Section</label>
          <select v-model="selectedAssignment" class="p-2 border rounded text-sm bg-slate-50 font-semibold">
            <option v-for="(item, idx) in assignedSubjects" :key="idx" :value="item">
              {{ item.subject }} — Section {{ item.section }}
            </option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-bold text-slate-600 mb-1">Term</label>
          <select v-model="selectedTerm" class="p-2 border rounded text-sm bg-slate-50 font-semibold">
            <option value="term 1">Term 1</option>
            <option value="term 2">Term 2</option>
            <option value="term 3">Term 3</option>
          </select>
        </div>
      </div>

      <div class="flex items-center gap-3">
        <button @click="saveGradesToSupabase" :disabled="saving" class="bg-blue-600 hover:bg-blue-700 text-white font-bold px-4 py-2 rounded text-sm shadow-sm">
          {{ saving ? 'Saving...' : 'Save Grades' }}
        </button>
        <button @click="syncGradesToGoogleSheets" :disabled="isSyncing" class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold px-4 py-2 rounded text-sm shadow-sm">
          Sync Term to Google Sheets
        </button>
      </div>
    </div>

    <div v-if="syncMessage" class="text-xs font-semibold text-slate-700">{{ syncMessage }}</div>

    <div v-if="!loading" class="bg-white border rounded-lg shadow-sm overflow-hidden">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-slate-800 text-white text-xs uppercase font-bold">
            <th class="p-3 w-12 text-center">#</th>
            <th class="p-3">Student Name</th>
            <th class="p-3 w-36 text-center">LRN</th>
            <th class="p-3 w-32 text-center bg-slate-900">Grade ({{ selectedAssignment?.subject }})</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-200 text-sm">
          <tr v-for="(s, index) in students" :key="s.lrn" class="hover:bg-slate-50">
            <td class="p-3 text-center text-slate-500 font-bold">{{ index + 1 }}</td>
            <td class="p-3 font-semibold text-slate-800">{{ s.name }}</td>
            <td class="p-3 text-center font-mono text-xs text-slate-600">{{ s.lrn }}</td>
            <td class="p-2 text-center bg-slate-50">
              <input 
                v-model="gradeInputs[s.lrn]" 
                type="number" 
                min="0" 
                max="100" 
                step="0.01"
                placeholder="0-100" 
                class="w-24 p-1.5 border rounded text-center text-sm font-bold border-slate-300 focus:border-blue-500" 
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>