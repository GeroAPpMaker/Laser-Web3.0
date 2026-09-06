<script setup>
import { computed, onMounted, ref } from 'vue'
import DashboardHeader from '../components/DashboardHeader.vue'
import GradeEntry from '../components/GradeEntry.vue'
import { fetchCurrentProfile } from '../utils/auth'

const userEmail = ref('')
const loadError = ref('')

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
    // Retrieve the email property we just added in utils/auth.js
    userEmail.value = profile?.email ?? '' 
  } catch (err) {
    console.error('Error fetching profile:', err)
    loadError.value = 'Could not load your profile.'
  }
})
</script>

<template>
  <div class="flex-1 bg-slate-50 text-slate-900">
    <DashboardHeader :title="`Welcome ${welcomeName}`" wide>
      <p v-if="loadError" class="mt-2 text-sm text-red-700">{{ loadError }}</p>
    </DashboardHeader>

    <main class="mx-auto max-w-6xl px-4 py-8">
      <!-- Grade Entry Section -->
      <div class="w-full">
        <GradeEntry />
      </div>
    </main>
  </div>
</template>