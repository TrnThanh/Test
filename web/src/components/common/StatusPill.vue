<script setup lang="ts">
withDefaults(
  defineProps<{
    active?: boolean;
    variant?: 'ok' | 'off' | 'bad' | 'warn';
  }>(),
  {
    active: true,
    variant: undefined,
  }
);
</script>

<template>
  <span
    class="pill"
    :class="{
      off: variant ? variant === 'off' : !active,
      bad: variant === 'bad',
      warn: variant === 'warn',
    }"
  >
    <slot>{{ active ? 'Đang mở' : 'Tạm tắt' }}</slot>
  </span>
</template>

<style scoped>
.pill {
  display: inline-flex;
  align-items: center;
  padding: 3px 9px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 600;
  background: var(--ok-s);
  color: var(--ok);
  line-height: 1.3;
}

.pill.off {
  background: var(--off-s);
  color: var(--off);
}

.pill.bad {
  background: var(--bad-s);
  color: var(--bad);
}

.pill.warn {
  background: var(--warn-s);
  color: var(--warn);
}
</style>
