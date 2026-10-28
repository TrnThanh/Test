<script setup lang="ts">
import BaseModal from './BaseModal.vue';
import { AlertTriangle } from 'lucide-vue-next';

withDefaults(
  defineProps<{
    modelValue: boolean;
    title?: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    danger?: boolean;
    loading?: boolean;
  }>(),
  {
    title: 'Xác nhận thao tác',
    confirmText: 'Xác nhận',
    cancelText: 'Hủy',
    danger: true,
    loading: false,
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
  (e: 'confirm'): void;
  (e: 'cancel'): void;
}>();

function onCancel() {
  emit('update:modelValue', false);
  emit('cancel');
}

function onConfirm() {
  emit('confirm');
}
</script>

<template>
  <BaseModal
    :model-value="modelValue"
    :title="title"
    max-width="440px"
    :prevent-close="loading"
    :close-on-backdrop="!loading"
    @update:model-value="emit('update:modelValue', $event)"
    @close="onCancel"
  >
    <div class="confirm-body">
      <div v-if="danger" class="confirm-icon-danger">
        <AlertTriangle class="icon-svg" />
      </div>
      <p class="confirm-message">{{ message }}</p>
    </div>

    <template #footer>
      <button
        type="button"
        class="btn btn-secondary"
        :disabled="loading"
        @click="onCancel"
      >
        {{ cancelText }}
      </button>
      <button
        type="button"
        class="btn"
        :class="danger ? 'btn-danger' : 'btn-primary'"
        :disabled="loading"
        @click="onConfirm"
      >
        <span v-if="loading">Đang xử lý...</span>
        <span v-else>{{ confirmText }}</span>
      </button>
    </template>
  </BaseModal>
</template>

<style scoped>
.confirm-body {
  display: flex;
  gap: 14px;
  align-items: flex-start;
  padding: 4px 0;
}

.confirm-icon-danger {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: var(--bad-s);
  color: var(--bad);
  display: grid;
  place-items: center;
  flex: none;
}

.icon-svg {
  width: 20px;
  height: 20px;
}

.confirm-message {
  margin: 0;
  color: var(--ink);
  font-size: 14px;
  line-height: 1.5;
}
</style>
