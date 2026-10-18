<script setup lang="ts">
import type { Restaurant } from '../types';

defineProps<{
  restaurant: Restaurant;
}>();

const emit = defineEmits<{
  (e: 'viewDetail', restaurant: Restaurant): void;
}>();
</script>

<template>
  <div class="restaurant-card card">
    <div class="card-header">
      <h3 class="restaurant-name">{{ restaurant.name }}</h3>
      <span v-if="restaurant.distance_km != null" class="badge badge-primary">
        📍 {{ restaurant.distance_km < 1 ? Math.round(restaurant.distance_km * 1000) + ' m' : restaurant.distance_km.toFixed(1) + ' km' }}
      </span>
      <span v-else-if="restaurant.distance_meters != null" class="badge badge-primary">
        📍 {{ restaurant.distance_meters < 1000 ? Math.round(restaurant.distance_meters) + ' m' : (restaurant.distance_meters / 1000).toFixed(1) + ' km' }}
      </span>
    </div>

    <p v-if="restaurant.address" class="restaurant-address">
      🏠 {{ restaurant.address }}
    </p>

    <p v-if="restaurant.phone" class="restaurant-phone">
      📞 {{ restaurant.phone }}
    </p>

    <p v-if="restaurant.description" class="restaurant-desc">
      {{ restaurant.description }}
    </p>

    <div class="card-footer">
      <div class="coordinates">
        Toạ độ: {{ restaurant.latitude.toFixed(4) }}, {{ restaurant.longitude.toFixed(4) }}
      </div>
      <button type="button" class="btn btn-outline btn-sm" @click="emit('viewDetail', restaurant)">
        Chi tiết
      </button>
    </div>
  </div>
</template>

<style scoped>
.restaurant-card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 8px;
}

.restaurant-name {
  color: var(--c-text);
  font-size: 1.15rem;
}

.restaurant-address {
  font-size: 0.9rem;
  color: var(--c-text);
  margin-bottom: 4px;
}

.restaurant-phone {
  font-size: 0.88rem;
  color: var(--c-primary);
  font-weight: 600;
  margin-bottom: 6px;
}

.restaurant-desc {
  font-size: 0.85rem;
  color: var(--c-text-muted);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 12px;
}

.card-footer {
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px dashed var(--c-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.8rem;
  color: var(--c-text-muted);
}
</style>
