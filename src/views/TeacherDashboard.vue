<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase.js'
import DashboardHeader from '../components/DashboardHeader.vue'
import GradeEntry from '../components/GradeEntry.vue'
import GradeSheetUserManual from '../components/GradeSheetUserManual.vue'
import { fetchCurrentProfile } from '../utils/auth'

const router = useRouter()
const userEmail = ref('')
const loadError = ref('')
const isAdviser = ref(false)
const isManualOpen = ref(false)

// ── Tab navigation ────────────────────────────────────────────────────────────
const activeTab = ref('grades')

const welcomeName = computed(() => {
  if (!userEmail.value) return 'Teacher'
  const username = userEmail.value.split('@')[0] || ''
  const formattedName = username.replace(/[._-]/g, ' ').trim()
  if (!formattedName) return 'Teacher'
  return formattedName
    .split(' ')
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ')
})

onMounted(async () => {
  try {
    const profile = await fetchCurrentProfile()
    userEmail.value = profile?.email ?? ''

    if (userEmail.value) {
      const { data, error } = await supabase
        .from('adviser_sections')
        .select('section')
        .eq('teacher_email', userEmail.value)
        .maybeSingle()
      if (!error && data) isAdviser.value = true
    }
  } catch (err) {
    console.error('Error fetching profile:', err)
    loadError.value = 'Could not load your profile.'
  }
})

function goToAdviserDashboard() {
  router.push('/adviser')
}

// ── Learning Materials state ──────────────────────────────────────────────────
const myMaterials = ref([])
const materialForm = ref({ type: 'adm', subject: '', term: 1, title: '', url: '', section: '' })
const materialLoading = ref(false)
const materialError = ref('')

async function fetchMyMaterials() {
  if (!userEmail.value) return
  materialError.value = ''
  const { data, error } = await supabase
    .from('learning_materials')
    .select('*')
    .eq('submitted_by', userEmail.value)
    .order('created_at', { ascending: false })
  if (error) { materialError.value = `Failed to load materials: ${error.message}`; return }
  myMaterials.value = data || []
}

async function addMaterial() {
  materialError.value = ''
  const f = materialForm.value
  if (!f.subject || !f.title || !f.url) { materialError.value = 'Subject, Title and URL are required.'; return }
  materialLoading.value = true
  const payload = {
    type: f.type,
    subject: f.subject.trim(),
    term: Number(f.term),
    title: f.title.trim(),
    url: f.url.trim(),
    section: f.section.trim() || null,
    submitted_by: userEmail.value,
  }
  const { error } = await supabase.from('learning_materials').insert([payload])
  materialLoading.value = false
  if (error) { materialError.value = `Failed to add material: ${error.message}`; return }
  materialForm.value = { type: 'adm', subject: '', term: 1, title: '', url: '', section: '' }
  await fetchMyMaterials()
}

async function deleteMaterial(id) {
  if (!confirm('Delete this material?')) return
  const { error } = await supabase.from('learning_materials').delete().eq('id', id)
  if (error) { materialError.value = `Delete failed: ${error.message}`; return }
  await fetchMyMaterials()
}
</script>

<template>
  <div class="flex-1 bg-slate-50 text-slate-900">
    <DashboardHeader :title="`Welcome ${welcomeName}`" wide>
      <p v-if="loadError" class="mt-2 text-sm text-red-700">{{ loadError }}</p>
    </DashboardHeader>

    <!-- Tab bar -->
    <div class="flex border-b border-slate-200 bg-white px-6 space-x-6 overflow-x-auto">
      <button
        @click="activeTab = 'grades'"
        :class="activeTab === 'grades' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
        class="py-3 px-1 border-b-2 text-sm transition-colors whitespace-nowrap"
      >
        Grades
      </button>
      <button
        @click="activeTab = 'materials'; fetchMyMaterials()"
        :class="activeTab === 'materials' ? 'border-blue-600 text-blue-600 font-semibold' : 'border-transparent text-slate-500 hover:text-slate-700'"
        class="py-3 px-1 border-b-2 text-sm transition-colors whitespace-nowrap flex items-center gap-2"
      >
        Learning Materials
        <span class="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full text-xs font-mono">{{ myMaterials.length }}</span>
      </button>
    </div>

    <main class="mx-auto max-w-6xl px-4 py-8 space-y-6">

      <!-- ── GRADES TAB ──────────────────────────────────────────────────── -->
      <template v-if="activeTab === 'grades'">
        <!-- Adviser Navigation Banner -->
        <div v-if="isAdviser" class="bg-blue-50 border border-blue-200 rounded-lg p-4 flex flex-col sm:flex-row items-center justify-between shadow-sm">
          <div>
            <h3 class="text-blue-800 font-semibold text-lg">Advisory Section</h3>
            <p class="text-blue-600 text-sm">You are assigned as a section adviser. Manage your students here.</p>
          </div>
          <button
            @click="goToAdviserDashboard"
            class="mt-3 sm:mt-0 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-md font-medium text-sm transition-colors shadow-sm"
          >
            Open Adviser Dashboard
          </button>
        </div>

        <!-- Grade Entry Section -->
        <div class="w-full bg-white border border-slate-200 rounded-xl shadow-sm p-6">
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 border-b pb-3 gap-4">
            <h2 class="text-xl font-bold text-slate-800">Subject Grades Entry</h2>
            <button
              @click="isManualOpen = true"
              class="bg-indigo-50 text-indigo-700 hover:bg-indigo-100 border border-indigo-200 px-4 py-2 rounded-lg font-semibold text-sm transition-colors shadow-sm flex items-center gap-2"
            >
              📖 User Manual
            </button>
          </div>
          <GradeEntry />
        </div>
      </template>

      <!-- ── LEARNING MATERIALS TAB ──────────────────────────────────────── -->
      <template v-else-if="activeTab === 'materials'">
        <div v-if="materialError" class="p-3 bg-red-50 border border-red-200 text-red-700 rounded-lg text-sm">{{ materialError }}</div>

        <!-- Add Form -->
        <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-6 space-y-4">
          <div>
            <h3 class="text-base font-semibold text-slate-800">Post a Learning Material</h3>
            <p class="text-xs text-slate-500 mt-0.5">You can post ADM and Reviewer links. Students in your section will see them.</p>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-xs font-semibold text-slate-600 mb-1">Type</label>
              <select v-model="materialForm.type" class="w-full p-2 border rounded-md text-sm">
                <option value="adm">ADM (Alternative Delivery Module)</option>
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
              <label class="block text-xs font-semibold text-slate-600 mb-1">Link (URL)</label>
              <input v-model="materialForm.url" type="url" placeholder="https://drive.google.com/..." class="w-full p-2 border rounded-md text-sm" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-slate-600 mb-1">
                Section <span class="font-normal text-slate-400">(leave blank for all)</span>
              </label>
              <input v-model="materialForm.section" placeholder="e.g. Grade 7 - Narra" class="w-full p-2 border rounded-md text-sm" />
            </div>
          </div>

          <div class="flex justify-end pt-1">
            <button
              @click="addMaterial"
              :disabled="materialLoading"
              class="px-5 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white text-sm font-medium rounded-lg transition"
            >
              {{ materialLoading ? 'Posting…' : 'Post Material' }}
            </button>
          </div>
        </div>

        <!-- My Materials List -->
        <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-x-auto">
          <div class="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-sm font-semibold text-slate-700">Your Posted Materials</h3>
            <span class="text-xs text-slate-400">{{ myMaterials.length }} total</span>
          </div>
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-slate-50 text-xs font-semibold uppercase text-slate-600">
                <th class="p-3">Type</th>
                <th class="p-3">Subject</th>
                <th class="p-3">Term</th>
                <th class="p-3">Title</th>
                <th class="p-3">Link</th>
                <th class="p-3">Section</th>
                <th class="p-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody class="text-sm divide-y divide-slate-100">
              <tr v-if="myMaterials.length === 0">
                <td colspan="7" class="p-8 text-center text-slate-500 italic">No materials posted yet. Use the form above to add one.</td>
              </tr>
              <tr v-for="m in myMaterials" :key="m.id" class="hover:bg-slate-50">
                <td class="p-3">
                  <span class="px-2 py-0.5 rounded-full text-xs font-medium"
                    :class="m.type === 'adm' ? 'bg-blue-100 text-blue-700' : 'bg-amber-100 text-amber-700'">
                    {{ m.type === 'adm' ? 'ADM' : 'Reviewer' }}
                  </span>
                </td>
                <td class="p-3 font-semibold">{{ m.subject }}</td>
                <td class="p-3 text-xs">{{ m.term === 1 ? '1st' : m.term === 2 ? '2nd' : '3rd' }} Term</td>
                <td class="p-3">{{ m.title }}</td>
                <td class="p-3 max-w-xs truncate">
                  <a :href="m.url" target="_blank" rel="noopener" class="text-blue-600 hover:underline text-xs">{{ m.url }}</a>
                </td>
                <td class="p-3 text-xs text-slate-500">{{ m.section || 'All sections' }}</td>
                <td class="p-3 text-right">
                  <button @click="deleteMaterial(m.id)" class="text-red-600 text-xs hover:underline">Delete</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

    </main>

    <!-- User Manual Modal -->
    <GradeSheetUserManual
      :is-open="isManualOpen"
      @close="isManualOpen = false"
    />
  </div>
</template>
