<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase.js'
import DashboardHeader from '../components/DashboardHeader.vue'
import GradeEntry from '../components/GradeEntry.vue'
import { fetchCurrentProfile } from '../utils/auth'

const router = useRouter()
const userEmail = ref('')
const loadError = ref('')
const isAdviser = ref(false)

const welcomeName = computed(() => {
  if (!userEmail.value) return 'Teacher'

  // Extract the portion before '@' (e.g., "gerald.valencia")
  const username = userEmail.value.split('@')[0] || ''
  
  // Replace dots, underscores, or hyphens with spaces (e.g., "gerald valencia")
  const formattedName = username.replace(/[._-]/g, ' ').trim()

  if (!formattedName) return 'Teacher'

  // Capitalize the first letter of each part (e.g., "Gerald Valencia")
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
    
    // Check if the user is assigned to an advisory section
    if (userEmail.value) {
      const { data, error } = await supabase
        .from('adviser_sections')
        .select('section')
        .eq('teacher_email', userEmail.value)
        .maybeSingle()
        
      if (!error && data) {
        isAdviser.value = true
      }
    }
  } catch (err) {
    console.error('Error fetching profile:', err)
    loadError.value = 'Could not load your profile.'
  }
})

function goToAdviserDashboard() {
  // Adjust this route to match your actual router configuration
  router.push('/adviser')
}
</script>

<template>
  <div class="flex-1 bg-slate-50 text-slate-900">
    <DashboardHeader :title="`Welcome ${welcomeName}`" wide>
      <p v-if="loadError" class="mt-2 text-sm text-red-700">{{ loadError }}</p>
    </DashboardHeader>

    <main class="mx-auto max-w-6xl px-4 py-8 space-y-6">
      
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
        <h2 class="text-xl font-bold text-slate-800 mb-4 border-b pb-2">Subject Grades Entry</h2>
        <GradeEntry />
      </div>
    </main>
  </div>
</template>