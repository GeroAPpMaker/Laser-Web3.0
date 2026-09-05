<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  wide: {
    type: Boolean,
    default: false,
  },
})
</script>

<template>
  <header class="border-b border-slate-200 bg-white">
    <div class="mx-auto px-4 py-6" :class="wide ? 'max-w-6xl' : 'max-w-3xl'">
      <h1 class="text-2xl font-semibold tracking-tight">{{ title }}</h1>
      <slot />
    </div>
  </header>
</template>
