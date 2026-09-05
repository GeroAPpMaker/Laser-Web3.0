<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import DashboardHeader from '../components/DashboardHeader.vue'
import { mapGrades } from '../data/mapSections'
import { fetchCurrentProfile } from '../utils/auth'

const userEmail = ref('')
const loadError = ref('')
const selectedLinks = reactive(Object.fromEntries(mapGrades.map((grade) => [grade.id, ''])))
const driveUrl = import.meta.env.VITE_TEACHER_GOOGLE_DRIVE_URL || ''

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

const accentClass = {
  blue: 'bg-blue-50 text-blue-700',
  emerald: 'bg-emerald-50 text-emerald-700',
  amber: 'bg-amber-50 text-amber-800',
  rose: 'bg-rose-50 text-rose-700',
}

function selectedSection(grade) {
  return grade.sections.find((section) => section.link === selectedLinks[grade.id]) ?? null
}

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
      <div class="grid gap-6 lg:grid-cols-2">
        <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <span
            class="mb-2 inline-flex rounded-full border border-school-primary/20 bg-school-primary/10 px-3 py-1 text-xs font-semibold text-school-primary"
          >
            Directory
          </span>
          <h2 class="text-lg font-semibold tracking-tight">M.A.P. Drive</h2>
          <p class="mt-1 text-sm text-slate-600">
            Select a grade and section to open the Master Academic Portfolio on Microsoft SharePoint.
          </p>

          <div class="mt-6 grid gap-4 sm:grid-cols-2">
            <article
              v-for="grade in mapGrades"
              :key="grade.id"
              class="flex flex-col rounded-xl border border-slate-200 p-4 text-center"
            >
              <div
                class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full text-sm font-bold"
                :class="accentClass[grade.accent]"
              >
                {{ grade.id }}
              </div>
              <h3 class="text-sm font-semibold">{{ grade.label }}</h3>
              <label class="mt-3 block text-xs text-slate-500" :for="`grade-${grade.id}`">
                Choose your section
              </label>
              <select
                :id="`grade-${grade.id}`"
                v-model="selectedLinks[grade.id]"
                class="mt-1 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              >
                <option disabled value="">Select Section...</option>
                <option v-for="section in grade.sections" :key="section.name" :value="section.link">
                  {{ section.name }}
                </option>
              </select>
              <a
                v-if="selectedSection(grade)"
                class="mt-3 inline-flex items-center justify-center rounded-full border border-school-primary px-3 py-2 text-xs font-semibold text-school-primary hover:bg-school-primary/5"
                :href="selectedSection(grade).link"
                target="_blank"
                rel="noopener noreferrer"
              >
                Open {{ selectedSection(grade).name }}
              </a>
            </article>
          </div>
        </section>

        <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-semibold tracking-tight">Resources</h2>
          <p class="mt-1 text-sm text-slate-600">Google Drive files for circulation and class resources.</p>

          <div class="mt-6 flex min-h-56 flex-col items-center justify-center rounded-xl border border-dashed border-slate-300 bg-slate-50 p-6 text-center">
            <p class="text-sm font-medium text-slate-800">Google Drive</p>
            <template v-if="driveUrl">
              <a
                class="mt-4 rounded-full bg-school-primary px-5 py-2.5 text-sm font-semibold text-white hover:bg-school-primary-light"
                :href="driveUrl"
                target="_blank"
                rel="noopener noreferrer"
              >
                Open Google Drive
              </a>
            </template>
            <p v-else class="mt-2 max-w-sm text-sm text-slate-500">
              Add your folder URL to
              <code class="rounded bg-white px-1 py-0.5 text-xs">VITE_TEACHER_GOOGLE_DRIVE_URL</code>
              in the <code class="rounded bg-white px-1 py-0.5 text-xs">.env</code> file.
            </p>
          </div>
        </section>
      </div>
    </main>
  </div>
</template>