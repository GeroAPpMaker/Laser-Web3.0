<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase.js'

const loading = ref(true)
const errorMessage = ref('')
const currentUserEmail = ref('')
const mySection = ref(null)
const students = ref([])
const googleSheetLink = ref('')

// Split students into Male and Female arrays
const maleStudents = computed(() => students.value.filter(s => s.sex === 'M'))
const femaleStudents = computed(() => students.value.filter(s => s.sex === 'F'))

// Form states
const newStudent = ref({ lrn: '', name: '', sex: 'M', birthday: '' })
const editingId = ref(null)
const editForm = ref({})

// Transmission states
const isSyncing = ref(false)
const syncMessage = ref('')

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

    // Fetch adviser's Google Sheet link from Supabase table
    const { data: sheetData } = await supabase
      .from('adviser_sheets')
      .select('google_sheet_link')
      .eq('email_address', currentUserEmail.value)
      .single()

    if (sheetData) {
      googleSheetLink.value = sheetData.google_sheet_link
    }

    await fetchStudents()
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

async function addStudent() {
  if (!newStudent.value.lrn || !newStudent.value.name) return
  
  const payload = { ...newStudent.value, section: mySection.value }
  const { error } = await supabase.from('students').insert([payload])
  
  if (error) {
    errorMessage.value = `Add failed: ${error.message}`
  } else {
    newStudent.value = { lrn: '', name: '', sex: 'M', birthday: '' }
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

// --- Fetch Target Sheet ID Helper ---
async function getTargetSheetId(email) {
  try {
    const response = await fetch('/Adviser_Mapping.csv')
    const csvText = await response.text()
    
    // Parse CSV rows
    const lines = csvText.split('\n')
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim()
      if (!line) continue
      
      const [fileId, emailAddress] = line.split(',')
      if (emailAddress && emailAddress.trim() === email) {
        return fileId.trim()
      }
    }
    return null
  } catch (error) {
    console.error("Failed to load Adviser_Mapping.csv", error)
    return null
  }
}

// --- Sync to Google Sheets Method ---
async function syncRecordsToSheet() {
  if (students.value.length === 0) {
    syncMessage.value = "No students to sync."
    return
  }

  isSyncing.value = true
  syncMessage.value = "Locating your mapped Google Sheet..."

  // Look up mapped Sheet ID for the logged-in user
  const targetSheetId = await getTargetSheetId(currentUserEmail.value)
  if (!targetSheetId) {
    syncMessage.value = `❌ Error: No mapped file found in Adviser_Mapping.csv for ${currentUserEmail.value}`
    isSyncing.value = false
    return
  }

  const GOOGLE_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbybs2g-PqNNw0Ge4iLWk8CfZNwps5krInwJcp4p9rbCOSlb6kBzbjxPzqRilUDp_EVi/exec'

  syncMessage.value = "Syncing records to Google Sheets..."

  try {
    const payload = {
      action: 'sync_records',
      section: mySection.value,
      students: students.value,
      spreadsheetId: targetSheetId // dynamically pass the spreadsheet based on email
    }

    await fetch(GOOGLE_SCRIPT_URL, {
      method: 'POST',
      mode: 'no-cors', 
      headers: {
        'Content-Type': 'text/plain;charset=utf-8'
      },
      body: JSON.stringify(payload)
    })

    // 'no-cors' hides response body details; reflect dispatch in UI
    syncMessage.value = `🚀 Sync request sent successfully! (${new Date().toLocaleTimeString()})`
    
  } catch (error) {
    syncMessage.value = `❌ Sync failed to send: ${error.message}`
  } finally {
    isSyncing.value = false
  }
}

// --- Print Card Method ---
function printCard() {
  if (googleSheetLink.value) {
    window.open(googleSheetLink.value, '_blank')
  } else {
    alert('No mapped Google Sheet link found for this account in Supabase.')
  }
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

    <!-- Toolbar: Add Student & Sync / Print -->
    <div v-if="!loading && mySection" class="bg-white p-4 border border-slate-200 rounded-lg shadow-sm flex flex-col xl:flex-row gap-4 items-center justify-between">
      <div class="flex flex-wrap items-center gap-2 w-full xl:w-auto">
        <span class="font-bold text-sm text-slate-700 mr-2">Add Student:</span>
        <input v-model="newStudent.lrn" placeholder="New LRN" class="p-2 border rounded text-xs w-32" />
        <input v-model="newStudent.name" placeholder="Full Name" class="p-2 border rounded text-xs w-48" />
        <select v-model="newStudent.sex" class="p-2 border rounded text-xs">
          <option value="M">M (Male)</option>
          <option value="F">F (Female)</option>
        </select>
        <input v-model="newStudent.birthday" type="date" class="p-2 border rounded text-xs w-36" />
        <button @click="addStudent" class="bg-blue-600 text-white px-4 py-2 rounded text-xs hover:bg-blue-700 font-bold shadow-sm">
          Add +
        </button>
      </div>

      <div class="flex flex-wrap items-center gap-3 xl:ml-auto">
        <span v-if="syncMessage" class="text-xs font-medium text-slate-600">{{ syncMessage }}</span>
        
        <!-- Print Card Button -->
        <button @click="printCard" class="bg-slate-700 hover:bg-slate-800 text-white px-4 py-2 rounded-lg text-sm font-bold transition-colors shadow-sm flex items-center gap-2">
          Go to GradeSheets
        </button>

        <button @click="syncRecordsToSheet" :disabled="isSyncing" class="bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white px-4 py-2 rounded-lg text-sm font-bold transition-colors shadow-sm flex items-center gap-2">
          Sync to Google Sheets
        </button>
      </div>
    </div>

    <div v-if="loading" class="text-slate-500">Loading advisory data...</div>
    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{{ errorMessage }}</div>

    <!-- Side-by-Side Tables -->
    <div v-if="!loading && mySection" class="grid grid-cols-1 xl:grid-cols-2 gap-8 items-start">
      
      <!-- MALE TABLE -->
      <div class="bg-white border border-slate-300 shadow-sm overflow-x-auto">
        <table class="w-full text-left border-collapse min-w-max">
          <thead>
            <tr class="bg-[#002060] text-white text-xs font-bold uppercase tracking-wide">
              <th class="p-2 w-10 text-center border border-slate-400">#</th>
              <th class="p-2 border border-slate-400 w-48">MALE</th>
              <th class="p-2 text-center border border-slate-400 w-28">LRN</th>
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
                <td class="p-2 text-center text-xs text-slate-700 border border-slate-300">{{ s.birthday || '-' }}</td>
                <td class="p-2 text-center space-x-2 border border-slate-300">
                  <button @click="startEdit(s)" class="text-blue-600 text-xs hover:underline font-bold">Edit</button>
                  <button @click="deleteStudent(s.id, s.name)" class="text-red-600 text-xs hover:underline font-bold">Del</button>
                </td>
              </template>

              <template v-else>
                <td class="p-1 border border-slate-300"><input v-model="editForm.name" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                <td class="p-1 border border-slate-300"><input v-model="editForm.lrn" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                <td class="p-1 border border-slate-300"><input v-model="editForm.birthday" type="date" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                <td class="p-1 text-center space-x-1 border border-slate-300">
                  <button @click="saveEdit" class="bg-emerald-600 text-white px-2 py-1 rounded text-xs hover:bg-emerald-700">Save</button>
                  <button @click="cancelEdit" class="bg-slate-200 text-slate-700 px-2 py-1 rounded text-xs hover:bg-slate-300">Cancel</button>
                </td>
              </template>
            </tr>
            <tr v-if="maleStudents.length === 0">
              <td colspan="5" class="p-4 text-center text-slate-400 text-xs font-medium border border-slate-300">No Male students recorded.</td>
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
                <td class="p-2 text-center text-xs text-slate-700 border border-slate-300">{{ s.birthday || '-' }}</td>
                <td class="p-2 text-center space-x-2 border border-slate-300">
                  <button @click="startEdit(s)" class="text-blue-600 text-xs hover:underline font-bold">Edit</button>
                  <button @click="deleteStudent(s.id, s.name)" class="text-red-600 text-xs hover:underline font-bold">Del</button>
                </td>
              </template>

              <template v-else>
                <td class="p-1 border border-slate-300"><input v-model="editForm.name" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                <td class="p-1 border border-slate-300"><input v-model="editForm.lrn" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                <td class="p-1 border border-slate-300"><input v-model="editForm.birthday" type="date" class="w-full p-1 border rounded text-xs border-emerald-400" /></td>
                <td class="p-1 text-center space-x-1 border border-slate-300">
                  <button @click="saveEdit" class="bg-emerald-600 text-white px-2 py-1 rounded text-xs hover:bg-emerald-700">Save</button>
                  <button @click="cancelEdit" class="bg-slate-200 text-slate-700 px-2 py-1 rounded text-xs hover:bg-slate-300">Cancel</button>
                </td>
              </template>
            </tr>
            <tr v-if="femaleStudents.length === 0">
              <td colspan="5" class="p-4 text-center text-slate-400 text-xs font-medium border border-slate-300">No Female students recorded.</td>
            </tr>
          </tbody>
        </table>
      </div>

    </div>
  </div>
</template>