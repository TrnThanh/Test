<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { Restaurant } from '../types';
import { api } from '../services/api';
import RestaurantCard from './RestaurantCard.vue';

const restaurants = ref<Restaurant[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const searchQuery = ref('');
const selectedRestaurant = ref<Restaurant | null>(null);

async function loadRestaurants() {
  loading.value = true;
  error.value = null;
  try {
    restaurants.value = await api.getRestaurants();
  } catch (err: any) {
    error.value = err.message || 'Không thể tải danh sách quán ăn';
  } finally {
    loading.value = false;
  }
}

const filteredRestaurants = computed(() => {
  if (!searchQuery.value.trim()) return restaurants.value;
  const q = searchQuery.value.toLowerCase().trim();
  return restaurants.value.filter(
    (r) =>
      r.name.toLowerCase().includes(q) ||
      (r.address && r.address.toLowerCase().includes(q)) ||
      (r.description && r.description.toLowerCase().includes(q))
  );
});

function openDetail(restaurant: Restaurant) {
  selectedRestaurant.value = restaurant;
}

function closeDetail() {
  selectedRestaurant.value = null;
}

onMounted(() => {
  loadRestaurants();
});
</script>

<template>
  <div class="explore-section">
    <div class="section-header">
      <div>
        <h2>Khám phá Quán ăn</h2>
        <p>Thưởng thức các địa điểm ẩm thực hấp dẫn được cập nhật theo thời gian thực</p>
      </div>

      <div class="search-bar">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="🔎 Tìm quán theo tên, món ăn, địa chỉ..."
        />
        <button type="button" class="btn btn-outline btn-sm" @click="loadRestaurants">
          Tải lại
        </button>
      </div>
    </div>

    <!-- Alert error -->
    <div v-if="error" class="alert alert-error">
      <span>⚠️ {{ error }}</span>
      <button type="button" class="btn btn-sm btn-outline" style="margin-left: auto;" @click="loadRestaurants">
        Thử lại
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="state-box">
      <div class="spinner"></div>
      <p style="margin-top: 12px;">Đang tải danh sách quán ăn từ máy chủ...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredRestaurants.length === 0" class="state-box">
      <div class="icon">🍽️</div>
      <h3>Chưa tìm thấy quán ăn nào</h3>
      <p v-if="searchQuery">Không có kết quả khớp với "{{ searchQuery }}". Hãy thử từ khoá khác.</p>
      <p v-else>Hệ thống chưa có quán ăn nào. Hãy đăng nhập tài khoản Chủ quán để đăng quán đầu tiên!</p>
    </div>

    <!-- Grid List -->
    <div v-else class="grid">
      <RestaurantCard
        v-for="r in filteredRestaurants"
        :key="r.id"
        :restaurant="r"
        @view-detail="openDetail"
      />
    </div>

    <!-- Detail Modal -->
    <div v-if="selectedRestaurant" class="modal-overlay" @click.self="closeDetail">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ selectedRestaurant.name }}</h3>
          <button type="button" class="modal-close" @click="closeDetail">×</button>
        </div>

        <div class="detail-body">
          <p v-if="selectedRestaurant.address" class="detail-item">
            <strong>Địa chỉ:</strong> {{ selectedRestaurant.address }}
          </p>
          <p v-if="selectedRestaurant.phone" class="detail-item">
            <strong>Hotline:</strong>
            <a :href="'tel:' + selectedRestaurant.phone" style="color: var(--c-primary); font-weight: 600; margin-left: 6px;">
              {{ selectedRestaurant.phone }}
            </a>
          </p>
          <p v-if="selectedRestaurant.description" class="detail-item">
            <strong>Mô tả:</strong> {{ selectedRestaurant.description }}
          </p>
          <div class="detail-item">
            <strong>Toạ độ PostGIS:</strong>
            <code>{{ selectedRestaurant.latitude }}, {{ selectedRestaurant.longitude }}</code>
          </div>
        </div>

        <div style="margin-top: 24px; text-align: right;">
          <button type="button" class="btn btn-primary btn-sm" @click="closeDetail">
            Đóng
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.section-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 20px;
}

.search-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 320px;
}

.detail-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 12px;
}

.detail-item {
  font-size: 0.95rem;
  color: var(--c-text);
}

.detail-item strong {
  color: var(--c-text);
  margin-right: 6px;
}

code {
  background: var(--c-bg);
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.88rem;
  border: 1px solid var(--c-border);
}

@media (max-width: 640px) {
  .search-bar {
    width: 100%;
  }
}
</style>
