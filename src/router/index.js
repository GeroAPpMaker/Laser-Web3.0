import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../supabase'
import {
  PENDING_STORAGE_KEY,
  dashboardRouteForRole,
  resolveSessionRole,
} from '../utils/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
    },
    {
      path: '/about',
      name: 'about',
      component: () => import('../views/About.vue'), 
    },
    {
      path: '/organizational-chart',
      name: 'organizational-chart',
      component: () => import('../views/OrgChart.vue'),
    },
    {
      path: '/contact',
      name: 'contact',
      component: () => import('../views/Contact.vue'),
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/Login.vue'),
    },
    {
      path: '/admin',
      name: 'admin-dashboard',
      component: () => import('../views/AdminDashboard.vue'),
      meta: { requiresAuth: true, role: 'admin' },
    },
    {
      path: '/teacher',
      name: 'teacher-dashboard',
      component: () => import('../views/TeacherDashboard.vue'),
      meta: { requiresAuth: true, role: 'teacher' },
    },
    // ADDED: Adviser Dashboard Route
    {
      path: '/adviser',
      name: 'adviser-dashboard',
      component: () => import('../views/AdviserDashboard.vue'),
      meta: { requiresAuth: true, role: 'teacher' }, // Assumes advisers share the 'teacher' role in auth
    },
    {
      path: '/student',
      name: 'student-dashboard',
      component: () => import('../views/StudentDashboard.vue'),
      meta: { requiresAuth: true, role: 'student' },
    },
    {
      path: '/department/:subject',
      name: 'department',
      component: () => import('../views/Department.vue'),
    },
    // Add this inside the routes array in src/router/index.js
    {
      path: '/term-grade',
      name: 'term-grade',
      component: () => import('../views/TermGradeView.vue'),
      meta: { requiresAuth: true, role: 'teacher' },
    },
    {
      path: '/office/:name',
      name: 'office',
      component: () => import('../views/Office.vue'),
    },
  ],
})

router.beforeEach(async (to) => {
  const requiresAuth = to.matched.some((record) => record.meta.requiresAuth)
  const {
    data: { session },
  } = await supabase.auth.getSession()

  if (requiresAuth && !session) {
    return { name: 'login' }
  }

  const pendingLogin = sessionStorage.getItem(PENDING_STORAGE_KEY) === '1'

  if (to.name === 'login' && session && !pendingLogin) {
    const role = await resolveSessionRole(session)
    return dashboardRouteForRole(role) || true
  }

  if (requiresAuth && session) {
    const role = await resolveSessionRole(session)
    const home = dashboardRouteForRole(role)
    if (!home) return { name: 'login' }
    
    // Check if the route restricts access by role
    if (to.meta.role && to.meta.role !== role) {
      // Allow users with 'admin' or 'teacher' role to access adviser dashboard
      if (to.name === 'adviser-dashboard' && (role === 'teacher' || role === 'admin')) {
        return true
      }
      return home
    }
  }
})

export default router