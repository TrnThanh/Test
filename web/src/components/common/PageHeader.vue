<script setup lang="ts">
defineProps<{
  title: string;
  subtitle?: string;
}>();
</script>

<template>
  <div class="hd">
    <div>
      <h1>{{ title }}</h1>
      <p v-if="subtitle">{{ subtitle }}</p>
    </div>
    <div v-if="$slots.actions" class="hd-actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<style scoped>
.hd {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

h1 {
  font-size: 22px;
  margin: 0;
  font-weight: 700;
  color: var(--ink);
  line-height: 1.3;
}

p {
  margin: 3px 0 0;
  color: var(--mut);
  font-size: 13.5px;
}

.hd-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  align-items: center;
}
</style>
