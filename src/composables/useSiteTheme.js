import { onMounted, ref } from 'vue'

const isDark = ref(false)

function applyTheme(dark) {
  isDark.value = dark
  document.documentElement.classList.toggle('dark', dark)
  document.documentElement.dataset.theme = dark ? 'dark' : 'light'
  localStorage.setItem('site-theme', dark ? 'dark' : 'light')
}

export function useSiteTheme() {
  onMounted(() => {
    applyTheme(localStorage.getItem('site-theme') === 'dark')
  })

  function toggleTheme() {
    applyTheme(!isDark.value)
  }

  return { isDark, toggleTheme }
}
