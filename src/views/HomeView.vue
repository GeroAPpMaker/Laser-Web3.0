<script setup>
import { onMounted, onUnmounted, ref } from 'vue'

const slides = [
  { src: '/images/Portal1.jpg', alt: 'Portal Preview 1' },
  { src: '/images/LR1 (2).png', alt: 'Portal Preview 2' },
  { src: '/images/portal 2.jpg', alt: 'Portal Preview 3' },
  { src: '/images/portal 3.PNG', alt: 'Portal Preview 4' },
]

const activeSlide = ref(0)
const showGuide = ref(false)
const showDisclaimer = ref(false)
let timer

function nextSlide() {
  activeSlide.value = (activeSlide.value + 1) % slides.length
}

function prevSlide() {
  activeSlide.value = (activeSlide.value - 1 + slides.length) % slides.length
}

onMounted(() => {
  timer = window.setInterval(nextSlide, 4000)
})

onUnmounted(() => {
  window.clearInterval(timer)
})
</script>

<template>
  <div class="flex flex-1 flex-col">
    <main class="mx-auto w-full max-w-6xl flex-grow px-4 py-16 md:py-24">
      <div class="grid items-center gap-12 lg:grid-cols-2">
        <section class="text-center lg:pr-8 lg:text-left">
          <div class="mb-6">
            <span
              class="mb-3 inline-flex items-center rounded-full border border-black/5 bg-school-primary/10 px-3 py-2 text-sm font-semibold text-school-primary dark:border-white/10 dark:text-blue-300"
            >
              Official Website
            </span>
            <h1 class="mb-3 text-4xl font-extrabold leading-tight tracking-tight md:text-5xl">
              Welcome to LASER-web
            </h1>
            <p class="mb-6 text-lg leading-relaxed text-slate-600 dark:text-slate-300">
              Your centralized digital portal for Las Piñas East National High School. Access learning
              resources, view grades, and connect with departments seamlessly.
            </p>
          </div>

          <div class="flex flex-col justify-center gap-3 sm:flex-row lg:justify-start">
            <button
              type="button"
              class="rounded-full bg-school-primary px-8 py-3 text-lg font-semibold text-white shadow transition hover:-translate-y-0.5 hover:bg-school-primary-light"
              @click="showGuide = true"
            >
              Get Started Guide
            </button>
            <a
              href="LPENHS.html"
              class="rounded-full border-0 bg-white px-8 py-3 text-lg font-semibold text-slate-800 shadow-sm transition hover:-translate-y-0.5 hover:text-school-primary dark:bg-slate-800 dark:text-slate-100"
            >
              Learn More
            </a>
          </div>
        </section>

        <section>
          <div class="relative rounded-lg border-4 border-white bg-white p-2.5 shadow-[0_10px_30px_rgba(0,0,0,0.1)] dark:border-slate-800 dark:bg-slate-800">
            <div class="relative overflow-hidden rounded">
              <img
                v-for="(slide, index) in slides"
                v-show="index === activeSlide"
                :key="slide.src"
                :src="slide.src"
                :alt="slide.alt"
                class="block h-[280px] w-full object-cover sm:h-[450px]"
              />
              <div class="absolute bottom-3 left-0 right-0 flex justify-center gap-2">
                <button
                  v-for="(_, index) in slides"
                  :key="index"
                  type="button"
                  class="h-2.5 w-2.5 rounded-full"
                  :class="index === activeSlide ? 'bg-white' : 'bg-white/50'"
                  :aria-current="index === activeSlide ? 'true' : undefined"
                  @click="activeSlide = index"
                />
              </div>
              <button
                type="button"
                class="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-black/30 p-2 text-white"
                aria-label="Previous"
                @click="prevSlide"
              >
                ‹
              </button>
              <button
                type="button"
                class="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-black/30 p-2 text-white"
                aria-label="Next"
                @click="nextSlide"
              >
                ›
              </button>
            </div>
          </div>
        </section>
      </div>
    </main>

    <div
      v-if="showGuide"
      class="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-4"
      id="exampleModalToggle"
      tabindex="-1"
    >
      <div class="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl bg-white shadow-2xl dark:bg-slate-800">
        <div
          class="flex items-center justify-between border-0 px-6 py-4 text-white"
          style="background: linear-gradient(135deg, #000080 0%, #0000a0 100%)"
        >
          <h1 class="text-lg font-bold" id="exampleModalToggleLabel">LASER-web Navigation Guide</h1>
          <button type="button" class="text-2xl leading-none text-white" aria-label="Close" @click="showGuide = false">
            ×
          </button>
        </div>
        <div class="p-6 md:p-10">
          <p class="mb-10 text-center text-lg text-slate-500 dark:text-slate-300">
            Follow this guide to easily navigate our digital features:
          </p>
          <div class="grid gap-4 md:grid-cols-2">
            <div class="h-full rounded-2xl border border-black/5 bg-canvas p-4 dark:border-white/10 dark:bg-slate-900">
              <h5 class="mb-3 flex items-center text-base font-bold text-school-primary dark:text-blue-300">Login</h5>
              <p class="mb-0 text-sm text-slate-600 dark:text-slate-300">
                Click <b>"Login"</b> on the top right. Choose Teacher or Student and continue with
                Google, or use Admin / student test login as needed.
              </p>
            </div>
            <div class="h-full rounded-2xl border border-black/5 bg-canvas p-4 dark:border-white/10 dark:bg-slate-900">
              <h5 class="mb-3 flex items-center text-base font-bold text-school-primary dark:text-blue-300">Resources</h5>
              <p class="mb-0 text-sm text-slate-600 dark:text-slate-300">
                <b>M.A.P Portal:</b> Access the grade portal.<br /><b>D.R.I.V.E:</b> Access files for
                circulation and submissions.
              </p>
            </div>
            <div class="h-full rounded-2xl border border-black/5 bg-canvas p-4 dark:border-white/10 dark:bg-slate-900">
              <h5 class="mb-3 flex items-center text-base font-bold text-school-primary dark:text-blue-300">
                Offices & Depts
              </h5>
              <p class="mb-0 text-sm text-slate-600 dark:text-slate-300">
                Explore subject areas, curriculum, faculty info, and vital administrative offices.
              </p>
            </div>
            <div class="h-full rounded-2xl border border-black/5 bg-canvas p-4 dark:border-white/10 dark:bg-slate-900">
              <h5 class="mb-3 flex items-center text-base font-bold text-school-primary dark:text-blue-300">
                Help & Support
              </h5>
              <p class="mb-0 text-sm text-slate-600 dark:text-slate-300">
                Check our FAQs, locate contact numbers, or submit an inquiry directly to our support team.
              </p>
            </div>
          </div>
        </div>
        <div class="flex justify-between px-6 pb-6 pt-0 md:px-10">
          <button
            type="button"
            class="rounded-full border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 dark:border-slate-600 dark:text-slate-200"
            @click="showGuide = false; showDisclaimer = true"
          >
            Read Disclaimer
          </button>
          <button
            type="button"
            class="rounded-full bg-school-primary px-8 py-2 text-sm font-semibold text-white"
            @click="showGuide = false"
          >
            Got it!
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="showDisclaimer"
      class="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-4"
      id="exampleModalToggle2"
      tabindex="-1"
    >
      <div class="w-full max-w-lg overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-slate-800">
        <div class="flex items-center justify-between bg-slate-900 px-6 py-4 text-white">
          <h1 class="text-lg font-bold" id="exampleModalToggleLabel2">Disclaimer</h1>
          <button type="button" class="text-2xl leading-none text-white" aria-label="Close" @click="showDisclaimer = false">
            ×
          </button>
        </div>
        <div class="p-6 text-sm leading-relaxed text-slate-600 md:p-10 dark:text-slate-300">
          <p>
            The information provided on the LASER-web school website is for general informational purposes
            only. While we strive to keep the content up to date and accurate, we make no representations
            or warranties of any kind...
          </p>
          <p>
            In no event will the school be liable for any loss or damage arising out of, or in connection
            with, the use of this website.
          </p>
          <p class="mb-0">
            Through this website, you may be able to link to other websites which are not under the
            control of the school. The inclusion of any links does not necessarily imply a recommendation.
          </p>
        </div>
        <div class="px-6 pb-6">
          <button
            type="button"
            class="rounded-full bg-slate-600 px-4 py-2 text-sm font-semibold text-white"
            @click="showDisclaimer = false; showGuide = true"
          >
            Back to Guidelines
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
