import { supabase } from '../supabase'
import { roleFromEmail } from './roleEmail'

export const ROLE_STORAGE_KEY = 'laserv3.pendingRole'
export const PENDING_STORAGE_KEY = 'laserv3.pendingGoogleLogin'

export const DASHBOARD_BY_ROLE = {
  admin: { name: 'admin-dashboard' },
  teacher: { name: 'teacher-dashboard' },
  student: { name: 'student-dashboard' },
}

export async function fetchProfileRole(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', userId)
    .maybeSingle()

  if (error) throw error
  return data?.role ?? null
}

export async function fetchCurrentProfile() {
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) return null

  const { data, error } = await supabase
    .from('profiles')
    .select('id, role, name, address, contact_number, guardian, year, section')
    .eq('id', user.id)
    .maybeSingle()

  if (error) throw error
  
  // Attach the auth email to the profile data so the dashboard can access it
  return { ...data, email: user.email }
}

export function dashboardRouteForRole(role) {
  return DASHBOARD_BY_ROLE[role] ?? null
}

export async function assignProfileRole(userId, role) {
  const { error } = await supabase
    .from('profiles')
    .update({ role })
    .eq('id', userId)

  if (error) throw error
}

export async function resolveSessionRole(session) {
  const userId = session?.user?.id
  if (!userId) return null

  const emailRole = roleFromEmail(session.user.email)
  if (emailRole === 'teacher') {
    const currentRole = await fetchProfileRole(userId)
    if (currentRole === 'admin') return 'admin'
    if (currentRole !== 'teacher') {
      await assignProfileRole(userId, 'teacher')
    }
    return 'teacher'
  }

  return fetchProfileRole(userId)
}

export async function signOutUser() {
  sessionStorage.removeItem(ROLE_STORAGE_KEY)
  sessionStorage.removeItem(PENDING_STORAGE_KEY)
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}