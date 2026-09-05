<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const isEnlarged = ref(false)

// Dictionary holding data for each department
const departmentsData = {
  'araling-panlipunan': {
    title: 'Araling Panlipunan',
    description: 'Fostering historical awareness and deep understanding of society.',
    orgChart: '/images/org-ap.jpg'
  },
  'english': {
    title: 'English Department',
    description: 'Empowering students through effective global communication and literature.',
    orgChart: '/images/org-english.jpg'
  },
  'esp': {
    title: 'Edukasyon sa Pagpapakatao (ESP)',
    description: 'Guiding students toward strong moral values and ethical decision-making.',
    orgChart: '/images/org-esp.jpg'
  },
  'filipino': {
    title: 'Filipino Department',
    description: 'Pinagyayaman ang wikang pambansa at panitikang Pilipino.',
    orgChart: '/images/org-filipino.jpg'
  },
  'science': {
    title: 'Science Department',
    description: 'Cultivating analytical thinking and scientific discovery.',
    orgChart: '/images/org-science.jpg'
  },
  'mapeh': {
    title: 'MAPEH',
    description: 'Nurturing physical wellness, artistic expression, and holistic health.',
    orgChart: '/images/org-mapeh.jpg'
  },
  'mathematics': {
    title: 'Mathematics Department',
    description: 'Developing logical reasoning and complex problem-solving skills.',
    orgChart: '/images/org-math.jpg'
  },
  'tle': {
    title: 'Technology and Livelihood Education',
    description: 'Equipping students with practical skills for future careers.',
    orgChart: '/images/org-tle.jpg'
  }
}

// Automatically updates when the URL changes (e.g., from /english to /science)
const currentDept = computed(() => {
  const subjectSlug = route.params.subject
  return departmentsData[subjectSlug] || {
    title: 'Department Not Found',
    description: 'Please select a valid department from the menu.',
    orgChart: ''
  }
})

// Modal Logic
function openModal() {
  if (currentDept.value.orgChart) {
    isEnlarged.value = true
    document.body.style.overflow = 'hidden'
  }
}

function closeModal() {
  isEnlarged.value = false
  document.body.style.overflow = ''
}

function handleKeyDown(event) {
  if (event.key === 'Escape' && isEnlarged.value) closeModal()
}

onMounted(() => window.addEventListener('keydown', handleKeyDown))
onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
  document.body.style.overflow = ''
})
</script>

<template>
  <div>
    <!-- Dynamic Page Banner -->
    <div class="text-center py-12 mb-12 shadow-sm bg-blue-900 text-white">
      <div class="container mx-auto px-4">
        <h1 class="text-4xl md:text-5xl font-bold mb-2">{{ currentDept.title }}</h1>
        <p class="text-lg md:text-xl text-white/75 mb-0">{{ currentDept.description }}</p>
      </div>
    </div>

    <!-- Main Content -->
    <main class="container mx-auto px-4 mb-12 pb-4">
      <div class="flex justify-center">
        <div class="w-full lg:w-5/6 xl:w-4/5">
          <div class="bg-white border-0 shadow-sm rounded-2xl overflow-hidden p-6 md:p-12 text-center">
            
            <h3 class="text-2xl font-bold mb-6 text-slate-800">Department Organizational Chart</h3>
            
            <!-- Conditional Rendering if image exists -->
            <div v-if="currentDept.orgChart">
              <div 
                class="relative mx-auto rounded-xl overflow-hidden shadow-sm border border-gray-200 cursor-pointer group max-w-[800px]" 
                @click="openModal"
              >
                <img 
                  :src="currentDept.orgChart" 
                  :alt="`${currentDept.title} Organizational Chart`" 
                  class="block mx-auto w-full h-auto transition-transform duration-300 group-hover:scale-105" 
                />
                <div class="absolute inset-0 bg-blue-900/60 flex justify-center items-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <span class="text-white text-xl font-bold flex items-center bg-black/40 px-4 py-2 rounded-lg shadow-lg">
                    <i class="fas fa-search-plus mr-2"></i> Click to Enlarge
                  </span>
                </div>
              </div>

              <!-- Action Buttons -->
              <div class="flex flex-col sm:flex-row justify-center gap-4 mt-8">
                <button type="button" class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center shadow-sm" @click="openModal">
                  <i class="fas fa-expand mr-2"></i> View Full Screen
                </button>
                <a :href="currentDept.orgChart" :download="`LPENHS_${currentDept.title}_OrgChart.jpg`" class="px-6 py-2.5 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center shadow-sm">
                  <i class="fas fa-download mr-2"></i> Download Image
                </a>
              </div>
            </div>

            <!-- Fallback if no image -->
            <div v-else class="py-12 text-gray-400">
              <i class="fas fa-image fa-3x mb-3"></i>
              <p>Organizational chart currently unavailable.</p>
            </div>

          </div>
        </div>
      </div>
    </main>

    <!-- Vue Lightbox Overlay -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="isEnlarged" class="fixed inset-0 w-full h-full bg-black/80 z-[9999] flex justify-center items-center p-4 md:p-8" @click="closeModal">
          <div class="relative bg-white rounded-2xl w-full max-w-[1200px] max-h-[95vh] flex flex-col shadow-2xl" @click.stop>
            <div class="flex justify-between items-center p-4 border-b border-gray-200">
              <h5 class="text-lg font-bold text-slate-800 m-0">{{ currentDept.title }} Chart</h5>
              <button type="button" class="text-gray-400 hover:text-gray-600 transition-colors" @click="closeModal">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
              </button>
            </div>
            <div class="overflow-auto p-4 flex justify-center items-center bg-gray-50 flex-grow">
              <img :src="currentDept.orgChart" :alt="currentDept.title" class="block mx-auto rounded shadow-sm object-contain" style="max-height: calc(95vh - 140px);"/>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.25s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>