<script setup>
import { computed, ref, watchEffect } from 'vue'
import { supabase } from '../supabase'

const props = defineProps({
  /** 'adm' | 'lesson_guide' | 'reviewer' */
  type: { type: String, required: true },
  /** Student's section from their profile */
  section: { type: String, default: '' },
  /** Display title shown as the card heading */
  title: { type: String, required: true },
})

const materials = ref([])
const loading = ref(false)
const error = ref('')

watchEffect(async () => {
  if (!props.type) return
  loading.value = true
  error.value = ''

  // Fetch rows where type matches AND (section is null OR section equals student's section)
  const { data, err } = await supabase
    .from('learning_materials')
    .select('*')
    .eq('type', props.type)
    .or(`section.is.null,section.eq.${props.section}`)
    .order('term')
    .order('subject')

  loading.value = false
  if (err) { error.value = 'Could not load materials.'; return }
  materials.value = data || []
})

// Group by term: { 1: [...], 2: [...], 3: [...] }
const byTerm = computed(() => {
  const groups = { 1: [], 2: [], 3: [] }
  for (const m of materials.value) {
    if (groups[m.term]) groups[m.term].push(m)
  }
  return groups
})

const termLabels = { 1: '1st Term', 2: '2nd Term', 3: '3rd Term' }
</script>

<template>
  <div class="space-y-4">
    <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <h2 class="text-lg font-semibold tracking-tight">{{ title }}</h2>
      <p class="mt-1 text-sm text-slate-600">Click any link to open the material in a new tab.</p>

      <p v-if="loading" class="mt-6 text-sm text-slate-500">Loading…</p>
      <p v-else-if="error" class="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">{{ error }}</p>

      <template v-else-if="materials.length === 0">
        <p class="mt-6 text-sm text-slate-500 italic">No materials available yet.</p>
      </template>

      <template v-else>
        <div v-for="termNum in [1, 2, 3]" :key="termNum" class="mt-6">
          <template v-if="byTerm[termNum].length > 0">
            <h3 class="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">{{ termLabels[termNum] }}</h3>
            <div class="space-y-2">
              <a
                v-for="m in byTerm[termNum]"
                :key="m.id"
                :href="m.url"
                target="_blank"
                rel="noopener noreferrer"
                class="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 hover:border-[#000080] hover:bg-white transition-colors group"
              >
                <div>
                  <p class="text-sm font-semibold text-slate-800 group-hover:text-[#000080]">{{ m.title }}</p>
                  <p class="mt-0.5 text-xs text-slate-500">{{ m.subject }}</p>
                </div>
                <svg class="h-4 w-4 shrink-0 text-slate-400 group-hover:text-[#000080]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>
            </div>
          </template>
        </div>
      </template>
    </div>
  </div>
</template>
