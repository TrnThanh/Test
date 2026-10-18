<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { Restaurant, Category, Dish, RoleLoginResponse } from '../types';
import { api } from '../services/api';
import RestaurantCard from './RestaurantCard.vue';

const props = defineProps<{
  currentUser?: RoleLoginResponse | null;
}>();

const restaurants = ref<Restaurant[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const searchQuery = ref('');
const selectedRestaurant = ref<Restaurant | null>(null);

// Menu State in Modal
const menuCategories = ref<Category[]>([]);
const menuDishes = ref<Dish[]>([]);
const menuLoading = ref(false);
const menuError = ref<string | null>(null);
const selectedCategoryId = ref<number | null>(null);
const userFavIds = ref<Set<number>>(new Set());

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

async function openDetail(restaurant: Restaurant) {
  selectedRestaurant.value = restaurant;
  selectedCategoryId.value = null;
  menuLoading.value = true;
  menuError.value = null;

  try {
    const [cats, dishes] = await Promise.all([
      api.getRestaurantCategories(restaurant.id, true),
      api.getRestaurantDishes(restaurant.id),
    ]);
    menuCategories.value = cats;
    menuDishes.value = dishes;

    if (props.currentUser && props.currentUser.role === 'user') {
      try {
        const favs = await api.getUserFavourites(props.currentUser.id);
        userFavIds.value = new Set(favs.map((f) => f.dish_id));
      } catch {
        // ignore favourite fetch error
      }
    }
  } catch (err: any) {
    menuError.value = err.message || 'Không thể tải thực đơn';
  } finally {
    menuLoading.value = false;
  }
}

function closeDetail() {
  selectedRestaurant.value = null;
  menuCategories.value = [];
  menuDishes.value = [];
}

const displayedDishes = computed(() => {
  if (selectedCategoryId.value === null) return menuDishes.value;
  return menuDishes.value.filter((d) => d.category_id === selectedCategoryId.value);
});

async function toggleFavourite(dish: Dish) {
  if (!props.currentUser || props.currentUser.role !== 'user') {
    alert('Vui lòng đăng nhập tài khoản Khách hàng để lưu món yêu thích.');
    return;
  }
  const isFav = userFavIds.value.has(dish.id);
  try {
    if (isFav) {
      await api.removeFavouriteDish(props.currentUser.id, dish.id);
      userFavIds.value.delete(dish.id);
    } else {
      await api.addFavouriteDish(props.currentUser.id, dish.id);
      userFavIds.value.add(dish.id);
    }
    userFavIds.value = new Set(userFavIds.value);
  } catch (err: any) {
    alert(err.message || 'Thao tác không thành công');
  }
}

function formatPrice(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
}

onMounted(() => {
  loadRestaurants();
});
</script>

<template>
  <div class="explore-section">
    <div class="section-header">
      <div>
        <h2 style="font-size: 1.5rem; font-weight: 700; margin-bottom: 4px;">Khám phá Quán ăn</h2>
        <p style="color: var(--c-text-muted); font-size: 0.95rem;">
          Toàn bộ quán ăn được lưu trữ với toạ độ không gian PostGIS trên PostgreSQL
        </p>
      </div>

      <div class="search-bar">
        <input
          v-model="searchQuery"
          type="text"
          class="input"
          placeholder="Tìm theo tên quán, địa chỉ..."
        />
        <button
          type="button"
          class="btn btn-secondary btn-sm"
          :disabled="loading"
          @click="loadRestaurants"
        >
          {{ loading ? 'Đang tải...' : 'Làm mới' }}
        </button>
      </div>
    </div>

    <!-- Error State -->
    <div v-if="error" class="state-box" style="margin-bottom: 24px;">
      <div class="icon">⚠️</div>
      <p style="color: var(--c-danger); font-weight: 600;">{{ error }}</p>
      <button type="button" class="btn btn-primary btn-sm" style="margin-top: 10px;" @click="loadRestaurants">
        Thử lại
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading && restaurants.length === 0" class="state-box">
      <div class="icon">⏳</div>
      <p>Đang tải danh sách quán ăn từ cơ sở dữ liệu...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="!loading && filteredRestaurants.length === 0" class="state-box">
      <div class="icon">🍽️</div>
      <h3>Không tìm thấy quán ăn nào</h3>
      <p>Thử tìm kiếm với từ khoá khác hoặc tạo quán ăn mới nếu bạn là Chủ quán.</p>
    </div>

    <!-- Restaurant Grid -->
    <div v-else class="restaurant-grid">
      <RestaurantCard
        v-for="r in filteredRestaurants"
        :key="r.id"
        :restaurant="r"
        @click="openDetail(r)"
      />
    </div>

    <!-- Detail & Menu Modal -->
    <div v-if="selectedRestaurant" class="modal-overlay" @click.self="closeDetail">
      <div class="modal-content modal-menu">
        <div class="modal-header">
          <div>
            <h3 style="font-size: 1.25rem; font-weight: 700;">{{ selectedRestaurant.name }}</h3>
            <p v-if="selectedRestaurant.address" style="font-size: 0.88rem; color: var(--c-text-muted); margin-top: 2px;">
              📍 {{ selectedRestaurant.address }}
            </p>
          </div>
          <button type="button" class="modal-close" @click="closeDetail">×</button>
        </div>

        <div class="detail-info-bar">
          <span v-if="selectedRestaurant.phone" class="info-pill">
            📞 {{ selectedRestaurant.phone }}
          </span>
          <span v-if="selectedRestaurant.open_time && selectedRestaurant.close_time" class="info-pill">
            🕒 {{ selectedRestaurant.open_time }} – {{ selectedRestaurant.close_time }}
          </span>
          <span class="info-pill">
            🗺️ {{ selectedRestaurant.latitude.toFixed(4) }}, {{ selectedRestaurant.longitude.toFixed(4) }}
          </span>
        </div>

        <p v-if="selectedRestaurant.description" style="margin: 12px 0 16px; font-size: 0.92rem; color: var(--c-text-muted);">
          {{ selectedRestaurant.description }}
        </p>

        <!-- Menu Section -->
        <div class="menu-container">
          <div class="menu-header-row">
            <h4 style="font-size: 1.1rem; font-weight: 700;">Thực đơn món ăn</h4>
            <span v-if="!menuLoading" style="font-size: 0.85rem; color: var(--c-text-muted);">
              {{ displayedDishes.length }} món
            </span>
          </div>

          <!-- Category Filter Pills -->
          <div v-if="menuCategories.length > 0" class="category-pills">
            <button
              type="button"
              class="pill-btn"
              :class="{ active: selectedCategoryId === null }"
              @click="selectedCategoryId = null"
            >
              Tất cả
            </button>
            <button
              v-for="cat in menuCategories"
              :key="cat.id"
              type="button"
              class="pill-btn"
              :class="{ active: selectedCategoryId === cat.id }"
              @click="selectedCategoryId = cat.id"
            >
              {{ cat.name }} <span v-if="cat.dish_count">({{ cat.dish_count }})</span>
            </button>
          </div>

          <!-- Menu Loading / Error / Empty -->
          <div v-if="menuLoading" class="menu-loading">
            <span>⏳ Đang tải thực đơn...</span>
          </div>
          <div v-else-if="menuError" class="menu-error">
            <span>⚠️ {{ menuError }}</span>
          </div>
          <div v-else-if="displayedDishes.length === 0" class="menu-empty">
            <span>🍽️ Quán chưa có món nào trong nhóm danh mục này.</span>
          </div>

          <!-- Dish List -->
          <div v-else class="dish-list">
            <div
              v-for="dish in displayedDishes"
              :key="dish.id"
              class="dish-card"
              :class="{ unavailable: !dish.is_available }"
            >
              <div class="dish-info">
                <div class="dish-title-row">
                  <h5 class="dish-name">{{ dish.name }}</h5>
                  <span class="dish-price">{{ formatPrice(dish.price) }}</span>
                </div>
                <p v-if="dish.description" class="dish-desc">{{ dish.description }}</p>
                
                <div class="dish-meta">
                  <span v-if="dish.category_name || dish.category" class="badge badge-info">
                    📁 {{ dish.category_name || dish.category }}
                  </span>
                  <span class="badge badge-secondary">
                    🍴 {{ dish.meal_type }}
                  </span>
                  <span
                    v-for="t in dish.tags"
                    :key="t"
                    class="badge badge-primary"
                  >
                    #{{ t }}
                  </span>
                  <span v-if="!dish.is_available" class="badge badge-danger">
                    Tạm hết
                  </span>
                </div>
              </div>

              <div class="dish-actions">
                <button
                  type="button"
                  class="fav-btn"
                  :class="{ active: userFavIds.has(dish.id) }"
                  :title="userFavIds.has(dish.id) ? 'Bỏ thích món này' : 'Yêu thích món này'"
                  @click="toggleFavourite(dish)"
                >
                  {{ userFavIds.has(dish.id) ? '❤️' : '🤍' }}
                </button>
              </div>
            </div>
          </div>
        </div>

        <div style="margin-top: 24px; text-align: right;">
          <button type="button" class="btn btn-secondary btn-sm" @click="closeDetail">
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

.modal-menu {
  max-width: 680px;
  width: 95%;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
}

.detail-info-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}

.info-pill {
  background: var(--c-bg);
  border: 1px solid var(--c-border);
  border-radius: 6px;
  padding: 4px 8px;
  font-size: 0.85rem;
  color: var(--c-text);
}

.menu-container {
  border-top: 1px solid var(--c-border);
  padding-top: 16px;
  margin-top: 12px;
  overflow-y: auto;
  flex: 1;
}

.menu-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.category-pills {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 8px;
  margin-bottom: 14px;
}

.pill-btn {
  background: var(--c-bg);
  border: 1px solid var(--c-border);
  border-radius: 20px;
  padding: 5px 14px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  color: var(--c-text);
  transition: all 0.15s ease;
}

.pill-btn:hover {
  border-color: var(--c-primary);
}

.pill-btn.active {
  background: var(--c-primary);
  color: white;
  border-color: var(--c-primary);
}

.dish-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.dish-card {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 12px 14px;
  border: 1px solid var(--c-border);
  border-radius: 8px;
  background: var(--c-surface);
  transition: border-color 0.15s;
}

.dish-card:hover {
  border-color: var(--c-border-hover);
}

.dish-card.unavailable {
  opacity: 0.6;
}

.dish-info {
  flex: 1;
  padding-right: 12px;
}

.dish-title-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
}

.dish-name {
  font-size: 1rem;
  font-weight: 600;
  color: var(--c-text);
}

.dish-price {
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--c-primary);
  white-space: nowrap;
}

.dish-desc {
  font-size: 0.85rem;
  color: var(--c-text-muted);
  margin-top: 4px;
}

.dish-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 8px;
}

.fav-btn {
  background: none;
  border: 1px solid var(--c-border);
  border-radius: 50%;
  width: 36px;
  height: 36px;
  cursor: pointer;
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.15s, background 0.15s;
}

.fav-btn:hover {
  transform: scale(1.1);
  background: var(--c-bg);
}

.menu-loading,
.menu-error,
.menu-empty {
  text-align: center;
  padding: 24px 0;
  color: var(--c-text-muted);
  font-size: 0.92rem;
}

@media (max-width: 640px) {
  .search-bar {
    width: 100%;
    min-width: 100%;
  }
}
</style>
