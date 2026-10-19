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
  <div class="restaurant-card card" @click="emit('viewDetail', restaurant)">
    <div class="card-top">
      <div class="icon-avatar">🍲</div>
      <div class="top-info">
        <h3 class="restaurant-name">{{ restaurant.name }}</h3>
        <div class="badges-row">
          <span v-if="restaurant.open_time && restaurant.close_time" class="badge badge-success">
            🕒 {{ restaurant.open_time }} – {{ restaurant.close_time }}
          </span>
          <span v-if="restaurant.distance_km != null" class="badge badge-primary">
            📍 {{ restaurant.distance_km < 1 ? Math.round(restaurant.distance_km * 1000) + ' m' : restaurant.distance_km.toFixed(1) + ' km' }}
          </span>
          <span v-else-if="restaurant.distance_meters != null" class="badge badge-primary">
            📍 {{ restaurant.distance_meters < 1000 ? Math.round(restaurant.distance_meters) + ' m' : (restaurant.distance_meters / 1000).toFixed(1) + ' km' }}
          </span>
        </div>
      </div>
    </div>

    <p v-if="restaurant.address" class="restaurant-address">
      📍 {{ restaurant.address }}
    </p>

    <p v-if="restaurant.phone" class="restaurant-phone">
      📞 {{ restaurant.phone }}
    </p>

    <p v-if="restaurant.description" class="restaurant-desc">
      {{ restaurant.description }}
    </p>

    <div class="card-bottom">
      <span class="view-menu-hint">Xem thực đơn & món ăn →</span>
      <button type="button" class="btn btn-primary btn-sm" @click.stop="emit('viewDetail', restaurant)">
        Xem Menu
      </button>
    </div>
  </div>
</template>

<style scoped>
.restaurant-card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  cursor: pointer;
  border-radius: var(--radius-lg);
  background: var(--c-surface);
  box-shadow: var(--shadow-sm);
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
  padding: 18px;
}

.restaurant-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-md);
  border-color: var(--c-primary);
}

.card-top {
  display: flex;
  gap: 12px;
  align-items: flex-start;
  margin-bottom: 10px;
}

.icon-avatar {
  font-size: 2.2rem;
  background-color: var(--c-primary-light);
  width: 52px;
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-md);
  flex-shrink: 0;
}

.top-info {
  flex: 1;
}

.restaurant-name {
  color: var(--c-text);
  font-size: 1.15rem;
  font-weight: 700;
  margin-bottom: 4px;
}

.badges-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 4px;
}

.restaurant-address {
  font-size: 0.88rem;
  color: var(--c-text-muted);
  margin-bottom: 6px;
  line-height: 1.4;
}

.restaurant-phone {
  font-size: 0.85rem;
  color: var(--c-primary);
  font-weight: 600;
  margin-bottom: 8px;
}

.restaurant-desc {
  font-size: 0.85rem;
  color: var(--c-text-muted);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: 12px;
  line-height: 1.4;
}

.card-bottom {
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px dashed var(--c-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.view-menu-hint {
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--c-primary);
}
</style>
