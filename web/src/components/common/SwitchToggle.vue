<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    modelValue: boolean;
    disabled?: boolean;
    loading?: boolean;
    ariaLabel?: string;
  }>(),
  {
    disabled: false,
    loading: false,
    ariaLabel: 'Chuyển đổi trạng thái',
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'change', value: boolean): void;
}>();

function toggle() {
  if (props.disabled || props.loading) return;
  const next = !props.modelValue;
  emit('update:modelValue', next);
  emit('change', next);
}
</script>

<template>
  <button
    type="button"
    class="sw"
    :class="{ on: modelValue, loading: loading }"
    role="switch"
    :aria-checked="modelValue"
    :aria-label="ariaLabel"
    :disabled="disabled || loading"
    @click="toggle"
  >
    <span v-if="loading" class="sw-spinner"></span>
  </button>
</template>

<style scoped>
.sw {
  width: 38px;
  height: 22px;
  border-radius: 99px;
  border: 0;
  background: var(--line);
  position: relative;
  flex: none;
  cursor: pointer;
  transition: background 0.15s ease, opacity 0.15s ease;
  padding: 0;
  display: inline-block;
}

.sw:focus-visible {
  outline: 2px solid var(--pri);
  outline-offset: 2px;
}

.sw:after {
  content: "";
  position: absolute;
  top: 3px;
  left: 3px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #ffffff;
  transition: transform 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
}

.sw.on {
  background: var(--pri);
}

.sw.on:after {
  transform: translateX(16px);
}

.sw:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

/* Spinner inside switch when loading */
.sw-spinner {
  position: absolute;
  top: 5px;
  left: 5px;
  width: 12px;
  height: 12px;
  border: 2px solid transparent;
  border-top-color: var(--pri);
  border-radius: 50%;
  animation: sw-spin 0.6s linear infinite;
  z-index: 1;
}

.sw.on .sw-spinner {
  left: 21px;
  border-top-color: #ffffff;
}

@keyframes sw-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
