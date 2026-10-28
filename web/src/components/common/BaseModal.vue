<script setup lang="ts">
import { onMounted, onUnmounted, watch } from 'vue';
import { X } from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    modelValue: boolean;
    title?: string;
    subtitle?: string;
    maxWidth?: string;
    closeOnBackdrop?: boolean;
    preventClose?: boolean;
  }>(),
  {
    title: '',
    subtitle: '',
    maxWidth: '520px',
    closeOnBackdrop: true,
    preventClose: false,
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
  (e: 'close'): void;
}>();

function close() {
  if (props.preventClose) return;
  emit('update:modelValue', false);
  emit('close');
}

function handleBackdropClick() {
  if (props.preventClose) return;
  if (props.closeOnBackdrop) {
    close();
  }
}

function handleKeyDown(e: KeyboardEvent) {
  if (props.preventClose) return;
  if (e.key === 'Escape' && props.modelValue) {
    close();
  }
}

watch(
  () => props.modelValue,
  (val) => {
    if (val) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
  }
);

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
  document.body.style.overflow = '';
});
</script>

<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="modelValue"
        class="modal-backdrop"
        role="dialog"
        aria-modal="true"
        @click.self="handleBackdropClick"
      >
        <div class="modal-sheet" :style="{ maxWidth: maxWidth }">
          <div class="modal-sheet-header">
            <div class="header-titles">
              <slot name="title">
                <h3 class="modal-title">{{ title }}</h3>
                <p v-if="subtitle" class="modal-subtitle">{{ subtitle }}</p>
              </slot>
            </div>
            <button
              type="button"
              class="modal-close-btn"
              :disabled="preventClose"
              aria-label="Đóng cửa sổ"
              @click="close"
            >
              <X class="modal-close-icon" />
            </button>
          </div>

          <div class="modal-sheet-body">
            <slot />
          </div>

          <div v-if="$slots.footer" class="modal-sheet-footer">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(14, 21, 20, 0.45);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 16px;
}

.modal-sheet {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 14px;
  width: 100%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 16px 36px rgba(20, 32, 30, 0.16);
  overflow: hidden;
}

.modal-sheet-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  padding: 16px 20px;
  border-bottom: 1px solid var(--line);
  background: var(--card);
  flex: none;
}

.header-titles {
  min-width: 0;
}

.modal-title {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: var(--ink);
  line-height: 1.3;
}

.modal-subtitle {
  margin: 3px 0 0;
  font-size: 12.5px;
  color: var(--mut);
}

.modal-close-btn {
  background: none;
  border: 1px solid transparent;
  color: var(--mut);
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: grid;
  place-items: center;
  flex: none;
  padding: 0;
  transition: all 0.15s ease;
}

.modal-close-btn:hover:not(:disabled) {
  background: var(--bg);
  border-color: var(--line);
  color: var(--ink);
}

.modal-close-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.modal-close-icon {
  width: 18px;
  height: 18px;
}

.modal-sheet-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
  min-height: 0;
}

.modal-sheet-footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid var(--line);
  background: var(--bg);
  flex: none;
}

/* Transitions */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.modal-fade-enter-active .modal-sheet,
.modal-fade-leave-active .modal-sheet {
  transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-fade-enter-from .modal-sheet,
.modal-fade-leave-to .modal-sheet {
  transform: scale(0.97) translateY(8px);
}
</style>
