export const ROLE_EMAIL_DOMAINS = {
  teacher: '@deped.gov.ph',
  student: '@depedlaspinas.ph',
}

function studentTestEmails() {
  return (import.meta.env.VITE_STUDENT_TEST_EMAILS || '')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean)
}

export function isStudentTestEmail(email) {
  if (!email) return false
  return studentTestEmails().includes(email.trim().toLowerCase())
}

export function roleFromEmail(email) {
  if (!email) return null

  const normalizedEmail = email.trim().toLowerCase()

  if (normalizedEmail.endsWith(ROLE_EMAIL_DOMAINS.teacher)) return 'teacher'
  if (normalizedEmail.endsWith(ROLE_EMAIL_DOMAINS.student)) return 'student'
  if (isStudentTestEmail(normalizedEmail)) return 'student'
  return null
}

export function resolveLoginRole(email, selectedRole) {
  const assignedFromEmail = roleFromEmail(email)
  if (assignedFromEmail) return assignedFromEmail

  if (!selectedRole) return null
  if (!emailMatchesRole(email, selectedRole)) return null
  return selectedRole.trim().toLowerCase()
}

export function emailMatchesRole(email, role) {
  if (!email || !role) return false

  const normalizedEmail = email.trim().toLowerCase()
  const normalizedRole = role.trim().toLowerCase()

  if (normalizedRole === 'admin') return false

  const requiredDomain = ROLE_EMAIL_DOMAINS[normalizedRole]
  if (!requiredDomain) return false

  if (normalizedRole === 'student' && isStudentTestEmail(normalizedEmail)) return true

  return normalizedEmail.endsWith(requiredDomain)
}

export function domainErrorForRole(role, email) {
  const normalizedRole = role?.trim().toLowerCase()
  const domain = ROLE_EMAIL_DOMAINS[normalizedRole]

  if (!domain) return 'This account cannot be used with the selected role.'

  return `A ${normalizedRole} account must use an email ending with ${domain}. "${email}" is not allowed.`
}
