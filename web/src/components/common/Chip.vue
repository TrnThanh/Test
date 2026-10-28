<script setup lang="ts">
withDefaults(
  defineProps<{
    variant?: 'default' | 'ok' | 'warn' | 'bad';
  }>(),
  {
    variant: 'default',
  }
);
</script>

<template>
  <span
    class="chip"
    :class="{
      g: variant === 'ok',
      w: variant === 'warn',
      b: variant === 'bad',
    }"
  >
    <slot />
  </span>
</template>

<style scoped>
.chip {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  background: var(--bg);
  color: var(--mut);
  border: 1px solid var(--line);
  line-height: 1.4;
}

.chip.g {
  background: var(--ok-s);
  color: var(--ok);
  border-color: transparent;
}

.chip.w {
  background: var(--warn-s);
  color: var(--warn);
  border-color: transparent;
}

.chip.b {
  background: var(--bad-s);
  color: var(--bad);
  border-color: transparent;
}
</style>
