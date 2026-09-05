<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const isEnlarged = ref(false)

function openModal() {
  isEnlarged.value = true
  document.body.style.overflow = 'hidden' // Locks body scrolling
}

function closeModal() {
  isEnlarged.value = false
  document.body.style.overflow = '' // Restores body scrolling
}

// Allows closing the modal using the Escape key
function handleKeyDown(event) {
  if (event.key === 'Escape' && isEnlarged.value) {
    closeModal()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
  document.body.style.overflow = ''
})
</script>

<template>
  <div>
    <!-- Page Banner -->
    <div class="text-center py-12 mb-12 shadow-sm bg-blue-900 text-white">
      <div class="container mx-auto px-4">
        <h1 class="text-4xl md:text-5xl font-bold mb-2">Organizational Structure</h1>
        <p class="text-lg md:text-xl text-white/75 mb-0">Meet the dedicated leadership and faculty guiding LPENHS.</p>
      </div>
    </div>

    <!-- Main Content -->
    <main class="container mx-auto px-4 mb-12 pb-4">
      <div class="flex justify-center">
        <div class="w-full lg:w-5/6 xl:w-4/5">
          <div class="bg-white border-0 shadow-sm rounded-2xl overflow-hidden">
            <div class="p-6 md:p-12 text-center">
              
              <h3 class="text-2xl font-bold mb-6 text-slate-800">Current Academic Year Chart</h3>
              
              <!-- Interactive Image Container -->
              <!-- mx-auto centers the container itself -->
              <div 
                class="relative mx-auto rounded-xl overflow-hidden shadow-sm border border-gray-200 cursor-pointer group max-w-[800px]" 
                @click="openModal"
              >
                <!-- block and mx-auto centers the image inside the container -->
                <img 
                  src="/images/org_chart.jpg" 
                  alt="LPENHS Organizational Chart" 
                  class="block mx-auto w-full h-auto transition-transform duration-300 group-hover:scale-105" 
                />
                
                <!-- Hover Overlay -->
                <div class="absolute inset-0 bg-blue-900/60 flex justify-center items-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <span class="text-white text-xl font-bold flex items-center bg-black/40 px-4 py-2 rounded-lg shadow-lg">
                    <i class="fas fa-search-plus mr-2"></i> Click to Enlarge
                  </span>
                </div>
              </div>

              <!-- Action Buttons -->
              <div class="flex flex-col sm:flex-row justify-center gap-4 mt-8">
                <button 
                  type="button" 
                  class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center shadow-sm"
                  @click="openModal"
                >
                  <i class="fas fa-expand mr-2"></i> View Full Screen
                </button>
                <a 
                  href="/images/org_chart.jpg" 
                  download="LPENHS_Org_Chart.jpg" 
                  class="px-6 py-2.5 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center shadow-sm"
                >
                  <i class="fas fa-download mr-2"></i> Download Image
                </a>
              </div>

            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Vue Lightbox Overlay (Enlarged Modal View) -->
    <Teleport to="body">
      <Transition name="fade">
        <div 
          v-if="isEnlarged" 
          class="fixed inset-0 w-full h-full bg-black/80 z-[9999] flex justify-center items-center p-4 md:p-8"
          @click="closeModal"
        >
          <!-- Modal Content Container -->
          <div 
            class="relative bg-white rounded-2xl w-full max-w-[1200px] max-h-[95vh] flex flex-col shadow-2xl" 
            @click.stop
          >
            <!-- Modal Header -->
            <div class="flex justify-between items-center p-4 border-b border-gray-200">
              <h5 class="text-lg font-bold text-slate-800 m-0">
                LPENHS Organizational Chart
              </h5>
              <button 
                type="button" 
                class="text-gray-400 hover:text-gray-600 transition-colors" 
                aria-label="Close" 
                @click="closeModal"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <!-- Modal Body (Enlarged Image) -->
            <!-- flex, justify-center, and items-center ensure absolute centering if the image is smaller than the container -->
            <div class="overflow-auto p-4 flex justify-center items-center bg-gray-50 flex-grow">
              <img 
                src="/images/org_chart.jpg" 
                alt="Full Organizational Chart" 
                class="block mx-auto rounded shadow-sm object-contain" 
                style="max-height: calc(95vh - 140px);"
              />
            </div>

            <!-- Modal Footer -->
            <div class="flex justify-end p-4 border-t border-gray-200">
              <button 
                type="button" 
                class="px-5 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors font-medium" 
                @click="closeModal"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
/* Smooth Fade Transition for the Lightbox Modal */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>