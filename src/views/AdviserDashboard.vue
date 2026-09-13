<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase.js'

const loading = ref(true)
const errorMessage = ref('')
const currentUserEmail = ref('')
const mySection = ref(null)
const students = ref([])
const grades = ref([]) // Added to hold grades for transmission

// Transmission States
const isReviewing = ref(false)
const isFinalized = ref(false)
const isTransmitting = ref(false)
const transmissionMessage = ref('')

// Form states
const newStudent = ref({ lrn: '', name: '', sex: 'MALE', birthday: '' })
const editingId = ref(null)
const editForm = ref({})

onMounted(async () => {
  await initializeAdviserData()
})

async function initializeAdviserData() {
  loading.value = true
  errorMessage.value = ''
  try {
    // 1. Get logged-in user
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) throw new Error('Not authenticated. Please log in.')
    currentUserEmail.value = user.email

    // 2. Determine adviser's assigned section
    const { data: sectionData, error: sectionError } = await supabase
      .from('adviser_sections')
      .select('section')
      .eq('teacher_email', currentUserEmail.value)
      .single()
      
    if (sectionError) throw new Error('No advisory section assigned to your account.')
    mySection.value = sectionData.section

    // 3. Fetch students and grades for this section
    await fetchStudents()
    await fetchGrades() 
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

// Added function to fetch grades for the payload
async function fetchGrades() {
  if (!mySection.value) return
  // Adjust 'grades' table name and query to match your actual Supabase schema
  const { data, error } = await supabase
    .from('grades')
    .select('*')
    .eq('section', mySection.value)
  
  if (!error) grades.value = data || []
}

async function addStudent() {
  if (!newStudent.value.lrn || !newStudent.value.name) return
  
  const payload = { ...newStudent.value, section: mySection.value }
  const { error } = await supabase.from('students').insert([payload])
  
  if (error) {
    errorMessage.value = `Add failed: ${error.message}`
  } else {
    newStudent.value = { lrn: '', name: '', sex: 'MALE', birthday: '' }
    fetchStudents()
  }
}

async function deleteStudent(id, name) {
  if (!confirm(`Permanently delete ${name}?`)) return
  const { error } = await supabase.from('students').delete().eq('id', id)
  if (error) errorMessage.value = `Delete failed: ${error.message}`
  else fetchStudents()
}

// --- Inline Edit Methods ---
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
      birthday: editForm.value.birthday
    })
    .eq('id', editingId.value)

  if (error) {
    errorMessage.value = `Update failed: ${error.message}`
  } else {
    editingId.value = null
    fetchStudents()
  }
}

// --- Transmission Methods ---
function reviewGrades() {
  isReviewing.value = true
  alert("Grades are now in review mode. Please verify all entries.")
}

function finalizeGrades() {
  if (!confirm("Are you sure you want to finalize? This will lock further edits.")) return
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

  // REPLACE WITH YOUR ACTUAL DEPLOYED APPS SCRIPT URL
  const GOOGLE_SCRIPT_URL = 'YOUR_GOOGLE_SCRIPT_WEB_APP_URL_HERE' 

  try {
    const payload = {
      section: mySection.value,
      teacherEmail: currentUserEmail.value,
      grades: grades.value 
    }

    const response = await fetch(GOOGLE_SCRIPT_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'text/plain;charset=utf-8', 
      },
      body: JSON.stringify(payload)
    })

    const result = await response.json()

    if (result.status === 'error') throw new Error(result.message)
    
    transmissionMessage.value = "✅ Successfully transmitted to Google Sheets!"
    
  } catch (error) {
    transmissionMessage.value = `❌ Transmission failed: ${error.message}`
  } finally {
    isTransmitting.value = false
  }
}
</script>

<template>
  <div class="max-w-6xl mx-auto p-6 space-y-6">
    <!-- Header with Navigation Buttons -->
    <div class="border-b pb-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-slate-800">My Advisory Section</h1>
        <p v-if="mySection" class="text-sm text-slate-600 mt-1">
          Currently managing <span class="font-bold text-blue-600">{{ mySection }}</span> | {{ students.length }} Students
        </p>
      </div>

      <!-- Navigation Action Buttons -->
      <div class="flex flex-col sm:flex-row gap-3 self-start sm:self-auto">
        <router-link 
          to="/term-grade" 
          class="inline-flex items-center justify-center bg-emerald-600 hover:bg-emerald-700 text-white text-xs sm:text-sm font-semibold px-4 py-2.5 rounded-lg transition-colors shadow-sm"
        >
          View Term Grades Summary &rarr;
        </router-link>
        
        <router-link 
          to="/teacher" 
          class="inline-flex items-center justify-center bg-indigo-600 hover:bg-indigo-700 text-white text-xs sm:text-sm font-semibold px-4 py-2.5 rounded-lg transition-colors shadow-sm"
        >
          TEACHER DASHBOARD (enter grades here) &rarr;
        </router-link>
      </div>
    </div>

    <!-- TRANSMISSION TOOLBAR -->
    <div v-if="!loading && mySection" class="flex flex-wrap items-center gap-3 p-4 bg-white border border-slate-200 rounded-lg shadow-sm">
      <button 
        @click="reviewGrades" 
        :class="isReviewing ? 'bg-amber-100 text-amber-800 border-amber-300' : 'bg-white text-slate-700 border-slate-300 hover:bg-slate-50'"
        class="px-4 py-2 border rounded-md text-sm font-medium transition"
      >
        Review
      </button>
      
      <button 
        @click="finalizeGrades" 
        :disabled="!isReviewing || isFinalized"
        class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-md text-sm font-medium transition"
      >
        Finalize
      </button>
      
      <button 
        @click="transmitGrades" 
        :disabled="!isFinalized || isTransmitting"
        class="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-md text-sm font-medium transition flex items-center gap-2"
      >
        <svg v-if="isTransmitting" class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Transmit to Sheet
      </button>

      <span v-if="transmissionMessage" class="ml-auto text-sm font-medium text-slate-600">
        {{ transmissionMessage }}
      </span>
    </div>

    <div v-if="loading" class="text-slate-500">Loading advisory data...</div>
    
    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">
      {{ errorMessage }}
    </div>

    <div v-if="!loading && mySection" class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600">
            <th class="p-3">LRN</th>
            <th class="p-3">Name</th>
            <th class="p-3">Sex</th>
            <th class="p-3">Birthday</th>
            <th class="p-3 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="text-sm divide-y divide-slate-100">
          
          <!-- Add New Student Row -->
          <tr class="bg-blue-50/40">
            <td class="p-2"><input v-model="newStudent.lrn" placeholder="New LRN" class="w-full p-1.5 border rounded text-xs" /></td>
            <td class="p-2"><input v-model="newStudent.name" placeholder="Full Name" class="w-full p-1.5 border rounded text-xs" /></td>
            <td class="p-2">
              <select v-model="newStudent.sex" class="w-full p-1.5 border rounded text-xs">
                <option>MALE</option>
                <option>FEMALE</option>
              </select>
            </td>
            <td class="p-2"><input v-model="newStudent.birthday" type="date" class="w-full p-1.5 border rounded text-xs" /></td>
            <td class="p-2 text-right">
              <button @click="addStudent" class="bg-blue-600 text-white px-3 py-1.5 rounded text-xs hover:bg-blue-700 font-medium">Add to Section</button>
            </td>
          </tr>

          <!-- Data Rows -->
          <tr v-for="s in students" :key="s.id" class="hover:bg-slate-50">
            
            <!-- Read-Only Mode -->
            <template v-if="editingId !== s.id">
              <td class="p-3 font-mono text-xs text-slate-600">{{ s.lrn }}</td>
              <td class="p-3 font-semibold text-slate-800">{{ s.name }}</td>
              <td class="p-3 text-xs">{{ s.sex }}</td>
              <td class="p-3 text-xs">{{ s.birthday }}</td>
              <td class="p-3 text-right space-x-3">
                <button @click="startEdit(s)" class="text-emerald-600 text-xs hover:underline font-medium">Edit</button>
                <button @click="deleteStudent(s.id, s.name)" class="text-red-600 text-xs hover:underline font-medium">Delete</button>
              </td>
            </template>

            <!-- Edit Mode -->
            <template v-else>
              <td class="p-2"><input v-model="editForm.lrn" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
              <td class="p-2"><input v-model="editForm.name" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
              <td class="p-2">
                <select v-model="editForm.sex" class="w-full p-1 border rounded text-xs border-emerald-400">
                  <option>MALE</option><option>FEMALE</option>
                </select>
              </td>
              <td class="p-2"><input v-model="editForm.birthday" type="date" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
              <td class="p-2 text-right space-x-2">
                <button @click="saveEdit" class="bg-emerald-600 text-white px-3 py-1 rounded text-xs hover:bg-emerald-700">Save</button>
                <button @click="cancelEdit" class="bg-slate-200 text-slate-700 px-3 py-1 rounded text-xs hover:bg-slate-300">Cancel</button>
              </td>
            </template>

          </tr>
          <tr v-if="students.length === 0 && !loading">
            <td colspan="5" class="p-8 text-center text-slate-500 text-sm">No students found in your section.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>