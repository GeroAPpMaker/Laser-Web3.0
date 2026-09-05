<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

// Centralized data for different offices, now including an image placeholder property
const officesData = {
  'principals-office': {
    title: "Principal's Office",
    subtitle: "Leadership and Administrative Excellence",
    description: "The Principal's Office oversees all academic programs, faculty development, and administrative operations at LPENHS. We are committed to fostering a safe, inclusive, and high-achieving environment for all students and staff.",
    services: [
      "School Policy Implementation",
      "Faculty and Staff Supervision",
      "Community and Stakeholder Relations",
      "Academic Excellence Programs"
    ],
    email: "principal@lpenhs.edu.ph",
    icon: "fas fa-user-tie",
    image: "https://placehold.co/1200x600/e2e8f0/475569?text=Principal's+Office+Image"
  },
  'guidance-office': {
    title: "Guidance Office",
    subtitle: "Student Counseling and Career Support",
    description: "The Guidance Office provides comprehensive psychological, academic, and career counseling services. We are here to support student well-being and help shape their future educational and career paths.",
    services: [
      "Individual and Group Counseling",
      "Career Guidance and Testing",
      "Student Behavior Interventions",
      "Peer Facilitating Programs"
    ],
    email: "guidance@lpenhs.edu.ph",
    icon: "fas fa-hands-helping",
    image: "https://placehold.co/1200x600/e2e8f0/475569?text=Guidance+Office+Image"
  },
  'clinic': {
    title: "School Clinic",
    subtitle: "Health and Wellness Services",
    description: "The School Clinic ensures the health and safety of the student body and faculty. We provide first aid, regular health assessments, and promote wellness campaigns across the campus.",
    services: [
      "First Aid and Emergency Care",
      "Annual Health and Dental Screenings",
      "Health Education and Nutrition Campaigns",
      "Medical Record Maintenance"
    ],
    email: "clinic@lpenhs.edu.ph",
    icon: "fas fa-notes-medical",
    image: "https://placehold.co/1200x600/e2e8f0/475569?text=School+Clinic+Image"
  },
  'records': {
    title: "Records Office",
    subtitle: "Registrar and Academic Documents",
    description: "The Records Office manages the enrollment process, student academic histories, and the issuance of official school documents safely and confidentially.",
    services: [
      "Enrollment and Registration",
      "Issuance of Form 137 / SF10",
      "Certificates of Good Moral Character",
      "Transcript of Records"
    ],
    email: "records@lpenhs.edu.ph",
    icon: "fas fa-folder-open",
    image: "https://placehold.co/1200x600/e2e8f0/475569?text=Records+Office+Image"
  },
  'sbm': {
    title: "School-Based Management (SBM)",
    subtitle: "Continuous School Improvement",
    description: "The SBM Office focuses on decentralizing decision-making, encouraging stakeholders—teachers, parents, and the community—to actively participate in the school's continuous improvement plans.",
    services: [
      "School Improvement Plan (SIP) Monitoring",
      "Stakeholder Collaboration",
      "Resource Management",
      "Performance Assessment and Evaluation"
    ],
    email: "sbm@lpenhs.edu.ph",
    icon: "fas fa-chart-line",
    image: "https://placehold.co/1200x600/e2e8f0/475569?text=SBM+Office+Image"
  }
}

// Compute the current office based on the route parameter
const currentOffice = computed(() => {
  const name = route.params.name
  return officesData[name] || {
    title: "Office Not Found",
    subtitle: "The requested office does not exist.",
    description: "Please navigate back to the main menu and select a valid office.",
    services: [],
    email: "",
    icon: "fas fa-exclamation-triangle",
    image: null
  }
})
</script>

<template>
  <div class="office-page min-h-screen bg-gray-50/50">
    <!-- Page Banner -->
    <div class="py-16 mb-12 text-center text-white shadow-sm bg-[var(--school-primary,#0d6efd)]">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col items-center">
        <i :class="[currentOffice.icon, 'text-5xl mb-4 opacity-90']"></i>
        <h1 class="text-4xl sm:text-5xl font-bold mb-3">{{ currentOffice.title }}</h1>
        <p class="text-lg sm:text-xl text-white/80 max-w-2xl mx-auto">
          {{ currentOffice.subtitle }}
        </p>
      </div>
    </div>

    <!-- Main Content -->
    <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 mb-16 pb-8">
      
      <div v-if="currentOffice.title !== 'Office Not Found'" class="bg-white rounded-3xl shadow-xl p-8 sm:p-12 border border-gray-100">
        
        <!-- Featured Image Placeholder -->
        <div v-if="currentOffice.image" class="mb-10 w-full h-64 sm:h-80 md:h-96 rounded-2xl overflow-hidden bg-gray-200 border border-gray-100 shadow-sm">
          <img 
            :src="currentOffice.image" 
            :alt="currentOffice.title + ' facility'" 
            class="w-full h-full object-cover"
          />
        </div>

        <!-- Description Section -->
        <div class="mb-10">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">About the Office</h2>
          <p class="text-gray-600 leading-relaxed text-lg">
            {{ currentOffice.description }}
          </p>
        </div>

        <!-- Services List -->
        <div class="mb-10" v-if="currentOffice.services.length">
          <h2 class="text-2xl font-bold text-gray-900 mb-5">Key Responsibilities & Services</h2>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div 
              v-for="(service, index) in currentOffice.services" 
              :key="index"
              class="flex items-start gap-3 p-4 rounded-xl bg-gray-50 border border-gray-100"
            >
              <i class="fas fa-check-circle text-[var(--school-primary,#0d6efd)] mt-1 text-lg"></i>
              <span class="text-gray-700 font-medium">{{ service }}</span>
            </div>
          </div>
        </div>

        <!-- Contact Banner -->
        <div class="mt-8 bg-blue-50 rounded-2xl p-6 sm:p-8 flex flex-col sm:flex-row items-center justify-between border border-blue-100 gap-4 text-center sm:text-left">
          <div>
            <h3 class="text-xl font-bold text-blue-900 mb-1">Need Assistance?</h3>
            <p class="text-blue-700">Reach out directly to this office via email.</p>
          </div>
          <a 
            :href="'mailto:' + currentOffice.email" 
            class="inline-flex items-center gap-2 px-6 py-3 bg-[var(--school-primary,#0d6efd)] text-white font-semibold rounded-xl hover:bg-blue-700 transition-colors shadow-md shrink-0"
          >
            <i class="fas fa-envelope"></i>
            {{ currentOffice.email }}
          </a>
        </div>
      </div>

      <!-- 404 State -->
      <div v-else class="text-center py-20">
        <RouterLink 
          to="/" 
          class="inline-flex items-center gap-2 px-6 py-3 bg-[var(--school-primary,#0d6efd)] text-white font-semibold rounded-xl hover:opacity-90 transition-opacity"
        >
          <i class="fas fa-home"></i> Return to Homepage
        </RouterLink>
      </div>

    </main>
  </div>
</template>