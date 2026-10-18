<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse, Restaurant } from '../types';
import { api } from '../services/api';

defineProps<{
  admin: RoleLoginResponse;
}>();

const restaurants = ref<Restaurant[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const searchQuery = ref('');

async function loadAllRestaurants() {
  loading.value = true;
  error.value = null;
  try {
    restaurants.value = await api.getRestaurants(0, 200);
  } catch (err: any) {
    error.value = err.message || 'Không thể tải danh sách quán ăn';
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  loadAllRestaurants();
});
</script>

<template>
  <div class="admin-dashboard">
    <div class="dashboard-header">
      <div>
        <h2 style="font-size: 1.6rem; font-weight: 800;">Cổng Quản Trị Hệ Thống (Admin Portal)</h2>
        <p style="color: var(--c-text-muted); font-size: 0.95rem;">
          Quản trị viên: <strong>{{ admin.email }}</strong> • Giám sát và quản lý toàn bộ cơ sở ẩm thực trên hệ thống
        </p>
      </div>

      <button type="button" class="btn btn-secondary btn-sm" :disabled="loading" @click="loadAllRestaurants">
        {{ loading ? 'Đang tải...' : 'Làm mới dữ liệu' }}
      </button>
    </div>

    <!-- Stats row -->
    <div class="stats-row">
      <div class="stat-card">
        <span class="stat-num">{{ restaurants.length }}</span>
        <span class="stat-label">Tổng số quán ăn</span>
      </div>
      <div class="stat-card">
        <span class="stat-num">
          {{ restaurants.filter((r) => r.is_active).length }}
        </span>
        <span class="stat-label">Đang hoạt động</span>
      </div>
      <div class="stat-card">
        <span class="stat-num">
          {{ restaurants.filter((r) => !r.is_active).length }}
        </span>
        <span class="stat-label">Tạm ngừng hoạt động</span>
      </div>
    </div>

    <!-- Filter & Search -->
    <div style="margin: 20px 0 16px;">
      <input
        v-model="searchQuery"
        type="text"
        class="input"
        placeholder="Tìm kiếm theo tên quán, địa chỉ..."
        style="max-width: 400px;"
      />
    </div>

    <!-- Table of all restaurants -->
    <div v-if="loading" class="state-box">
      <div class="spinner"></div>
      <p style="margin-top: 12px;">Đang tải dữ liệu toàn hệ thống...</p>
    </div>

    <div v-else-if="error" class="alert alert-error">
      {{ error }}
    </div>

    <div v-else class="table-container">
      <table class="admin-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Tên Quán</th>
            <th>Chủ Quán (Seller ID)</th>
            <th>Địa chỉ</th>
            <th>Giờ mở cửa</th>
            <th>Toạ độ PostGIS</th>
            <th>Trạng thái</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="r in restaurants.filter((x) =>
              !searchQuery.trim() ||
              x.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
              (x.address && x.address.toLowerCase().includes(searchQuery.toLowerCase()))
            )"
            :key="r.id"
          >
            <td>#{{ r.id }}</td>
            <td style="font-weight: 700;">{{ r.name }}</td>
            <td>Seller #{{ r.seller_id }}</td>
            <td>{{ r.address || '—' }}</td>
            <td>
              <span v-if="r.open_time && r.close_time">{{ r.open_time }} – {{ r.close_time }}</span>
              <span v-else>—</span>
            </td>
            <td><code>{{ r.latitude.toFixed(4) }}, {{ r.longitude.toFixed(4) }}</code></td>
            <td>
              <span class="badge" :class="r.is_active ? 'badge-primary' : 'badge-danger'">
                {{ r.is_active ? 'Hoạt động' : 'Tạm dừng' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped>
.admin-dashboard {
  max-width: 1100px;
  margin: 0 auto;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 20px;
}

.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.stat-card {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
}

.stat-num {
  font-size: 2rem;
  font-weight: 800;
  color: #000000;
}

.stat-label {
  font-size: 0.9rem;
  color: var(--c-text-muted);
  margin-top: 4px;
}

.table-container {
  overflow-x: auto;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  background: var(--c-surface);
}

.admin-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 0.92rem;
}

.admin-table th,
.admin-table td {
  padding: 12px 16px;
  border-bottom: 1px solid var(--c-border);
}

.admin-table th {
  background: #f5f5f5;
  font-weight: 700;
  color: #000000;
}

.admin-table tr:hover td {
  background: #fafafa;
}
</style>
