<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useSiteTheme } from '../composables/useSiteTheme'
import { supabase } from '../supabase'
import { signOutUser } from '../utils/auth'

const { isDark, toggleTheme } = useSiteTheme()
const router = useRouter()
const mobileOpen = ref(false)
const openDropdown = ref(null)
const isSignedIn = ref(false)
const isSigningOut = ref(false)

let unsubscribeAuth = null

// Internal Vue Router links
const aboutItems = [
  { to: '/about', label: 'LPENHS Profile' }, 
  { to: '/organizational-chart', label: 'Organizational Chart' }, 
  { to: '/news', label: 'News & Updates' },
]

const departmentItems = [
  { to: '/department/araling-panlipunan', label: 'Araling Panlipunan' },
  { to: '/department/english', label: 'English' },
  { to: '/department/esp', label: 'ESP' },
  { to: '/department/filipino', label: 'Filipino' },
  { to: '/department/science', label: 'Science' },
  { to: '/department/mapeh', label: 'MAPEH' },
  { to: '/department/mathematics', label: 'Mathematics' },
  { to: '/department/tle', label: 'TLE' },
]

// Updated: Converted Offices to use internal Vue Router links
const officeItems = [
  { to: '/office/principals-office', label: "Principal's Office" },
  { to: '/office/guidance-office', label: 'Guidance Office' },
  { to: '/office/clinic', label: 'Clinic' },
  { to: '/office/records', label: 'Records' },
  { to: '/office/sbm', label: 'SBM' },
]

const helpItems = [
  { href: 'FAQ.html', label: 'FAQs', target: '_blank', icon: 'help' },
  { to: '/contact', label: 'Contact Us', icon: 'headset' },
  { divider: true },
  {
    href: 'https://forms.office.com/Pages/ResponsePage.aspx?id=gKvjQCQgo0W_dnoHYaJNKXnMyzDDnJlNgwZDPrj4MWBUQU0zWEVFWUhPWU45UjA2VFNEMUlJVlhSTy4u',
    label: 'Leave A Message',
    target: '_blank',
    icon: 'mail',
  },
]

function toggleDropdown(id) {
  openDropdown.value = openDropdown.value === id ? null : id
}

function closeMenu() {
  openDropdown.value = null
  mobileOpen.value = false
}

function onDocumentClick(event) {
  if (!event.target.closest('[data-nav-root]')) {
    openDropdown.value = null
  }
}

onMounted(() => {
  document.addEventListener('click', onDocumentClick)

  supabase.auth.getSession().then(({ data }) => {
    isSignedIn.value = Boolean(data.session)
  })

  const { data } = supabase.auth.onAuthStateChange((_event, session) => {
    isSignedIn.value = Boolean(session)
  })
  unsubscribeAuth = data.subscription.unsubscribe
})

onUnmounted(() => {
  document.removeEventListener('click', onDocumentClick)
  unsubscribeAuth?.()
})

async function signOut() {
  isSigningOut.value = true
  try {
    await signOutUser()
    await router.replace('/')
  } finally {
    isSigningOut.value = false
  }
}
</script>

<template>
  <header class="sticky top-0 z-50 bg-school-primary shadow-[0_4px_10px_rgba(0,0,0,0.15)]" data-nav-root>
    <nav class="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-3">
      <RouterLink class="flex items-center gap-3" to="/" @click="closeMenu">
        <img
          class="h-[55px] w-[55px] rounded-full bg-white object-cover shadow-sm"
          src="/images/Optimized-LR_favicon.jpg"
          alt="LPENHS Logo"
          width="55"
          height="55"
        />
        <img
          class="hidden h-auto w-40 sm:block"
          src="/images/LR_logo-removebg-preview.png"
          alt="LASER-web"
          width="160"
        />
      </RouterLink>

      <button
        type="button"
        class="rounded-lg p-2 text-white lg:hidden"
        aria-label="Toggle navigation"
        @click="mobileOpen = !mobileOpen"
      >
        <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      <div
        class="absolute left-0 right-0 top-full bg-school-primary px-4 pb-4 lg:static lg:flex lg:items-center lg:bg-transparent lg:px-0 lg:pb-0"
        :class="mobileOpen ? 'block' : 'hidden lg:flex'"
      >
        <ul class="flex flex-col gap-1 lg:ml-auto lg:flex-row lg:items-center lg:gap-2">
          
          <!-- Home Link -->
          <li class="relative">
            <RouterLink
              to="/"
              class="block rounded-md px-4 py-2 text-sm font-medium tracking-wide text-white hover:text-slate-200"
              @click="closeMenu"
            >
              Home
            </RouterLink>
          </li>
          
          <!-- About Dropdown -->
          <li class="relative">
            <a
              class="block rounded-md px-4 py-2 text-sm font-medium tracking-wide text-white hover:text-slate-200"
              href="#"
              id="aboutDropdown"
              role="button"
              aria-expanded="false"
              @click.prevent="toggleDropdown('about')"
            >
              About
            </a>
            <ul
              v-if="openDropdown === 'about'"
              class="mt-1 min-w-52 rounded-lg border border-slate-200 bg-white p-2 shadow-lg lg:absolute lg:right-0 lg:mt-2"
            >
              <li v-for="item in aboutItems" :key="item.label">
                <RouterLink
                  class="block rounded-md px-3 py-2 text-sm font-medium text-slate-800 hover:bg-school-primary/5 hover:text-school-primary"
                  :to="item.to"
                  @click="closeMenu"
                >
                  {{ item.label }}
                </RouterLink>
              </li>
            </ul>
          </li>

          <!-- Departments Dropdown -->
          <li class="relative">
            <a
              class="block rounded-md px-4 py-2 text-sm font-medium tracking-wide text-white hover:text-slate-200"
              href="#"
              id="deptDropdown"
              role="button"
              @click.prevent="toggleDropdown('departments')"
            >
              Departments
            </a>
            <ul
              v-if="openDropdown === 'departments'"
              class="mt-1 min-w-52 rounded-lg border border-slate-200 bg-white p-2 shadow-lg lg:absolute lg:right-0 lg:mt-2"
            >
              <li v-for="item in departmentItems" :key="item.label">
                <RouterLink
                  class="block rounded-md px-3 py-2 text-sm font-medium text-slate-800 hover:bg-school-primary/5 hover:text-school-primary"
                  :to="item.to"
                  @click="closeMenu"
                >
                  {{ item.label }}
                </RouterLink>
              </li>
            </ul>
          </li>

          <!-- Offices Dropdown -->
          <li class="relative">
            <a
              class="block rounded-md px-4 py-2 text-sm font-medium tracking-wide text-white hover:text-slate-200"
              href="#"
              id="officesDropdown"
              role="button"
              @click.prevent="toggleDropdown('offices')"
            >
              Offices
            </a>
            <ul
              v-if="openDropdown === 'offices'"
              class="mt-1 min-w-52 rounded-lg border border-slate-200 bg-white p-2 shadow-lg lg:absolute lg:right-0 lg:mt-2"
            >
              <li v-for="item in officeItems" :key="item.label">
                <RouterLink
                  class="block rounded-md px-3 py-2 text-sm font-medium text-slate-800 hover:bg-school-primary/5 hover:text-school-primary"
                  :to="item.to"
                  @click="closeMenu"
                >
                  {{ item.label }}
                </RouterLink>
              </li>
            </ul>
          </li>

          <!-- Help Dropdown -->
          <li class="relative">
            <a
              class="block rounded-md px-4 py-2 text-sm font-medium tracking-wide text-white hover:text-slate-200"
              href="#"
              id="helpDropdown"
              role="button"
              @click.prevent="toggleDropdown('help')"
            >
              Help
            </a>
            <ul
              v-if="openDropdown === 'help'"
              class="mt-1 min-w-56 rounded-lg border border-slate-200 bg-white p-2 shadow-lg lg:absolute lg:right-0 lg:mt-2"
            >
              <template v-for="(item, index) in helpItems" :key="item.label || index">
                <li v-if="item.divider" class="my-1 border-t border-slate-200"></li>
                <li v-else-if="item.to">
                  <RouterLink
                    class="block rounded-md px-3 py-2 text-sm font-medium text-slate-800 hover:bg-school-primary/5 hover:text-school-primary"
                    :to="item.to"
                    @click="closeMenu"
                  >
                    {{ item.label }}
                  </RouterLink>
                </li>
                <li v-else>
                  <a
                    class="block rounded-md px-3 py-2 text-sm font-medium text-slate-800 hover:bg-school-primary/5 hover:text-school-primary"
                    :href="item.href"
                    :target="item.target"
                    @click="closeMenu"
                  >
                    {{ item.label }}
                  </a>
                </li>
              </template>
            </ul>
          </li>

          <li v-if="isSignedIn" class="relative">
            <RouterLink
              to="/teacher"
              class="block rounded-md px-4 py-2 text-sm font-medium tracking-wide text-white hover:text-slate-200"
              @click="closeMenu"
            >
              My Account
            </RouterLink>
          </li>

          <li class="mt-3 flex items-center gap-3 lg:mt-0 lg:ml-3">
            <button
              id="themeToggle"
              type="button"
              class="flex h-9 w-9 items-center justify-center rounded-full border border-white/20 bg-white/10 text-white shadow-sm hover:bg-white hover:text-school-primary"
              title="Toggle Dark Mode"
              @click="toggleTheme"
            >
              <span class="sr-only">Toggle Dark Mode</span>
              <svg v-if="!isDark" class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M21 14.5A8.5 8.5 0 1 1 9.5 3 7 7 0 0 0 21 14.5Z" />
              </svg>
              <svg v-else class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                <path
                  d="M12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12Zm0 4a1 1 0 0 1-1-1v-1a1 1 0 1 1 2 0v1a1 1 0 0 1-1 1Zm0-18a1 1 0 0 1-1-1V2a1 1 0 1 1 2 0v1a1 1 0 0 1-1 1Zm10 7h-1a1 1 0 1 1 0-2h1a1 1 0 1 1 0 2ZM3 12H2a1 1 0 1 1 0-2h1a1 1 0 1 1 0 2Zm15.66 6.66-.7-.7a1 1 0 0 1 1.41-1.42l.7.71a1 1 0 1 1-1.41 1.41ZM5.64 6.34l-.7-.7A1 1 0 0 1 6.34 4.2l.7.71A1 1 0 1 1 5.64 6.34Zm12.72-2.12.7-.71a1 1 0 1 1 1.42 1.41l-.71.71a1 1 0 0 1-1.41-1.41ZM4.93 19.07l-.7.7a1 1 0 1 1-1.42-1.4l.71-.71a1 1 0 0 1 1.41 1.41Z"
                />
              </svg>
            </button>
            <button
              v-if="isSignedIn"
              type="button"
              class="rounded-full bg-white px-4 py-2 text-sm font-semibold text-school-primary shadow hover:bg-slate-100 disabled:opacity-60"
              :disabled="isSigningOut"
              @click="signOut"
            >
              {{ isSigningOut ? 'Signing out…' : 'Sign Out' }}
            </button>
            <RouterLink
              v-else
              class="rounded-full bg-white px-4 py-2 text-sm font-semibold text-school-primary shadow hover:bg-slate-100"
              to="/login"
              @click="closeMenu"
            >
              Login
            </RouterLink>
          </li>
        </ul>
      </div>
    </nav>
  </header>
</template>