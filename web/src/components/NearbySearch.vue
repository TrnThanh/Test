<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import type { Restaurant } from '../types';
import { api } from '../services/api';
import RestaurantCard from './RestaurantCard.vue';

// Default: Hồ Gươm, Hà Nội (21.0285, 105.8542)
const lat = ref(21.0285);
const lon = ref(105.8542);
const radiusKm = ref(5);
const restaurants = ref<Restaurant[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const gpsStatus = ref<string | null>(null);

let abortController: AbortController | null = null;

async function searchNearby() {
  if (abortController) {
    abortController.abort();
  }
  abortController = new AbortController();

  loading.value = true;
  error.value = null;

  try {
    const data = await api.getNearbyRestaurants(lat.value, lon.value, radiusKm.value, abortController.signal);
    restaurants.value = data;
  } catch (err: any) {
    if (err.name !== 'AbortError') {
      error.value = err.message || 'Không thể tìm quán ăn lân cận';
    }
  } finally {
    loading.value = false;
  }
}

function useGps() {
  if (!navigator.geolocation) {
    gpsStatus.value = 'Trình duyệt của bạn không hỗ trợ định vị GPS.';
    return;
  }

  gpsStatus.value = 'Đang lấy vị trí GPS...';
  navigator.geolocation.getCurrentPosition(
    (position) => {
      lat.value = Number(position.coords.latitude.toFixed(5));
      lon.value = Number(position.coords.longitude.toFixed(5));
      gpsStatus.value = 'Đã lấy vị trí thành công!';
      searchNearby();
      setTimeout(() => (gpsStatus.value = null), 3000);
    },
    (err) => {
      gpsStatus.value = `Chưa cấp quyền GPS (${err.message}). Bạn có thể dùng vị trí mẫu bên dưới.`;
    },
    { timeout: 10000 }
  );
}

function selectPreset(presetLat: number, presetLon: number) {
  lat.value = presetLat;
  lon.value = presetLon;
  searchNearby();
}

watch(radiusKm, () => {
  searchNearby();
});

onMounted(() => {
  searchNearby();
});
</script>

<template>
  <div class="nearby-section">
    <div class="section-header">
      <h2>Tìm quán ăn lân cận (PostGIS Spatial)</h2>
      <p>Ứng dụng hàm không gian <code>ST_DWithin</code> và <code>ST_Distance</code> trên PostgreSQL để lọc và tính khoảng cách chính xác theo mét.</p>
    </div>

    <!-- Control Card -->
    <div class="card control-card">
      <div class="coords-row">
        <div class="form-group flex-1">
          <label>Vĩ độ (Latitude):</label>
          <input v-model.number="lat" type="number" step="0.0001" placeholder="Vĩ độ" @change="searchNearby" />
        </div>

        <div class="form-group flex-1">
          <label>Kinh độ (Longitude):</label>
          <input v-model.number="lon" type="number" step="0.0001" placeholder="Kinh độ" @change="searchNearby" />
        </div>

        <div class="gps-btn-col">
          <button type="button" class="btn btn-outline" @click="useGps">
            🎯 Lấy vị trí GPS của tôi
          </button>
        </div>
      </div>

      <!-- Presets -->
      <div class="preset-row">
        <span class="preset-label">Vị trí mẫu:</span>
        <button type="button" class="preset-chip" @click="selectPreset(21.0285, 105.8542)">
          🏛️ Hồ Gươm, Hà Nội
        </button>
        <button type="button" class="preset-chip" @click="selectPreset(21.0378, 105.7838)">
          🏢 Cầu Giấy, Hà Nội
        </button>
        <button type="button" class="preset-chip" @click="selectPreset(10.7769, 106.7009)">
          🌆 Quận 1, TP.HCM
        </button>
      </div>

      <p v-if="gpsStatus" class="gps-status-msg">{{ gpsStatus }}</p>

      <!-- Radius Slider -->
      <div class="slider-row">
        <div class="slider-header">
          <label>Bán kính tìm kiếm (Radius):</label>
          <span class="radius-value badge badge-primary">{{ radiusKm }} km</span>
        </div>
        <input
          v-model.number="radiusKm"
          type="range"
          min="1"
          max="20"
          step="0.5"
          class="slider-input"
        />
        <div class="slider-labels">
          <span>1 km</span>
          <span>5 km</span>
          <span>10 km</span>
          <span>15 km</span>
          <span>20 km</span>
        </div>
      </div>
    </div>

    <!-- Results Section -->
    <div style="margin-top: 24px;">
      <div class="results-header">
        <h3>Kết quả tìm kiếm ({{ restaurants.length }} quán trong {{ radiusKm }} km)</h3>
      </div>

      <div v-if="error" class="alert alert-error">
        <span>⚠️ {{ error }}</span>
        <button type="button" class="btn btn-sm btn-outline" style="margin-left: auto;" @click="searchNearby">
          Thử lại
        </button>
      </div>

      <div v-if="loading" class="state-box">
        <div class="spinner"></div>
        <p style="margin-top: 12px;">Đang quét toạ độ PostGIS trong bán kính {{ radiusKm }} km...</p>
      </div>

      <div v-else-if="restaurants.length === 0" class="state-box">
        <div class="icon">🔍</div>
        <h3>Không tìm thấy quán nào trong bán kính {{ radiusKm }} km</h3>
        <p>Thử tăng thanh trượt bán kính lên hoặc chọn toạ độ khác.</p>
      </div>

      <div v-else class="grid">
        <RestaurantCard
          v-for="r in restaurants"
          :key="r.id"
          :restaurant="r"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.control-card {
  margin-top: 16px;
  background: var(--c-surface);
}

.coords-row {
  display: flex;
  gap: 16px;
  align-items: flex-end;
  flex-wrap: wrap;
}

.flex-1 {
  flex: 1;
  min-width: 140px;
}

.gps-btn-col {
  margin-bottom: 16px;
}

.preset-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 16px;
}

.preset-label {
  font-size: 0.85rem;
  color: var(--c-text-muted);
  font-weight: 600;
}

.preset-chip {
  background: var(--c-bg);
  border: 1px solid var(--c-border);
  padding: 4px 10px;
  border-radius: var(--radius-sm);
  font-size: 0.82rem;
  cursor: pointer;
  transition: var(--transition);
}

.preset-chip:hover {
  border-color: var(--c-primary);
  color: var(--c-primary);
  background: var(--c-primary-light);
}

.gps-status-msg {
  font-size: 0.85rem;
  color: var(--c-info);
  margin-bottom: 12px;
}

.slider-row {
  margin-top: 12px;
  padding-top: 16px;
  border-top: 1px solid var(--c-border);
}

.slider-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.radius-value {
  font-size: 0.95rem;
  padding: 4px 12px;
}

.slider-input {
  width: 100%;
  accent-color: var(--c-primary);
  cursor: pointer;
  height: 6px;
}

.slider-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.78rem;
  color: var(--c-text-muted);
  margin-top: 4px;
}

.results-header {
  margin-bottom: 12px;
}
</style>
