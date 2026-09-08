<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase.js'

const loading = ref(true)
const errorMessage = ref('')
const currentUserEmail = ref('')
const mySection = ref(null)
const students = ref([])

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

    // 3. Fetch students for this section
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

async function transferStudent(student) {
  const newSection = prompt(`Transfer ${student.name} to which section?`, '')
  if (newSection !== null && newSection.trim() !== '' && newSection.trim() !== mySection.value) {
    const { error } = await supabase
      .from('students')
      .update({ section: newSection.trim() })
      .eq('id', student.id)
      
    if (error) {
      errorMessage.value = `Transfer failed: ${error.message}`
    } else {
      alert(`${student.name} transferred to ${newSection.trim()}`)
      fetchStudents() // Will remove them from the current view
    }
  }
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
</script>

<template>
  <div class="max-w-6xl mx-auto p-6 space-y-6">
    <div class="border-b pb-5">
      <h1 class="text-3xl font-bold text-slate-800">My Advisory Section</h1>
      <p v-if="mySection" class="text-sm text-slate-600 mt-1">
        Currently managing <span class="font-bold text-blue-600">{{ mySection }}</span> | {{ students.length }} Students
      </p>
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
                <button @click="transferStudent(s)" class="text-blue-600 text-xs hover:underline font-medium">Transfer</button>
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