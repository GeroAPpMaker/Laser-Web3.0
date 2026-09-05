<script setup>
// Form logic or reactive state can be placed here if needed
</script>

<template>
  <div class="contact-page min-h-screen bg-gray-50/50">
    <!-- Page Banner -->
    <div class="py-12 mb-12 text-center text-white shadow-sm bg-[var(--school-primary,#0d6efd)]">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 class="text-4xl sm:text-5xl font-bold mb-2">Get in Touch</h1>
        <p class="text-lg sm:text-xl text-white/80 max-w-2xl mx-auto">
          We are here to help. Reach out to LPENHS today.
        </p>
      </div>
    </div>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-16 pb-8">
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
        
        <!-- Left Column: Contact Information -->
        <div class="lg:col-span-5">
          <!-- Image Card -->
          <div class="mb-6 rounded-2xl overflow-hidden shadow-sm border border-gray-200">
            <img 
              src="/images/easteambay.PNG" 
              alt="EasTEAMbay" 
              class="w-full h-auto object-cover"
            >
          </div>

          <div class="lg:pr-4 mt-6">
            <h3 class="text-2xl sm:text-3xl font-bold mb-4 text-[var(--text-dark,#212529)]">
              Contact Information
            </h3>
            <p class="text-gray-600 mb-8 leading-relaxed">
              Whether you have a question about enrollment, academic programs, or campus events, our team is ready to answer all your questions.
            </p>
            
            <!-- Location Item -->
            <div class="flex items-start gap-4 mb-6">
              <div class="w-12 h-12 shrink-0 rounded-full shadow-sm flex items-center justify-center text-white bg-[var(--school-primary,#0d6efd)]">
                <i class="fas fa-map-marker-alt text-lg"></i>
              </div>
              <div>
                <h5 class="text-lg font-bold text-gray-900 mb-1">Our Location</h5>
                <p class="text-gray-600 leading-relaxed">
                  Kasoy St., Verdant Acres Subd.,<br>Pamplona III, Las Piñas City
                </p>
              </div>
            </div>

            <!-- Phone Item -->
            <div class="flex items-start gap-4 mb-6">
              <div class="w-12 h-12 shrink-0 rounded-full shadow-sm flex items-center justify-center text-white bg-[var(--school-primary,#0d6efd)]">
                <i class="fas fa-phone-alt text-lg"></i>
              </div>
              <div>
                <h5 class="text-lg font-bold text-gray-900 mb-1">Call Us</h5>
                <p class="mb-0">
                  <a href="tel:(02)8-873-3117" class="text-gray-600 hover:text-blue-600 transition-colors">
                    (02) 8-873-3117
                  </a>
                </p>
              </div>
            </div>

            <!-- Email Item -->
            <div class="flex items-start gap-4 mb-8">
              <div class="w-12 h-12 shrink-0 rounded-full shadow-sm flex items-center justify-center text-white bg-[var(--school-primary,#0d6efd)]">
                <i class="fas fa-envelope text-lg"></i>
              </div>
              <div>
                <h5 class="text-lg font-bold text-gray-900 mb-1">Email Us</h5>
                <p class="mb-0">
                  <a href="mailto:305434@depedlaspinas.ph" class="text-gray-600 hover:text-blue-600 transition-colors break-all">
                    305434@depedlaspinas.ph
                  </a>
                </p>
              </div>
            </div>

            <!-- Social Media Buttons -->
            <h5 class="text-lg font-bold text-gray-900 mb-3">Follow Us</h5>
            <div class="flex flex-wrap gap-3">
              <a 
                href="https://www.facebook.com/profile.php?id=100084733710812" 
                target="_blank" 
                class="inline-flex items-center gap-2 px-4 py-2 border border-blue-600 text-blue-600 rounded-full font-medium text-sm hover:bg-blue-600 hover:text-white transition-all shadow-sm"
              >
                <i class="fab fa-facebook text-base"></i> Facebook
              </a>
              <a 
                href="https://www.instagram.com/lpenhs305434/" 
                target="_blank" 
                class="inline-flex items-center gap-2 px-4 py-2 border border-pink-600 text-pink-600 rounded-full font-medium text-sm hover:bg-pink-600 hover:text-white transition-all shadow-sm"
              >
                <i class="fab fa-instagram text-base"></i> Instagram
              </a>
              <a 
                href="https://www.youtube.com/channel/UCnb9HCbZt0ViL-a7O4MeIpg" 
                target="_blank" 
                class="inline-flex items-center gap-2 px-4 py-2 border border-red-600 text-red-600 rounded-full font-medium text-sm hover:bg-red-600 hover:text-white transition-all shadow-sm"
              >
                <i class="fab fa-youtube text-base"></i> YouTube
              </a>
            </div>
          </div>
        </div>

        <!-- Right Column: Contact Form -->
        <div class="lg:col-span-7">
          <div class="bg-[var(--bg-card,#ffffff)] shadow-xl rounded-3xl p-6 sm:p-10 border border-gray-100">
            <h3 class="text-2xl sm:text-3xl font-bold mb-6 text-[var(--text-dark,#212529)]">
              Send Us a Message
            </h3>
            
            <form action="https://formsubmit.co/gerald.valencia@deped.gov.ph" method="POST">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                
                <!-- First Name -->
                <div class="col-span-1">
                  <label for="firstName" class="block text-sm font-semibold text-gray-600 mb-1.5">First Name</label>
                  <input 
                    type="text" 
                    name="First Name" 
                    id="firstName" 
                    placeholder="John" 
                    required
                    class="w-full px-4 py-2.5 rounded-xl border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-gray-800 placeholder-gray-400"
                  >
                </div>

                <!-- Last Name -->
                <div class="col-span-1">
                  <label for="lastName" class="block text-sm font-semibold text-gray-600 mb-1.5">Last Name</label>
                  <input 
                    type="text" 
                    name="Last Name" 
                    id="lastName" 
                    placeholder="Doe" 
                    required
                    class="w-full px-4 py-2.5 rounded-xl border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-gray-800 placeholder-gray-400"
                  >
                </div>

                <!-- Email -->
                <div class="sm:col-span-2">
                  <label for="email" class="block text-sm font-semibold text-gray-600 mb-1.5">Email Address</label>
                  <input 
                    type="email" 
                    name="Email" 
                    id="email" 
                    placeholder="name@example.com" 
                    required
                    class="w-full px-4 py-2.5 rounded-xl border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-gray-800 placeholder-gray-400"
                  >
                </div>

                <!-- Subject -->
                <div class="sm:col-span-2">
                  <label for="subject" class="block text-sm font-semibold text-gray-600 mb-1.5">Subject</label>
                  <input 
                    type="text" 
                    name="Subject" 
                    id="subject" 
                    placeholder="How can we help?" 
                    required
                    class="w-full px-4 py-2.5 rounded-xl border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-gray-800 placeholder-gray-400"
                  >
                </div>

                <!-- Message -->
                <div class="sm:col-span-2">
                  <label for="message" class="block text-sm font-semibold text-gray-600 mb-1.5">Message</label>
                  <textarea 
                    name="Message" 
                    id="message" 
                    rows="5" 
                    placeholder="Write your message here..." 
                    required
                    class="w-full px-4 py-2.5 rounded-xl border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all text-gray-800 placeholder-gray-400 resize-y"
                  ></textarea>
                </div>

                <!-- Submit Button & Auxiliary Text -->
                <div class="sm:col-span-2 mt-2">
                  <button 
                    type="submit" 
                    class="w-full py-3.5 px-6 rounded-xl font-bold text-white shadow-md bg-[var(--school-primary,#0d6efd)] hover:opacity-95 hover:shadow-lg transition-all flex items-center justify-center gap-2 cursor-pointer"
                  >
                    <i class="fas fa-paper-plane"></i> Send Message
                  </button>

                  <div class="text-center mt-4">
                    <span class="text-xs sm:text-sm text-gray-500">
                      Alternatively, you can fill out our 
                      <a 
                        href="https://forms.office.com/Pages/ResponsePage.aspx?id=gKvjQCQgo0W_dnoHYaJNKXnMyzDDnJlNgwZDPrj4MWBUQU0zWEVFWUhPWU45UjA2VFNEMUlJVlhSTy4u" 
                        target="_blank" 
                        class="font-bold text-blue-600 hover:underline"
                      >
                        Official Feedback Form
                      </a>.
                    </span>
                  </div>
                </div>

              </div>
            </form>
          </div>
        </div>

      </div>
    </main>
  </div>
</template>