<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted } from 'vue';
import type { Restaurant, Category, Dish, MealType, Ingredient, IngredientGroup } from '../../types';
import { api } from '../../services/api';
import { useToast } from '../../composables/useToast';
import PageHeader from '../common/PageHeader.vue';
import Chip from '../common/Chip.vue';
import BaseModal from '../common/BaseModal.vue';
import ConfirmDialog from '../common/ConfirmDialog.vue';
import IngredientInput from '../common/IngredientInput.vue';
import {
  Plus,
  Search,
  Image as ImageIcon,
  Edit,
  Trash2,
  RefreshCw,
  Clock,
  MapPin,
  UtensilsCrossed,
} from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    restaurants: Restaurant[];
    selectedRestaurantId: number | null;
    categories: Category[];
    masterCategories: Category[];
    dishes: Dish[];
    loading: boolean;
    error?: string | null;
  }>(),
  {
    error: null,
  }
);

const emit = defineEmits<{
  (e: 'selectRestaurant', restaurantId: number): void;
  (e: 'dishCreated', dish: Dish): void;
  (e: 'dishUpdated', dish: Dish): void;
  (e: 'dishDeleted', dishId: number): void;
  (e: 'retry'): void;
}>();

const { showToast } = useToast();

const masterIngredients = ref<Ingredient[]>([]);
const ingredientGroups = ref<IngredientGroup[]>([]);

async function loadMasterIngredients() {
  try {
    const res = await api.getIngredients({ is_active_only: true, limit: 500 });
    masterIngredients.value = res.items || [];
  } catch {
    // ignore
  }
}

async function loadIngredientGroups() {
  try {
    ingredientGroups.value = await api.getIngredientGroups({ is_active_only: true });
  } catch {
    // ignore
  }
}

onMounted(() => {
  loadMasterIngredients();
  loadIngredientGroups();
});

// Normalization function (toLowerCase FIRST, then normalize NFD, remove accents and đ)
function normalizeText(str: string): string {
  if (!str) return '';
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .trim();
}

// Master list search state (left pane)
const restSearchQuery = ref('');

const filteredRestaurants = computed(() => {
  const q = normalizeText(restSearchQuery.value);
  if (!q) return props.restaurants;
  return props.restaurants.filter((r) => {
    const textTarget = normalizeText(`${r.name} ${r.address || ''}`);
    return textTarget.includes(q);
  });
});

// Current selected restaurant
const currentRestaurant = computed(() => {
  return (
    props.restaurants.find((r) => r.id === props.selectedRestaurantId) || null
  );
});

// Category & Dish filtering (right pane)
const selectedCategoryId = ref<number | 'all'>('all');
const dishSearchQuery = ref('');

const masterListScrollEl = ref<HTMLElement | null>(null);

// Reset category tab to 'Tất cả' and dish filter to empty when switching restaurant, auto scroll into view
watch(
  () => props.selectedRestaurantId,
  (newId) => {
    selectedCategoryId.value = 'all';
    dishSearchQuery.value = '';
    if (newId) {
      nextTick(() => {
        const activeEl = masterListScrollEl.value?.querySelector('.li.on') as HTMLElement | null;
        if (activeEl) {
          activeEl.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
      });
    }
  },
  { immediate: true }
);

// Failed images tracking for fallback placeholder
const failedImageMap = ref<Record<number, boolean>>({});
function handleImageError(dishId: number) {
  failedImageMap.value[dishId] = true;
}

// Unified available categories list (deduplicated by id)
const availableCategories = computed(() => {
  const map = new Map<number, Category>();
  for (const c of props.masterCategories) {
    map.set(c.id, c);
  }
  for (const c of props.categories) {
    map.set(c.id, c);
  }
  return Array.from(map.values()).sort(
    (a, b) => a.display_order - b.display_order || a.name.localeCompare(b.name)
  );
});

// Filtered dishes
const filteredDishes = computed(() => {
  return props.dishes.filter((d) => {
    // Filter by category
    if (selectedCategoryId.value !== 'all') {
      if (d.category_id !== selectedCategoryId.value) return false;
    }

    // Filter by dish search (name, description, ingredients)
    const q = normalizeText(dishSearchQuery.value);
    if (!q) return true;

    const ingText = (d.ingredients || []).join(' ');
    const dishTarget = normalizeText(
      `${d.name} ${d.description || ''} ${ingText}`
    );
    return dishTarget.includes(q);
  });
});

function getMealTypeLabel(code?: string | null): string {
  if (!code) return 'Cả ngày';
  const c = code.toLowerCase();
  if (c.includes('break') || c.includes('sáng')) return 'Bữa sáng';
  if (c.includes('lunch') || c.includes('trưa')) return 'Bữa trưa';
  if (c.includes('din') || c.includes('tối')) return 'Bữa tối';
  if (c.includes('snack') || c.includes('vặt')) return 'Ăn vặt';
  return 'Cả ngày';
}

function getSpicyLabel(level?: number | null): string {
  if (!level || level <= 0) return 'Không cay';
  if (level === 1) return 'Cay nhẹ';
  if (level === 2) return 'Cay vừa';
  return `Cay cấp ${level}`;
}

// ====================================================
// MODAL: THÊM MÓN ĂN
// ====================================================
const showCreateDishModal = ref(false);
const newDishName = ref('');
const newDishPrice = ref(35000);
const newDishDesc = ref('');
const newDishCategoryId = ref<number | null>(null);
const newDishMealType = ref<MealType>('all_day');
const newDishIngredients = ref('');
const newDishCalories = ref<number | null>(null);
const newDishSpicyLevel = ref(0);
const newDishImageUrl = ref('');
const newDishIsAvailable = ref(true);
const newDishSaving = ref(false);

function openCreateDish() {
  if (!props.selectedRestaurantId) {
    showToast('Vui lòng chọn một quán ăn trước');
    return;
  }
  newDishName.value = '';
  newDishPrice.value = 35000;
  newDishDesc.value = '';
  newDishCategoryId.value =
    selectedCategoryId.value !== 'all'
      ? selectedCategoryId.value
      : availableCategories.value.length > 0
      ? availableCategories.value[0].id
      : null;
  newDishMealType.value = 'all_day';
  newDishIngredients.value = '';
  newDishCalories.value = null;
  newDishSpicyLevel.value = 0;
  newDishImageUrl.value = '';
  newDishIsAvailable.value = true;
  loadMasterIngredients();
  loadIngredientGroups();
  showCreateDishModal.value = true;
}

async function handleCreateDishSubmit() {
  if (!props.selectedRestaurantId) return;
  if (!newDishName.value.trim()) {
    showToast('Tên món ăn không được để trống');
    return;
  }
  if (newDishPrice.value < 0) {
    showToast('Đơn giá không được âm');
    return;
  }

  newDishSaving.value = true;
  try {
    const priceNum = Number(newDishPrice.value);
    if (isNaN(priceNum) || priceNum < 0) {
      showToast('Đơn giá không hợp lệ (phải là số >= 0)');
      return;
    }

    const ingList = newDishIngredients.value
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    const calNum = newDishCalories.value != null && String(newDishCalories.value).trim() !== ''
      ? Number(newDishCalories.value)
      : undefined;
    if (calNum !== undefined && (isNaN(calNum) || calNum < 0 || calNum > 20000)) {
      showToast('Lượng calo phải là số từ 0 đến 20,000 kcal');
      newDishSaving.value = false;
      return;
    }
    const calories = calNum !== undefined && !isNaN(calNum) && calNum >= 0 ? calNum : undefined;

    const created = await api.createDish(props.selectedRestaurantId, {
      name: newDishName.value.trim(),
      price: priceNum,
      description: newDishDesc.value.trim() || undefined,
      category_id: newDishCategoryId.value ? Number(newDishCategoryId.value) : undefined,
      meal_types: [newDishMealType.value],
      ingredients: ingList,
      calories,
      spicy_level: Number(newDishSpicyLevel.value),
      image_url: newDishImageUrl.value.trim() || undefined,
      is_available: newDishIsAvailable.value,
    });

    emit('dishCreated', created);
    showToast(`Đã thêm món "${created.name}" thành công!`);
    showCreateDishModal.value = false;
  } catch (err: any) {
    showToast(err.message || 'Không thể tạo món ăn');
  } finally {
    newDishSaving.value = false;
  }
}

// ====================================================
// MODAL: SỬA MÓN ĂN
// ====================================================
const showEditDishModal = ref(false);
const editingDish = ref<Dish | null>(null);
const editDishName = ref('');
const editDishPrice = ref(0);
const editDishDesc = ref('');
const editDishCategoryId = ref<number | null>(null);
const editDishMealType = ref<MealType>('all_day');
const editDishIngredients = ref('');
const editDishCalories = ref<number | null>(null);
const editDishSpicyLevel = ref(0);
const editDishImageUrl = ref('');
const editDishIsAvailable = ref(true);
const editDishSaving = ref(false);

function openEditDish(d: Dish) {
  editingDish.value = d;
  editDishName.value = d.name;
  editDishPrice.value = d.price;
  editDishDesc.value = d.description || '';
  editDishCategoryId.value = d.category_id != null ? Number(d.category_id) : null;
  editDishMealType.value = (d.meal_types?.[0] as MealType) || d.meal_type || 'all_day';
  editDishIngredients.value = (d.ingredients || []).join(', ');
  editDishCalories.value = d.calories ?? null;
  editDishSpicyLevel.value = d.spicy_level ?? 0;
  editDishImageUrl.value = d.image_url || '';
  editDishIsAvailable.value = d.is_available ?? true;
  loadMasterIngredients();
  loadIngredientGroups();
  showEditDishModal.value = true;
}

async function handleEditDishSubmit() {
  if (!editingDish.value) return;
  if (!editDishName.value.trim()) {
    showToast('Tên món ăn không được để trống');
    return;
  }
  const priceNum = Number(editDishPrice.value);
  if (isNaN(priceNum) || priceNum < 0) {
    showToast('Đơn giá không được âm');
    return;
  }

  editDishSaving.value = true;
  try {
    const ingList = editDishIngredients.value
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    const calNum = editDishCalories.value != null && String(editDishCalories.value).trim() !== ''
      ? Number(editDishCalories.value)
      : undefined;
    if (calNum !== undefined && (isNaN(calNum) || calNum < 0 || calNum > 20000)) {
      showToast('Lượng calo phải là số từ 0 đến 20,000 kcal');
      editDishSaving.value = false;
      return;
    }
    const calories = calNum !== undefined && !isNaN(calNum) && calNum >= 0 ? calNum : undefined;

    const updated = await api.updateDish(editingDish.value.id, {
      name: editDishName.value.trim(),
      price: priceNum,
      description: editDishDesc.value.trim() || undefined,
      category_id: editDishCategoryId.value ? Number(editDishCategoryId.value) : undefined,
      meal_types: [editDishMealType.value],
      ingredients: ingList,
      calories,
      spicy_level: Number(editDishSpicyLevel.value),
      image_url: editDishImageUrl.value.trim() || undefined,
      is_available: editDishIsAvailable.value,
    });

    emit('dishUpdated', updated);
    showToast(`Đã lưu thay đổi cho món "${updated.name}"!`);
    showEditDishModal.value = false;
  } catch (err: any) {
    showToast(err.message || 'Không thể cập nhật món ăn');
  } finally {
    editDishSaving.value = false;
  }
}

// ====================================================
// CONFIRM: XÓA MÓN ĂN
// ====================================================
const showDeleteDishConfirm = ref(false);
const deletingDish = ref<Dish | null>(null);
const deleteDishLoading = ref(false);

function confirmDeleteDish(d: Dish) {
  deletingDish.value = d;
  showDeleteDishConfirm.value = true;
}

async function handleDeleteDishSubmit() {
  if (!deletingDish.value) return;
  deleteDishLoading.value = true;
  const target = deletingDish.value;
  try {
    await api.deleteDish(target.id);
    emit('dishDeleted', target.id);
    showToast(`Đã xóa món "${target.name}" khỏi thực đơn.`);
    showDeleteDishConfirm.value = false;
  } catch (err: any) {
    showToast(err.message || 'Không thể xóa món ăn');
  } finally {
    deleteDishLoading.value = false;
  }
}


</script>

<template>
  <div class="menus-tab">
    <PageHeader
      title="Thực đơn &amp; Món ăn"
      subtitle="Quản lý thực đơn và phân nhóm theo từng cơ sở ẩm thực"
    >
      <template #actions>
        <button
          type="button"
          class="btn btn-primary"
          :disabled="!selectedRestaurantId"
          aria-label="Thêm món ăn mới"
          @click="openCreateDish"
        >
          <Plus class="btn-icon" />
          <span>Thêm món</span>
        </button>
      </template>
    </PageHeader>

    <!-- Master-Detail 2 Column Split Layout -->
    <div class="split">
      <!-- Cột Trái (270px): Danh sách quán -->
      <div class="card master-pane">
        <label class="srch master-srch" aria-label="Tìm quán ăn">
          <Search class="srch-icon" />
          <input
            v-model="restSearchQuery"
            type="text"
            placeholder="Tìm quán (không dấu)..."
          />
        </label>

        <div ref="masterListScrollEl" class="master-list-scroll">
          <button
            v-for="r in filteredRestaurants"
            :key="r.id"
            type="button"
            class="li"
            :class="{ on: r.id === selectedRestaurantId }"
            @click="emit('selectRestaurant', r.id)"
          >
            <div class="sq">{{ r.name.charAt(0).toUpperCase() }}</div>
            <div class="master-li-info">
              <b>{{ r.name }}</b>
              <small>{{ r.address || 'Chưa cập nhật địa chỉ' }}</small>
            </div>
          </button>

          <div v-if="filteredRestaurants.length === 0" class="master-empty">
            Không tìm thấy quán phù hợp
          </div>
        </div>
      </div>

      <!-- Cột Phải: Thực đơn món của quán đang chọn -->
      <div class="card detail-pane">
        <div v-if="!currentRestaurant" class="empty-detail-guide">
          <UtensilsCrossed class="guide-icon" />
          <h4>Chưa chọn cơ sở quán ăn</h4>
          <p>Vui lòng chọn một quán ăn ở cột bên trái để quản lý danh sách món và thực đơn.</p>
        </div>

        <div v-else class="detail-container">
          <!-- Header quán đang chọn -->
          <div class="pad detail-header">
            <div class="detail-titles">
              <h3>{{ currentRestaurant.name }}</h3>
              <div class="meta-row">
                <span class="meta-item">
                  <MapPin class="inline-icon" />
                  {{ currentRestaurant.address || 'Chưa cập nhật địa chỉ' }}
                </span>
                <span v-if="currentRestaurant.open_time && currentRestaurant.close_time" class="meta-item">
                  <Clock class="inline-icon" />
                  <b>{{ currentRestaurant.open_time }} – {{ currentRestaurant.close_time }}</b>
                </span>
                <span class="meta-item">
                  <b>{{ dishes.length }}</b> món · <b>{{ categories.length }}</b> nhóm
                </span>
              </div>
            </div>
          </div>

          <!-- Thanh Tabs Nhóm món & Tìm món -->
          <div class="menu-filter-bar">
            <!-- Tabs nhóm món -->
            <div class="category-tabs-scroll" role="tablist" aria-label="Nhóm món">
              <button
                type="button"
                class="cat-tab-btn"
                :class="{ on: selectedCategoryId === 'all' }"
                role="tab"
                :aria-selected="selectedCategoryId === 'all'"
                @click="selectedCategoryId = 'all'"
              >
                Tất cả
              </button>

              <button
                v-for="cat in availableCategories"
                :key="cat.id"
                type="button"
                class="cat-tab-btn"
                :class="{ on: selectedCategoryId === cat.id }"
                role="tab"
                :aria-selected="selectedCategoryId === cat.id"
                @click="selectedCategoryId = cat.id"
              >
                {{ cat.name }}
              </button>
            </div>

            <!-- Ô tìm kiếm món ăn -->
            <label class="srch dish-srch" aria-label="Tìm món ăn">
              <Search class="srch-icon" />
              <input
                v-model="dishSearchQuery"
                type="text"
                placeholder="Lọc món theo tên, nguyên liệu..."
              />
            </label>
          </div>

          <!-- Error State -->
          <div v-if="error" class="error-detail-state">
            <p>{{ error }}</p>
            <button type="button" class="btn btn-secondary btn-sm" @click="emit('retry')">
              <RefreshCw class="btn-icon" /> Thử lại
            </button>
          </div>

          <!-- Loading Skeleton -->
          <div v-else-if="loading" class="dishes-skeleton-grid">
            <div v-for="i in 6" :key="i" class="skeleton-dish-card">
              <div class="skeleton-img"></div>
              <div class="skeleton-body">
                <div class="skeleton-line title"></div>
                <div class="skeleton-line desc"></div>
                <div class="skeleton-line chips"></div>
              </div>
            </div>
          </div>

          <!-- Empty State: Quán chưa có món nào -->
          <div v-else-if="dishes.length === 0" class="empty-detail-guide">
            <UtensilsCrossed class="guide-icon" />
            <h4>Quán chưa có món nào</h4>
            <p>Bắt đầu xây dựng thực đơn bằng cách thêm món ăn hoặc tạo nhóm món mới.</p>
            <button type="button" class="btn btn-primary" @click="openCreateDish">
              <Plus class="btn-icon" /> Thêm món đầu tiên
            </button>
          </div>

          <!-- Empty State: Lọc không khớp món -->
          <div v-else-if="filteredDishes.length === 0" class="empty-detail-guide">
            <h4>Không có món ăn nào khớp bộ lọc</h4>
            <p>Thử đổi từ khóa tìm kiếm hoặc chọn nhóm món khác.</p>
            <button
              type="button"
              class="btn btn-secondary btn-sm"
              @click="dishSearchQuery = ''; selectedCategoryId = 'all'"
            >
              Đặt lại bộ lọc
            </button>
          </div>

          <!-- Lưới card món ăn -->
          <div v-else class="dishes-grid">
            <div
              v-for="d in filteredDishes"
              :key="d.id"
              class="dish-card"
              :class="{ unavailable: !d.is_available }"
            >
              <!-- Khung ảnh phía trên -->
              <div class="dish-photo-frame">
                <img
                  v-if="d.image_url && !failedImageMap[d.id]"
                  :src="d.image_url"
                  :alt="d.name"
                  class="dish-photo-img"
                  loading="lazy"
                  @error="handleImageError(d.id)"
                />
                <ImageIcon v-else class="dish-photo-placeholder" />

                <!-- Chip hết món -->
                <span v-if="!d.is_available" class="stock-badge">
                  Hết món
                </span>
              </div>

              <!-- Nội dung món -->
              <div class="dish-card-body">
                <h4 class="dish-title">{{ d.name }}</h4>
                <p class="dish-desc">
                  {{ d.description || 'Đặc sản chuẩn vị được chế biến tươi mỗi ngày tại cơ sở.' }}
                </p>

                <!-- 1 hàng chip: Nhóm bữa, kcal, độ cay -->
                <div class="dish-chips-row">
                  <Chip>
                    {{ getMealTypeLabel(d.meal_types?.[0] || d.meal_type) }}
                  </Chip>
                  <Chip v-if="d.calories">
                    {{ d.calories }} kcal
                  </Chip>
                  <Chip :variant="d.spicy_level && d.spicy_level > 0 ? 'warn' : 'default'">
                    {{ getSpicyLabel(d.spicy_level) }}
                  </Chip>
                </div>

                <!-- Footer thẻ: Đơn giá & Thao tác -->
                <div class="dish-card-footer">
                  <span class="dish-price">
                    {{ d.price.toLocaleString('vi-VN') }} đ
                  </span>

                  <div class="dish-actions">
                    <button
                      type="button"
                      class="dish-action-btn"
                      aria-label="Sửa món ăn"
                      @click="openEditDish(d)"
                    >
                      <Edit class="dish-action-icon" />
                    </button>
                    <button
                      type="button"
                      class="dish-action-btn danger-btn"
                      aria-label="Xóa món ăn"
                      @click="confirmDeleteDish(d)"
                    >
                      <Trash2 class="dish-action-icon" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- BaseModal: Thêm món ăn mới -->
    <BaseModal
      v-model="showCreateDishModal"
      title="Thêm món ăn mới"
      subtitle="Bổ sung món vào thực đơn của quán"
      max-width="540px"
      :close-on-backdrop="false"
      :prevent-close="newDishSaving"
    >
      <form id="createDishForm" @submit.prevent="handleCreateDishSubmit">
        <div class="form-group">
          <label class="form-label">Tên món ăn *</label>
          <input
            v-model="newDishName"
            type="text"
            class="form-input"
            placeholder="Ví dụ: Bún chả nướng than hoa"
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Đơn giá (VNĐ) *</label>
            <input
              v-model.number="newDishPrice"
              type="number"
              min="0"
              step="1000"
              class="form-input"
              required
            />
          </div>
          <div class="form-group">
            <label class="form-label">Nhóm món</label>
            <select v-model="newDishCategoryId" class="form-input">
              <option :value="null">-- Chưa phân loại --</option>
              <option
                v-for="c in availableCategories"
                :key="c.id"
                :value="c.id"
              >
                {{ c.name }}
              </option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Bữa ăn phục vụ</label>
            <select v-model="newDishMealType" class="form-input">
              <option value="all_day">Cả ngày</option>
              <option value="breakfast">Bữa sáng</option>
              <option value="lunch">Bữa trưa</option>
              <option value="dinner">Bữa tối</option>
              <option value="snack">Ăn vặt</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Lượng Calo (kcal)</label>
            <input
              v-model.number="newDishCalories"
              type="number"
              min="0"
              class="form-input"
              placeholder="Ví dụ: 350"
            />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Mức độ cay</label>
            <select v-model.number="newDishSpicyLevel" class="form-input">
              <option :value="0">Không cay</option>
              <option :value="1">Cay nhẹ</option>
              <option :value="2">Cay vừa</option>
              <option :value="3">Cay nhiều</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Tình trạng phục vụ</label>
            <select v-model="newDishIsAvailable" class="form-input">
              <option :value="true">Còn hàng (Sẵn sàng)</option>
              <option :value="false">Hết món (Tạm hết)</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Đường dẫn ảnh món (Image URL)</label>
          <input
            v-model="newDishImageUrl"
            type="url"
            class="form-input"
            placeholder="https://..."
          />
        </div>

        <div class="form-group">
          <label class="form-label">Nguyên liệu &amp; Gia vị (Gợi ý thông minh)</label>
          <IngredientInput
            v-model="newDishIngredients"
            :dish-name="newDishName"
            :available-ingredients="masterIngredients"
            :ingredient-groups="ingredientGroups"
            placeholder="Tìm trong danh mục hoặc gõ tên mới rồi nhấn Enter..."
          />
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả món ăn</label>
          <textarea
            v-model="newDishDesc"
            class="form-input"
            rows="2"
            placeholder="Hương vị, định lượng, ghi chú..."
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="newDishSaving"
          @click="showCreateDishModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="createDishForm"
          class="btn btn-primary"
          :disabled="newDishSaving"
        >
          {{ newDishSaving ? 'Đang tạo...' : 'Tạo món ăn' }}
        </button>
      </template>
    </BaseModal>

    <!-- BaseModal: Sửa món ăn -->
    <BaseModal
      v-model="showEditDishModal"
      :title="`Sửa món: ${editingDish?.name || ''}`"
      subtitle="Cập nhật thông tin chi tiết và nguyên liệu món ăn"
      max-width="540px"
      :close-on-backdrop="false"
      :prevent-close="editDishSaving"
    >
      <form id="editDishForm" @submit.prevent="handleEditDishSubmit">
        <div class="form-group">
          <label class="form-label">Tên món ăn *</label>
          <input
            v-model="editDishName"
            type="text"
            class="form-input"
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Đơn giá (VNĐ) *</label>
            <input
              v-model.number="editDishPrice"
              type="number"
              min="0"
              step="1000"
              class="form-input"
              required
            />
          </div>
          <div class="form-group">
            <label class="form-label">Nhóm món</label>
            <select v-model="editDishCategoryId" class="form-input">
              <option :value="null">-- Chưa phân loại --</option>
              <option
                v-for="c in availableCategories"
                :key="c.id"
                :value="c.id"
              >
                {{ c.name }}
              </option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Bữa ăn phục vụ</label>
            <select v-model="editDishMealType" class="form-input">
              <option value="all_day">Cả ngày</option>
              <option value="breakfast">Bữa sáng</option>
              <option value="lunch">Bữa trưa</option>
              <option value="dinner">Bữa tối</option>
              <option value="snack">Ăn vặt</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Lượng Calo (kcal)</label>
            <input
              v-model.number="editDishCalories"
              type="number"
              min="0"
              class="form-input"
            />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Mức độ cay</label>
            <select v-model.number="editDishSpicyLevel" class="form-input">
              <option :value="0">Không cay</option>
              <option :value="1">Cay nhẹ</option>
              <option :value="2">Cay vừa</option>
              <option :value="3">Cay nhiều</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Tình trạng phục vụ</label>
            <select v-model="editDishIsAvailable" class="form-input">
              <option :value="true">Còn hàng (Sẵn sàng)</option>
              <option :value="false">Hết món (Tạm hết)</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Đường dẫn ảnh món (Image URL)</label>
          <input
            v-model="editDishImageUrl"
            type="url"
            class="form-input"
          />
        </div>

        <!-- Tag nguyên liệu hiển thị đầy đủ trong modal sửa -->
        <div class="form-group">
          <label class="form-label">Nguyên liệu &amp; Gia vị (Gợi ý thông minh)</label>
          <IngredientInput
            v-model="editDishIngredients"
            :dish-name="editDishName"
            :available-ingredients="masterIngredients"
            :ingredient-groups="ingredientGroups"
            placeholder="Tìm trong danh mục hoặc gõ tên mới rồi nhấn Enter..."
          />
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả món ăn</label>
          <textarea
            v-model="editDishDesc"
            class="form-input"
            rows="2"
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="editDishSaving"
          @click="showEditDishModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="editDishForm"
          class="btn btn-primary"
          :disabled="editDishSaving"
        >
          {{ editDishSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
        </button>
      </template>
    </BaseModal>

    <!-- ConfirmDialog: Xóa món ăn -->
    <ConfirmDialog
      v-model="showDeleteDishConfirm"
      title="Xác nhận xóa món ăn"
      :message="`Bạn có chắc chắn muốn xóa món '${deletingDish?.name}' khỏi thực đơn của quán?`"
      confirm-text="Xóa món"
      cancel-text="Hủy"
      :danger="true"
      :loading="deleteDishLoading"
      @confirm="handleDeleteDishSubmit"
    />


  </div>
</template>

<style scoped>
.menus-tab {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.btn-icon {
  width: 15px;
  height: 15px;
}

.srch-icon {
  width: 15px;
  height: 15px;
  color: var(--mut);
  flex: none;
}

/* Master-detail split */
.split {
  display: grid;
  grid-template-columns: 270px 1fr;
  gap: 14px;
  align-items: start;
}

/* Master pane (left) */
.master-pane {
  display: flex;
  flex-direction: column;
  padding: 10px;
  gap: 8px;
}

.master-srch {
  max-width: 100%;
  width: 100%;
}

.master-list-scroll {
  display: flex;
  flex-direction: column;
  gap: 3px;
  max-height: 560px;
  overflow-y: auto;
  padding-right: 2px;
}

.li {
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 8px 10px;
  border-radius: 8px;
  border: 1px solid transparent;
  background: none;
  text-align: left;
  transition: all 0.15s ease;
  cursor: pointer;
  width: 100%;
}

.li:hover {
  background: var(--bg);
}

.li.on {
  background: var(--pri-s);
  color: var(--pri);
  font-weight: 600;
  border-color: color-mix(in srgb, var(--pri) 25%, transparent);
}

.master-li-info {
  min-width: 0;
  flex: 1;
}

.master-li-info b {
  display: block;
  font-size: 13.5px;
  line-height: 1.3;
  color: var(--ink);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.master-li-info small {
  color: var(--mut);
  font-size: 11.5px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  display: block;
  margin-top: 2px;
}

.li.on .master-li-info small {
  color: var(--pri);
  opacity: 0.85;
}

.master-empty {
  padding: 24px 12px;
  text-align: center;
  color: var(--mut);
  font-size: 13px;
}

/* Detail pane (right) */
.detail-pane {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.empty-detail-guide {
  padding: 56px 20px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  color: var(--mut);
}

.guide-icon {
  width: 44px;
  height: 44px;
  color: var(--pri);
  opacity: 0.6;
  margin-bottom: 4px;
}

.empty-detail-guide h4 {
  margin: 0;
  color: var(--ink);
  font-size: 16px;
}

.empty-detail-guide p {
  margin: 0;
  font-size: 13.5px;
  max-width: 420px;
}

.detail-header {
  border-bottom: 1px solid var(--line);
  padding-bottom: 14px;
}

.detail-titles h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--ink);
}

.meta-row {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
  align-items: center;
  margin-top: 6px;
  font-size: 12.5px;
  color: var(--mut);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.inline-icon {
  width: 13px;
  height: 13px;
  flex: none;
}

/* Filter bar */
.menu-filter-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  padding: 12px 16px;
  border-bottom: 1px solid var(--line);
  background: color-mix(in srgb, var(--bg) 60%, transparent);
}

.category-tabs-scroll {
  display: flex;
  gap: 6px;
  align-items: center;
  overflow-x: auto;
  padding: 2px 0;
}

.cat-tab-item {
  display: flex;
  align-items: center;
  gap: 3px;
}

.cat-tab-btn {
  border: 1px solid var(--line);
  background: var(--card);
  padding: 5px 12px;
  border-radius: 99px;
  font-size: 12.5px;
  font-weight: 500;
  color: var(--mut);
  white-space: nowrap;
  transition: all 0.15s ease;
}

.cat-tab-btn:hover {
  border-color: var(--pri);
  color: var(--ink);
}

.cat-tab-btn.on {
  background: var(--pri);
  border-color: var(--pri);
  color: #fff;
  font-weight: 600;
}

.dish-srch {
  max-width: 280px;
}

/* Error state */
.error-detail-state {
  padding: 32px 16px;
  text-align: center;
  color: var(--bad);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

/* Dishes grid */
.dishes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 14px;
  padding: 16px;
}

.dish-card {
  border: 1px solid var(--line);
  border-radius: 12px;
  overflow: hidden;
  background: var(--card);
  display: flex;
  flex-direction: column;
  transition: all 0.15s ease;
}

.dish-card:hover {
  border-color: var(--pri);
  box-shadow: var(--sh);
}

.dish-card.unavailable .dish-photo-frame,
.dish-card.unavailable .dish-title,
.dish-card.unavailable .dish-desc,
.dish-card.unavailable .dish-chips-row {
  opacity: 0.6;
}

.dish-photo-frame {
  height: 140px;
  background: var(--bg);
  display: grid;
  place-items: center;
  color: var(--mut);
  position: relative;
  overflow: hidden;
}

.dish-photo-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.dish-photo-placeholder {
  width: 36px;
  height: 36px;
  opacity: 0.4;
}

.stock-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  background: rgba(20, 32, 30, 0.85);
  color: #fff;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 99px;
  font-weight: 600;
}

.dish-card-body {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.dish-title {
  margin: 0;
  font-size: 14px;
  font-weight: 700;
  color: var(--ink);
  line-height: 1.3;
}

.dish-desc {
  margin: 0;
  color: var(--mut);
  font-size: 12px;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.dish-chips-row {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
  margin-top: 2px;
}

.dish-card-footer {
  margin-top: auto;
  padding-top: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid var(--line);
}

.dish-price {
  font-size: 15px;
  font-weight: 700;
  color: var(--pri);
  font-variant-numeric: tabular-nums;
}

.dish-actions {
  display: flex;
  gap: 5px;
}

.dish-action-btn {
  border: 1px solid var(--line);
  background: var(--card);
  border-radius: 6px;
  padding: 5px;
  color: var(--mut);
  display: grid;
  place-items: center;
  transition: all 0.15s ease;
}

.dish-action-btn:hover {
  background: var(--bg);
  color: var(--ink);
  border-color: var(--pri);
}

.dish-action-btn.danger-btn {
  color: var(--bad);
}

.dish-action-btn.danger-btn:hover {
  background: var(--bad-s);
  border-color: var(--bad);
}

.dish-action-icon {
  width: 14px;
  height: 14px;
}

/* Skeleton Loading */
.dishes-skeleton-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 14px;
  padding: 16px;
}

.skeleton-dish-card {
  border: 1px solid var(--line);
  border-radius: 12px;
  overflow: hidden;
  background: var(--card);
}

.skeleton-img {
  height: 140px;
  background: var(--bg);
  animation: pulse 1.2s infinite ease-in-out;
}

.skeleton-body {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.skeleton-line {
  background: var(--bg);
  border-radius: 4px;
  height: 12px;
  animation: pulse 1.2s infinite ease-in-out;
}

.skeleton-line.title {
  width: 70%;
  height: 16px;
}

.skeleton-line.desc {
  width: 90%;
}

.skeleton-line.chips {
  width: 50%;
}

@keyframes pulse {
  0%, 100% {
    opacity: 0.6;
  }
  50% {
    opacity: 0.3;
  }
}

@media (prefers-reduced-motion: reduce) {
  .skeleton-img,
  .skeleton-line {
    animation: none;
    opacity: 0.4;
  }
}

/* Form layout */
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

@media (max-width: 860px) {
  .split {
    grid-template-columns: 1fr;
  }
  .master-list-scroll {
    max-height: 240px;
  }
  .menu-filter-bar {
    flex-direction: column;
    align-items: stretch;
  }
  .dish-srch {
    max-width: 100%;
  }
}
</style>
