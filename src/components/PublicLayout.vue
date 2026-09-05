<script setup>
import Footer from './Footer.vue'
import Navbar from './Navbar.vue'
</script>

<template>
  <div class="flex min-h-svh flex-col bg-canvas font-sans text-slate-800 dark:bg-slate-950 dark:text-slate-100">
    <Navbar />
    <div class="flex flex-1 flex-col">
      <slot />
    </div>
    <Footer />
  </div>
</template>
