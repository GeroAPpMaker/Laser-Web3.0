<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import DashboardHeader from '../components/DashboardHeader.vue'
import { supabase } from '../supabase'
import { fetchCurrentProfile } from '../utils/auth'

const profileName = ref('')
const loadError = ref('')
const saveError = ref('')
const saveSuccess = ref('')
const isLoading = ref(true)
const isSaving = ref(false)

const form = reactive({
  name: '',
  address: '',
  contact_number: '',
  guardian: '',
  year: '',
  section: '',
})

const welcomeName = computed(() => profileName.value.trim() || 'Student')
const display = (value) => (value && String(value).trim()) || '—'

const saved = reactive({
  name: '',
  address: '',
  contact_number: '',
  guardian: '',
  year: '',
  section: '',
})

function applyProfile(profile) {
  form.name = profile?.name ?? ''
  form.address = profile?.address ?? ''
  form.contact_number = profile?.contact_number ?? ''
  form.guardian = profile?.guardian ?? ''
  form.year = profile?.year ?? ''
  form.section = profile?.section ?? ''
  profileName.value = form.name
  saved.name = form.name
  saved.address = form.address
  saved.contact_number = form.contact_number
  saved.guardian = form.guardian
  saved.year = form.year
  saved.section = form.section
}

onMounted(async () => {
  try {
    const profile = await fetchCurrentProfile()
    applyProfile(profile)
  } catch {
    loadError.value = 'Could not load your profile.'
  } finally {
    isLoading.value = false
  }
})

async function saveProfile() {
  saveError.value = ''
  saveSuccess.value = ''
  isSaving.value = true

  try {
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      saveError.value = 'You must be signed in to save your profile.'
      return
    }

    const { error } = await supabase
      .from('profiles')
      .update({
        name: form.name.trim() || null,
        address: form.address.trim() || null,
        contact_number: form.contact_number.trim() || null,
        guardian: form.guardian.trim() || null,
        year: form.year.trim() || null,
        section: form.section.trim() || null,
      })
      .eq('id', user.id)

    if (error) throw error

    const updated = await fetchCurrentProfile()
    applyProfile(updated)
    saveSuccess.value = 'Profile saved.'
  } catch {
    saveError.value = 'Could not save your profile. Please try again.'
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <div class="flex-1 bg-slate-50 text-slate-900">
    <DashboardHeader :title="`Welcome ${welcomeName}`" />

    <main class="mx-auto max-w-3xl px-4 py-8">
      <section class="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
        <h2 class="text-lg font-semibold tracking-tight">Your profile</h2>
        <p class="mt-1 text-sm text-slate-600">This is the information currently saved for your account.</p>

        <p v-if="isLoading" class="mt-4 text-sm text-slate-500">Loading your profile…</p>
        <dl v-else class="mt-6 grid gap-4 sm:grid-cols-2">
          <div>
            <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Name</dt>
            <dd class="mt-1 text-sm text-slate-900">{{ display(saved.name) }}</dd>
          </div>
          <div>
            <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Contact Number</dt>
            <dd class="mt-1 text-sm text-slate-900">{{ display(saved.contact_number) }}</dd>
          </div>
          <div class="sm:col-span-2">
            <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Address</dt>
            <dd class="mt-1 text-sm text-slate-900">{{ display(saved.address) }}</dd>
          </div>
          <div>
            <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Guardian</dt>
            <dd class="mt-1 text-sm text-slate-900">{{ display(saved.guardian) }}</dd>
          </div>
          <div>
            <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Year</dt>
            <dd class="mt-1 text-sm text-slate-900">{{ display(saved.year) }}</dd>
          </div>
          <div>
            <dt class="text-xs font-medium uppercase tracking-wide text-slate-500">Section</dt>
            <dd class="mt-1 text-sm text-slate-900">{{ display(saved.section) }}</dd>
          </div>
        </dl>
      </section>

      <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
        <h2 class="text-lg font-semibold tracking-tight">Edit Profile</h2>
        <p class="mt-1 text-sm text-slate-600">Update your student information.</p>

        <p v-if="loadError" class="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
          {{ loadError }}
        </p>

        <form class="mt-6 grid gap-4" @submit.prevent="saveProfile">
          <label class="block">
            <span class="mb-1.5 block text-sm font-medium text-slate-700">Name</span>
            <input
              v-model="form.name"
              type="text"
              name="name"
              autocomplete="name"
              class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
            />
          </label>

          <label class="block">
            <span class="mb-1.5 block text-sm font-medium text-slate-700">Address</span>
            <input
              v-model="form.address"
              type="text"
              name="address"
              autocomplete="street-address"
              class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
            />
          </label>

          <label class="block">
            <span class="mb-1.5 block text-sm font-medium text-slate-700">Contact Number</span>
            <input
              v-model="form.contact_number"
              type="tel"
              name="contact_number"
              autocomplete="tel"
              class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
            />
          </label>

          <label class="block">
            <span class="mb-1.5 block text-sm font-medium text-slate-700">Guardian</span>
            <input
              v-model="form.guardian"
              type="text"
              name="guardian"
              autocomplete="off"
              class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
            />
          </label>

          <div class="grid gap-4 sm:grid-cols-2">
            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Year</span>
              <input
                v-model="form.year"
                type="text"
                name="year"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Section</span>
              <input
                v-model="form.section"
                type="text"
                name="section"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>
          </div>

          <p
            v-if="saveError"
            class="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
            role="alert"
          >
            {{ saveError }}
          </p>

          <p
            v-if="saveSuccess"
            class="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800"
          >
            {{ saveSuccess }}
          </p>

          <button
            type="submit"
            class="mt-2 rounded-lg bg-slate-900 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="isLoading || isSaving"
          >
            {{ isSaving ? 'Saving…' : 'Save profile' }}
          </button>
        </form>
      </section>
    </main>
  </div>
</template>
