<script setup lang="ts">
import { useToast } from '../../composables/useToast';

const { toastMessage, toastVisible } = useToast();
</script>

<template>
  <div id="toast" :class="{ on: toastVisible }" role="status" aria-live="polite">
    {{ toastMessage }}
  </div>
</template>

<style scoped>
#toast {
  position: fixed;
  bottom: 24px;
  right: 24px;
  background: var(--ink);
  color: var(--card);
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  opacity: 0;
  transform: translateY(12px);
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  pointer-events: none;
  z-index: 9999;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
}

#toast.on {
  opacity: 1;
  transform: translateY(0);
}
</style>
