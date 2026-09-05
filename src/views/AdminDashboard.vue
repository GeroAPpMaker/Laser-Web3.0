<script setup>
import { computed, onMounted, ref } from 'vue'
import DashboardHeader from '../components/DashboardHeader.vue'
import { fetchCurrentProfile } from '../utils/auth'

const profileName = ref('')
const loadError = ref('')

const welcomeName = computed(() => profileName.value.trim() || 'Admin')

const tableColumns = ['Name', 'Email', 'Role', 'Year', 'Section']

onMounted(async () => {
  try {
    const profile = await fetchCurrentProfile()
    profileName.value = profile?.name ?? ''
  } catch {
    loadError.value = 'Could not load your profile.'
  }
})
</script>

<template>
  <div class="flex-1 bg-slate-50 text-slate-900">
    <DashboardHeader :title="`Welcome ${welcomeName}`" wide>
      <p v-if="loadError" class="mt-2 text-sm text-red-700">{{ loadError }}</p>
    </DashboardHeader>

    <main class="mx-auto max-w-5xl px-4 py-8">
      <section class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 px-6 py-5">
          <h2 class="text-lg font-semibold tracking-tight">Manage users</h2>
          <p class="mt-1 text-sm text-slate-600">
            User records will appear here.
          </p>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full text-left text-sm">
            <thead class="bg-slate-50 text-slate-600">
              <tr>
                <th
                  v-for="column in tableColumns"
                  :key="column"
                  class="px-6 py-3 font-medium"
                >
                  {{ column }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td :colspan="tableColumns.length" class="px-6 py-12 text-center text-slate-500">
                  No users to display yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>
  </div>
</template>
