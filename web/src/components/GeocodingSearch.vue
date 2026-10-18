<script setup lang="ts">
import { ref } from 'vue';
import type { GeocodePlace } from '../types';
import { api } from '../services/api';

const query = ref('');
const places = ref<GeocodePlace[]>([]);
const searching = ref(false);
const searchError = ref<string | null>(null);

// Reverse geocoding fields
const revLat = ref<number | null>(21.0285);
const revLon = ref<number | null>(105.8542);
const revAddress = ref<string | null>(null);
const revLoading = ref(false);
const revError = ref<string | null>(null);

let debounceTimer: ReturnType<typeof setTimeout> | null = null;
let abortController: AbortController | null = null;

function onQueryInput() {
  if (debounceTimer) clearTimeout(debounceTimer);
  if (!query.value.trim() || query.value.trim().length < 2) {
    places.value = [];
    searching.value = false;
    return;
  }

  searching.value = true;
  searchError.value = null;

  debounceTimer = setTimeout(async () => {
    if (abortController) abortController.abort();
    abortController = new AbortController();

    try {
      const results = await api.searchMap(query.value.trim(), 6, abortController.signal);
      places.value = results;
    } catch (err: any) {
      if (err.name !== 'AbortError') {
        searchError.value = err.message || 'Không thể tra cứu địa chỉ';
      }
    } finally {
      searching.value = false;
    }
  }, 500);
}

function selectPlace(place: GeocodePlace) {
  revLat.value = place.latitude;
  revLon.value = place.longitude;
  revAddress.value = place.display_name;
}

async function doReverseGeocode() {
  if (revLat.value == null || revLon.value == null) return;
  revLoading.value = true;
  revError.value = null;
  revAddress.value = null;

  try {
    const res = await api.reverseMap(revLat.value, revLon.value);
    revAddress.value = res.address;
  } catch (err: any) {
    revError.value = err.message || 'Không thể đổi toạ độ sang địa chỉ';
  } finally {
    revLoading.value = false;
  }
}
</script>

<template>
  <div class="geocoding-section">
    <div class="section-header">
      <h2>Bản đồ & Geocoding (OpenStreetMap Nominatim)</h2>
      <p>Chuyển đổi địa chỉ thực tế thành toạ độ bản đồ (Forward Geocoding) và ngược lại (Reverse Geocoding).</p>
    </div>

    <div class="grid-2col">
      <!-- Col 1: Forward Geocoding -->
      <div class="card">
        <h3>🔍 Tìm kiếm địa chỉ (Forward Geocoding)</h3>
        <p class="subtitle">Nhập địa danh hoặc địa chỉ để lấy toạ độ địa lý chính xác (debounce 500ms):</p>

        <div class="form-group" style="margin-top: 16px;">
          <input
            v-model="query"
            type="text"
            placeholder="Ví dụ: Hồ Gươm, Nhà hát lớn Hà Nội, Chợ Bến Thành..."
            @input="onQueryInput"
          />
        </div>

        <div v-if="searching" class="loading-hint">
          <span class="spinner" style="width: 16px; height: 16px;"></span>
          <span>Đang tìm kiếm trên OpenStreetMap...</span>
        </div>

        <div v-if="searchError" class="alert alert-error" style="margin-top: 12px;">
          {{ searchError }}
        </div>

        <div v-if="places.length > 0" class="place-results">
          <div
            v-for="p in places"
            :key="p.place_id"
            class="place-item"
            @click="selectPlace(p)"
          >
            <div class="place-name">{{ p.display_name }}</div>
            <div class="place-coords">
              <code>Vĩ độ: {{ p.latitude.toFixed(5) }}</code>
              <code>Kinh độ: {{ p.longitude.toFixed(5) }}</code>
            </div>
          </div>
        </div>

        <div v-else-if="!searching && query.length >= 2" class="empty-hint">
          Không tìm thấy địa điểm phù hợp trên bản đồ.
        </div>
      </div>

      <!-- Col 2: Reverse Geocoding -->
      <div class="card">
        <h3>📍 Đổi toạ độ sang địa chỉ (Reverse Geocoding)</h3>
        <p class="subtitle">Nhập cặp toạ độ vĩ độ / kinh độ để truy vấn địa chỉ cụ thể:</p>

        <div class="coords-form" style="margin-top: 16px;">
          <div class="form-group">
            <label>Vĩ độ (Lat):</label>
            <input v-model.number="revLat" type="number" step="0.0001" placeholder="21.0285" />
          </div>
          <div class="form-group">
            <label>Kinh độ (Lon):</label>
            <input v-model.number="revLon" type="number" step="0.0001" placeholder="105.8542" />
          </div>
        </div>

        <button
          type="button"
          class="btn btn-primary"
          style="width: 100%; margin-top: 8px;"
          :disabled="revLoading || revLat == null || revLon == null"
          @click="doReverseGeocode"
        >
          <span v-if="revLoading" class="spinner" style="width: 16px; height: 16px;"></span>
          <span v-else>Tra cứu địa chỉ thực tế</span>
        </button>

        <div v-if="revError" class="alert alert-error" style="margin-top: 16px;">
          {{ revError }}
        </div>

        <div v-if="revAddress" class="reverse-result card" style="margin-top: 16px; background: var(--c-bg);">
          <h4>Kết quả địa chỉ:</h4>
          <p style="color: var(--c-text); font-weight: 500; margin-top: 6px;">{{ revAddress }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.subtitle {
  font-size: 0.88rem;
  margin-top: 4px;
}

.grid-2col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-top: 20px;
}

.loading-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.85rem;
  color: var(--c-text-muted);
  margin-top: 8px;
}

.place-results {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 380px;
  overflow-y: auto;
}

.place-item {
  padding: 10px 12px;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-sm);
  background: var(--c-bg);
  cursor: pointer;
  transition: var(--transition);
}

.place-item:hover {
  border-color: var(--c-primary);
  background: var(--c-primary-light);
}

.place-name {
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--c-text);
  margin-bottom: 6px;
}

.place-coords {
  display: flex;
  gap: 8px;
}

.place-coords code {
  font-size: 0.78rem;
  background: var(--c-surface);
  padding: 2px 6px;
  border-radius: 4px;
  border: 1px solid var(--c-border);
}

.empty-hint {
  font-size: 0.88rem;
  color: var(--c-text-muted);
  margin-top: 12px;
}

.coords-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.reverse-result {
  border: 1px solid var(--c-border);
  padding: 14px;
}

@media (max-width: 768px) {
  .grid-2col {
    grid-template-columns: 1fr;
  }
}
</style>
