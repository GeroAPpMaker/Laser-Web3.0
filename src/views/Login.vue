<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import {
  PENDING_STORAGE_KEY,
  ROLE_STORAGE_KEY,
  assignProfileRole,
  dashboardRouteForRole,
  fetchProfileRole,
} from '../utils/auth'
import { domainErrorForRole, resolveLoginRole } from '../utils/roleEmail'

const router = useRouter()

const roles = [
  { value: 'teacher', label: 'Teacher' },
  { value: 'student', label: 'Student' },
]

const showAdminLogin = ref(false)
const showStudentTestLogin = ref(false)
const selectedRole = ref('')
const adminEmail = ref('')
const adminPassword = ref('')
const studentEmail = ref('')
const studentPassword = ref('')
const errorMessage = ref('')
const isSubmitting = ref(false)

let unsubscribeAuth = null
let loginHandled = false

function clearPendingLogin() {
  sessionStorage.removeItem(ROLE_STORAGE_KEY)
  sessionStorage.removeItem(PENDING_STORAGE_KEY)
}

function openAdminLogin() {
  errorMessage.value = ''
  showStudentTestLogin.value = false
  showAdminLogin.value = true
}

function openStudentTestLogin() {
  errorMessage.value = ''
  showAdminLogin.value = false
  showStudentTestLogin.value = true
}

function backToGoogleLogin() {
  errorMessage.value = ''
  adminPassword.value = ''
  studentPassword.value = ''
  showAdminLogin.value = false
  showStudentTestLogin.value = false
}

async function rejectLogin(message) {
  clearPendingLogin()
  await supabase.auth.signOut()
  window.history.replaceState({}, document.title, '/login')
  errorMessage.value = message
  isSubmitting.value = false
}

async function finishPendingLogin(session) {
  if (loginHandled) return
  if (sessionStorage.getItem(PENDING_STORAGE_KEY) !== '1') return
  if (!session?.user) return

  loginHandled = true

  const pendingRole = sessionStorage.getItem(ROLE_STORAGE_KEY)
  const email = session.user.email
  const assignedRole = resolveLoginRole(email, pendingRole)

  if (!assignedRole || assignedRole === 'admin') {
    await rejectLogin(domainErrorForRole(pendingRole, email || ''))
    loginHandled = false
    return
  }

  clearPendingLogin()
  errorMessage.value = ''

  try {
    await assignProfileRole(session.user.id, assignedRole)
    const destination = dashboardRouteForRole(assignedRole)
    if (!destination) {
      await rejectLogin('No profile role was found for this account.')
      loginHandled = false
      return
    }
    await router.replace(destination)
  } catch {
    await rejectLogin('Could not load your profile. Try signing in again.')
    loginHandled = false
  }
}

async function signInWithGoogle() {
  errorMessage.value = ''

  if (!selectedRole.value) {
    errorMessage.value = 'Select a role before signing in.'
    return
  }

  isSubmitting.value = true
  loginHandled = false
  sessionStorage.setItem(ROLE_STORAGE_KEY, selectedRole.value)
  sessionStorage.setItem(PENDING_STORAGE_KEY, '1')

  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/login`,
      queryParams: {
        prompt: 'select_account',
      },
    },
  })

  if (error) {
    await rejectLogin(error.message)
  }
}

async function signInAsAdmin() {
  errorMessage.value = ''
  clearPendingLogin()

  const email = adminEmail.value.trim()
  const password = adminPassword.value

  if (!email || !password) {
    errorMessage.value = 'Enter your admin email and password.'
    return
  }

  isSubmitting.value = true

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      errorMessage.value = error.message
      return
    }

    const role = await fetchProfileRole(data.user.id)
    if (role !== 'admin') {
      await supabase.auth.signOut()
      errorMessage.value = 'This account is not an admin.'
      return
    }

    await router.replace({ name: 'admin-dashboard' })
  } catch {
    errorMessage.value = 'Could not sign in. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}

async function signInAsStudent() {
  errorMessage.value = ''
  clearPendingLogin()

  const email = studentEmail.value.trim()
  const password = studentPassword.value

  if (!email || !password) {
    errorMessage.value = 'Enter the student test email and password.'
    return
  }

  isSubmitting.value = true

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      errorMessage.value = error.message
      return
    }

    const currentRole = await fetchProfileRole(data.user.id)
    if (currentRole === 'admin' || currentRole === 'teacher') {
      await supabase.auth.signOut()
      errorMessage.value = 'This account is not a student.'
      return
    }

    await assignProfileRole(data.user.id, 'student')
    await router.replace({ name: 'student-dashboard' })
  } catch {
    errorMessage.value = 'Could not sign in. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}

onMounted(() => {
  const storedRole = sessionStorage.getItem(ROLE_STORAGE_KEY)
  if (storedRole && storedRole !== 'admin') selectedRole.value = storedRole

  const { data } = supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN' || (event === 'INITIAL_SESSION' && session)) {
      finishPendingLogin(session)
    }
  })
  unsubscribeAuth = data.subscription.unsubscribe
})

onUnmounted(() => {
  unsubscribeAuth?.()
})
</script>

<template>
  <div class="flex flex-1 items-center bg-slate-50 text-slate-900">
    <main class="mx-auto flex w-full max-w-md items-center px-4 py-10">
      <section class="w-full rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
        <h1 class="text-2xl font-semibold tracking-tight">Sign in</h1>

        <template v-if="!showAdminLogin && !showStudentTestLogin">
          <p class="mt-2 text-sm text-slate-600">
            Choose your role, then continue with Google.
          </p>

          <label class="mt-6 block text-sm font-medium text-slate-700" for="role">
            Role
          </label>
          <select
            id="role"
            v-model="selectedRole"
            class="mt-1.5 w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
          >
            <option disabled value="">Select a role</option>
            <option v-for="role in roles" :key="role.value" :value="role.value">
              {{ role.label }}
            </option>
          </select>

          <p class="mt-2 text-xs text-slate-500">
            Google accounts ending in @deped.gov.ph are signed in as teachers
            automatically. Students normally need an @depedlaspinas.ph email.
            Use Student test login if you do not have that domain.
          </p>

          <p
            v-if="errorMessage"
            class="mt-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
            role="alert"
          >
            {{ errorMessage }}
          </p>

          <button
            type="button"
            class="mt-6 flex w-full items-center justify-center gap-3 rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-medium text-slate-800 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="isSubmitting"
            @click="signInWithGoogle"
          >
            <svg class="h-5 w-5" viewBox="0 0 24 24" aria-hidden="true">
              <path
                fill="#4285F4"
                d="M23.49 12.27c0-.79-.07-1.54-.2-2.27H12v4.3h6.46a5.52 5.52 0 0 1-2.4 3.62v3h3.88c2.27-2.09 3.55-5.17 3.55-8.65Z"
              />
              <path
                fill="#34A853"
                d="M12 24c3.24 0 5.96-1.07 7.95-2.9l-3.88-3c-1.08.72-2.47 1.15-4.07 1.15-3.13 0-5.78-2.11-6.73-4.96H1.27v3.09A12 12 0 0 0 12 24Z"
              />
              <path
                fill="#FBBC05"
                d="M5.27 14.29A7.21 7.21 0 0 1 4.89 12c0-.8.14-1.57.38-2.29V6.62H1.27A12 12 0 0 0 0 12c0 1.94.46 3.77 1.27 5.38l4-3.09Z"
              />
              <path
                fill="#EA4335"
                d="M12 4.75c1.76 0 3.35.6 4.6 1.78l3.45-3.45C17.95 1.14 15.24 0 12 0 7.31 0 3.23 2.69 1.27 6.62l4 3.09C6.22 6.86 8.87 4.75 12 4.75Z"
              />
            </svg>
            {{ isSubmitting ? 'Redirecting…' : 'Sign in with Google' }}
          </button>

          <button
            type="button"
            class="mt-3 w-full rounded-lg px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
            :disabled="isSubmitting"
            @click="openStudentTestLogin"
          >
            Student test login
          </button>

          <button
            type="button"
            class="w-full rounded-lg px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
            :disabled="isSubmitting"
            @click="openAdminLogin"
          >
            Login as admin
          </button>
        </template>

        <template v-else-if="showStudentTestLogin">
          <p class="mt-2 text-sm text-slate-600">
            Sign in with a student test email and password. Create this user in
            the Supabase Authentication dashboard; no DepEd domain is required.
          </p>

          <form class="mt-6 grid gap-4" @submit.prevent="signInAsStudent">
            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Email</span>
              <input
                v-model="studentEmail"
                type="email"
                name="student-email"
                autocomplete="username"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Password</span>
              <input
                v-model="studentPassword"
                type="password"
                name="student-password"
                autocomplete="current-password"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <p
              v-if="errorMessage"
              class="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
              role="alert"
            >
              {{ errorMessage }}
            </p>

            <button
              type="submit"
              class="rounded-lg bg-slate-900 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="isSubmitting"
            >
              {{ isSubmitting ? 'Signing in…' : 'Sign in as student' }}
            </button>
          </form>

          <button
            type="button"
            class="mt-3 w-full rounded-lg px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
            :disabled="isSubmitting"
            @click="backToGoogleLogin"
          >
            Back to Google sign in
          </button>
        </template>

        <template v-else>
          <p class="mt-2 text-sm text-slate-600">
            Sign in with your admin email and password.
          </p>

          <form class="mt-6 grid gap-4" @submit.prevent="signInAsAdmin">
            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Email</span>
              <input
                v-model="adminEmail"
                type="email"
                name="email"
                autocomplete="username"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-slate-700">Password</span>
              <input
                v-model="adminPassword"
                type="password"
                name="password"
                autocomplete="current-password"
                class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-sm outline-none focus:border-slate-500 focus:ring-2 focus:ring-slate-200"
              />
            </label>

            <p
              v-if="errorMessage"
              class="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
              role="alert"
            >
              {{ errorMessage }}
            </p>

            <button
              type="submit"
              class="rounded-lg bg-slate-900 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="isSubmitting"
            >
              {{ isSubmitting ? 'Signing in…' : 'Sign in' }}
            </button>
          </form>

          <button
            type="button"
            class="mt-3 w-full rounded-lg px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 hover:text-slate-900"
            :disabled="isSubmitting"
            @click="backToGoogleLogin"
          >
            Back to Google sign in
          </button>
        </template>
      </section>
    </main>
  </div>
</template>
