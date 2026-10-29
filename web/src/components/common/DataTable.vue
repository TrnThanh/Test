<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(
  defineProps<{
    totalItems: number;
    currentPage: number;
    pageSize?: number;
    itemName?: string;
    loading?: boolean;
    error?: string | null;
    empty?: boolean;
    emptyMessage?: string;
    emptyAction?: string;
  }>(),
  {
    pageSize: 10,
    itemName: 'mục',
    loading: false,
    error: null,
    empty: false,
    emptyMessage: 'Không có dữ liệu phù hợp.',
    emptyAction: '',
  }
);

const emit = defineEmits<{
  (e: 'update:currentPage', page: number): void;
  (e: 'emptyActionClick'): void;
  (e: 'retry'): void;
}>();

const totalPages = computed(() =>
  Math.max(1, Math.ceil(props.totalItems / props.pageSize))
);

const visiblePages = computed<(number | string)[]>(() => {
  const total = totalPages.value;
  const current = props.currentPage;
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }
  if (current <= 4) {
    return [1, 2, 3, 4, 5, '...', total];
  }
  if (current >= total - 3) {
    return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
  }
  return [1, '...', current - 1, current, current + 1, '...', total];
});

const fromItem = computed(() =>
  props.totalItems === 0 ? 0 : (props.currentPage - 1) * props.pageSize + 1
);

const toItem = computed(() =>
  Math.min(props.currentPage * props.pageSize, props.totalItems)
);

function setPage(page: number) {
  if (page >= 1 && page <= totalPages.value) {
    emit('update:currentPage', page);
  }
}
</script>

<template>
  <div class="card data-table-container">
    <!-- Toolbar slot -->
    <div v-if="$slots.toolbar" class="tbar">
      <slot name="toolbar" />
    </div>

    <!-- Error State -->
    <div v-if="error" class="error-state">
      <p class="error-msg">{{ error }}</p>
      <button
        type="button"
        class="btn btn-secondary btn-sm retry-btn"
        @click="emit('retry')"
      >
        Thử lại
      </button>
    </div>

    <!-- Loading State -->
    <div v-else-if="loading" class="loading-state">
      <div class="spinner-small"></div>
      <span>Đang tải dữ liệu...</span>
    </div>

    <!-- Empty State -->
    <div v-else-if="empty" class="empty-state">
      <p class="empty-msg">{{ emptyMessage }}</p>
      <button
        v-if="emptyAction"
        type="button"
        class="btn btn-secondary btn-sm empty-btn"
        @click="emit('emptyActionClick')"
      >
        {{ emptyAction }}
      </button>
    </div>

    <!-- Table content wrapper -->
    <div v-else class="wrap">
      <table>
        <slot />
      </table>
    </div>

    <!-- Pagination bar -->
    <div v-if="!empty && !loading && !error" class="pg">
      <span class="pg-info">
        {{ fromItem }}–{{ toItem }} trên {{ totalItems }} {{ itemName }}
      </span>
      <div v-if="totalPages > 1" class="pg-controls">
        <button
          type="button"
          :disabled="currentPage <= 1"
          aria-label="Trang trước"
          @click="setPage(currentPage - 1)"
        >
          ‹
        </button>
        <template v-for="(p, idx) in visiblePages" :key="idx">
          <span v-if="p === '...'" class="pg-ellipsis">…</span>
          <button
            v-else
            type="button"
            :class="{ on: p === currentPage }"
            :aria-label="`Trang ${p}`"
            :aria-current="p === currentPage ? 'page' : undefined"
            @click="setPage(p as number)"
          >
            {{ p }}
          </button>
        </template>
        <button
          type="button"
          :disabled="currentPage >= totalPages"
          aria-label="Trang tiếp theo"
          @click="setPage(currentPage + 1)"
        >
          ›
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.data-table-container {
  overflow: hidden;
}

.empty-state,
.error-state {
  padding: 40px 20px;
  text-align: center;
  color: var(--mut);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.error-msg {
  margin: 0;
  font-size: 13.5px;
  color: var(--bad);
}

.empty-msg {
  margin: 0;
  font-size: 13.5px;
}

.empty-btn,
.retry-btn {
  margin-top: 4px;
}

.loading-state {
  padding: 40px 20px;
  text-align: center;
  color: var(--mut);
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 10px;
  font-size: 13.5px;
}

.spinner-small {
  width: 18px;
  height: 18px;
  border: 2px solid var(--line);
  border-top-color: var(--pri);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.pg-info {
  font-variant-numeric: tabular-nums;
}

.pg-controls {
  display: flex;
  gap: 4px;
  align-items: center;
}

.pg-ellipsis {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
  color: var(--mut);
  user-select: none;
  font-size: 13px;
}
</style>
