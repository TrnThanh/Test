<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse, Restaurant, Category, Dish, MealType } from '../types';
import { api } from '../services/api';

const props = defineProps<{
  seller: RoleLoginResponse;
}>();

const restaurants = ref<Restaurant[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const successMsg = ref<string | null>(null);

// Form state for Restaurant Create / Edit
const showFormModal = ref(false);
const editingId = ref<number | null>(null);
const formName = ref('');
const formAddress = ref('');
const formPhone = ref('');
const formDesc = ref('');
const formOpenTime = ref('');
const formCloseTime = ref('');
const formLat = ref(21.0285);
const formLon = ref(105.8542);
const formLoading = ref(false);
const formError = ref<string | null>(null);

// Menu & Category Management Modal State
const showMenuModal = ref(false);
const activeMenuRestaurant = ref<Restaurant | null>(null);
const menuTab = ref<'dishes' | 'categories'>('dishes');
const categories = ref<Category[]>([]);
const dishes = ref<Dish[]>([]);
const menuLoading = ref(false);
const menuError = ref<string | null>(null);

// Category Form State
const catName = ref('');
const catDesc = ref('');
const catOrder = ref(0);
const catLoading = ref(false);

// Dish Form State
const dishEditingId = ref<number | null>(null);
const dishName = ref('');
const dishPrice = ref<number>(30000);
const dishCategoryId = ref<number | null>(null);
const dishMealType = ref<MealType>('all_day');
const dishIngredients = ref('');
const dishDesc = ref('');
const dishAvailable = ref(true);
const dishLoading = ref(false);
const showDishForm = ref(false);

async function loadSellerRestaurants() {
  loading.value = true;
  error.value = null;
  try {
    restaurants.value = await api.getSellerRestaurants(props.seller.id);
  } catch (err: any) {
    error.value = err.message || 'Không thể tải danh sách quán của bạn';
  } finally {
    loading.value = false;
  }
}

function openCreateModal() {
  editingId.value = null;
  formName.value = '';
  formAddress.value = '';
  formPhone.value = props.seller.phone || '';
  formDesc.value = '';
  formOpenTime.value = '';
  formCloseTime.value = '';
  formLat.value = 21.0285;
  formLon.value = 105.8542;
  formError.value = null;
  showFormModal.value = true;
}

function openEditModal(restaurant: Restaurant) {
  editingId.value = restaurant.id;
  formName.value = restaurant.name;
  formAddress.value = restaurant.address || '';
  formPhone.value = restaurant.phone || '';
  formDesc.value = restaurant.description || '';
  formOpenTime.value = restaurant.open_time || '';
  formCloseTime.value = restaurant.close_time || '';
  formLat.value = restaurant.latitude;
  formLon.value = restaurant.longitude;
  formError.value = null;
  showFormModal.value = true;
}

async function handleSaveRestaurant() {
  formLoading.value = true;
  formError.value = null;

  try {
    if (editingId.value == null) {
      await api.createSellerRestaurant(props.seller.id, {
        name: formName.value,
        address: formAddress.value || undefined,
        phone: formPhone.value || undefined,
        description: formDesc.value || undefined,
        open_time: formOpenTime.value || null,
        close_time: formCloseTime.value || null,
        latitude: formLat.value,
        longitude: formLon.value,
      });
      successMsg.value = 'Tạo quán ăn mới thành công!';
    } else {
      await api.updateSellerRestaurant(props.seller.id, editingId.value, {
        name: formName.value,
        address: formAddress.value || undefined,
        phone: formPhone.value || undefined,
        description: formDesc.value || undefined,
        open_time: formOpenTime.value || null,
        close_time: formCloseTime.value || null,
        latitude: formLat.value,
        longitude: formLon.value,
      });
      successMsg.value = 'Cập nhật thông tin quán thành công!';
    }

    showFormModal.value = false;
    await loadSellerRestaurants();
    setTimeout(() => (successMsg.value = null), 4000);
  } catch (err: any) {
    formError.value = err.message || 'Thao tác không thành công';
  } finally {
    formLoading.value = false;
  }
}

async function handleDelete(restaurant: Restaurant) {
  const confirmDelete = window.confirm(
    `Bạn có chắc chắn muốn xoá quán "${restaurant.name}" không?\nHành động này không thể hoàn tác.`
  );
  if (!confirmDelete) return;

  try {
    await api.deleteSellerRestaurant(props.seller.id, restaurant.id);
    successMsg.value = `Đã xoá quán "${restaurant.name}" thành công!`;
    await loadSellerRestaurants();
    setTimeout(() => (successMsg.value = null), 4000);
  } catch (err: any) {
    alert(err.message || 'Xoá quán thất bại');
  }
}

// Menu Management Methods
async function openMenuModal(restaurant: Restaurant) {
  activeMenuRestaurant.value = restaurant;
  menuTab.value = 'dishes';
  showDishForm.value = false;
  dishEditingId.value = null;
  showMenuModal.value = true;
  await loadRestaurantMenu();
}

async function loadRestaurantMenu() {
  if (!activeMenuRestaurant.value) return;
  menuLoading.value = true;
  menuError.value = null;
  try {
    const [cats, dishList] = await Promise.all([
      api.getRestaurantCategories(activeMenuRestaurant.value.id),
      api.getRestaurantDishes(activeMenuRestaurant.value.id),
    ]);
    categories.value = cats;
    dishes.value = dishList;
  } catch (err: any) {
    menuError.value = err.message || 'Không thể tải thực đơn quán';
  } finally {
    menuLoading.value = false;
  }
}

async function handleAddCategory() {
  if (!activeMenuRestaurant.value || !catName.value.trim()) return;
  catLoading.value = true;
  try {
    await api.createCategory(props.seller.id, activeMenuRestaurant.value.id, {
      name: catName.value.trim(),
      description: catDesc.value.trim() || undefined,
      display_order: catOrder.value,
    });
    catName.value = '';
    catDesc.value = '';
    catOrder.value = 0;
    await loadRestaurantMenu();
  } catch (err: any) {
    alert(err.message || 'Thêm danh mục thất bại');
  } finally {
    catLoading.value = false;
  }
}

async function handleDeleteCategory(category: Category) {
  const ok = window.confirm(`Xoá danh mục "${category.name}"? Các món trong danh mục sẽ chuyển thành Chưa phân loại.`);
  if (!ok) return;
  try {
    await api.deleteCategory(props.seller.id, category.id);
    await loadRestaurantMenu();
  } catch (err: any) {
    alert(err.message || 'Xoá danh mục thất bại');
  }
}

function openAddDishForm() {
  dishEditingId.value = null;
  dishName.value = '';
  dishPrice.value = 35000;
  dishCategoryId.value = categories.value.length > 0 ? categories.value[0].id : null;
  dishMealType.value = 'all_day';
  dishIngredients.value = '';
  dishDesc.value = '';
  dishAvailable.value = true;
  showDishForm.value = true;
}

function openEditDishForm(dish: Dish) {
  dishEditingId.value = dish.id;
  dishName.value = dish.name;
  dishPrice.value = dish.price;
  dishCategoryId.value = dish.category_id || null;
  dishMealType.value = dish.meal_type;
  dishIngredients.value = (dish.ingredients || []).join(', ');
  dishDesc.value = dish.description || '';
  dishAvailable.value = dish.is_available;
  showDishForm.value = true;
}

async function handleSaveDish() {
  if (!activeMenuRestaurant.value || !dishName.value.trim()) return;
  dishLoading.value = true;
  const ingredientsArr = dishIngredients.value
    ? dishIngredients.value.split(',').map((t) => t.trim()).filter((t) => t.length > 0)
    : [];

  try {
    if (dishEditingId.value == null) {
      await api.createDish(props.seller.id, activeMenuRestaurant.value.id, {
        name: dishName.value.trim(),
        price: Number(dishPrice.value),
        category_id: dishCategoryId.value || undefined,
        meal_type: dishMealType.value,
        ingredients: ingredientsArr,
        description: dishDesc.value.trim() || undefined,
        is_available: dishAvailable.value,
      });
    } else {
      await api.updateDish(props.seller.id, dishEditingId.value, {
        name: dishName.value.trim(),
        price: Number(dishPrice.value),
        category_id: dishCategoryId.value ?? undefined,
        meal_type: dishMealType.value,
        ingredients: ingredientsArr,
        description: dishDesc.value.trim() || undefined,
        is_available: dishAvailable.value,
      });
    }
    showDishForm.value = false;
    await loadRestaurantMenu();
  } catch (err: any) {
    alert(err.message || 'Lưu món ăn thất bại');
  } finally {
    dishLoading.value = false;
  }
}

async function handleDeleteDish(dish: Dish) {
  const ok = window.confirm(`Xoá món "${dish.name}" khỏi thực đơn?`);
  if (!ok) return;
  try {
    await api.deleteDish(props.seller.id, dish.id);
    await loadRestaurantMenu();
  } catch (err: any) {
    alert(err.message || 'Xoá món thất bại');
  }
}

function formatPrice(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
}

onMounted(() => {
  loadSellerRestaurants();
});
</script>

<template>
  <div class="seller-dashboard">
    <div class="dashboard-header">
      <div>
        <h2>Quản lý quán ăn của bạn</h2>
        <p>
          Chủ quán: <strong>{{ seller.shop_name || seller.full_name }}</strong> (ID: {{ seller.id }})
        </p>
      </div>

      <button type="button" class="btn btn-primary" @click="openCreateModal">
        Thêm quán ăn mới
      </button>
    </div>

    <!-- Success banner -->
    <div v-if="successMsg" class="alert alert-success">
      {{ successMsg }}
    </div>

    <!-- Error banner -->
    <div v-if="error" class="alert alert-error">
      {{ error }}
      <button type="button" class="btn btn-sm btn-outline" style="margin-left: auto;" @click="loadSellerRestaurants">
        Tải lại
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="state-box">
      <div class="spinner"></div>
      <p style="margin-top: 12px;">Đang tải danh sách quán ăn của bạn...</p>
    </div>

    <!-- Empty state -->
    <div v-else-if="restaurants.length === 0" class="state-box">
      <h3>Bạn chưa đăng ký quán ăn nào</h3>
      <p>Hãy bắt đầu bằng cách thêm quán ăn đầu tiên của bạn vào hệ thống bản đồ.</p>
      <button type="button" class="btn btn-primary" style="margin-top: 16px;" @click="openCreateModal">
        Thêm quán ăn ngay
      </button>
    </div>

    <!-- Restaurants Table / Cards -->
    <div v-else class="grid">
      <div
        v-for="r in restaurants"
        :key="r.id"
        class="card seller-card"
      >
        <div class="seller-card-header">
          <h3 class="name">{{ r.name }}</h3>
          <span class="badge" :class="r.is_active ? 'badge-primary' : 'badge-danger'">
            {{ r.is_active ? 'Đang hoạt động' : 'Tạm dừng' }}
          </span>
        </div>

        <p v-if="r.address" class="meta">Địa chỉ: {{ r.address }}</p>
        <p v-if="r.phone" class="meta">Hotline: {{ r.phone }}</p>
        <p v-if="r.open_time && r.close_time" class="meta">Giờ mở cửa: {{ r.open_time }} – {{ r.close_time }}</p>
        <p v-if="r.description" class="desc">{{ r.description }}</p>

        <div class="coords">
          Toạ độ: <code>{{ r.latitude }}, {{ r.longitude }}</code>
        </div>

        <div class="actions">
          <button type="button" class="btn btn-primary btn-sm" @click="openMenuModal(r)">
            Quản lý thực đơn
          </button>
          <button type="button" class="btn btn-outline btn-sm" @click="openEditModal(r)">
            Sửa
          </button>
          <button type="button" class="btn btn-danger btn-sm" @click="handleDelete(r)">
            Xoá
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Form Create / Edit Restaurant -->
    <div v-if="showFormModal" class="modal-overlay" @click.self="showFormModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingId == null ? 'Thêm Quán Ăn Mới' : 'Cập Nhật Quán Ăn' }}</h3>
          <button type="button" class="modal-close" @click="showFormModal = false">×</button>
        </div>

        <div v-if="formError" class="alert alert-error">
          ⚠️ {{ formError }}
        </div>

        <form class="form" @submit.prevent="handleSaveRestaurant">
          <div class="form-group">
            <label class="label">Tên quán ăn *</label>
            <input v-model="formName" type="text" class="input" placeholder="Ví dụ: Phở Bát Đàn" required />
          </div>

          <div class="form-group">
            <label class="label">Địa chỉ</label>
            <input v-model="formAddress" type="text" class="input" placeholder="49 Bát Đàn, Hoàn Kiếm, Hà Nội" />
          </div>

          <div class="form-group">
            <label class="label">Hotline</label>
            <input v-model="formPhone" type="text" class="input" placeholder="0901234567" />
          </div>

          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
            <div class="form-group">
              <label class="label">Giờ mở cửa</label>
              <input v-model="formOpenTime" type="time" class="input" />
            </div>
            <div class="form-group">
              <label class="label">Giờ đóng cửa</label>
              <input v-model="formCloseTime" type="time" class="input" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label class="label">Vĩ độ (Latitude) *</label>
              <input v-model.number="formLat" type="number" step="any" class="input" required />
            </div>
            <div class="form-group">
              <label class="label">Kinh độ (Longitude) *</label>
              <input v-model.number="formLon" type="number" step="any" class="input" required />
            </div>
          </div>

          <div class="form-group">
            <label class="label">Mô tả quán</label>
            <textarea v-model="formDesc" class="input textarea" rows="2" placeholder="Giới thiệu đôi nét về quán..."></textarea>
          </div>

          <div class="form-actions">
            <button type="button" class="btn btn-outline" @click="showFormModal = false">
              Hủy
            </button>
            <button type="submit" class="btn btn-primary" :disabled="formLoading">
              {{ formLoading ? 'Đang lưu...' : (editingId == null ? 'Tạo Quán' : 'Cập Nhật') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal Menu & Category Management -->
    <div v-if="showMenuModal && activeMenuRestaurant" class="modal-overlay" @click.self="showMenuModal = false">
      <div class="modal-content menu-modal">
        <div class="modal-header">
          <div>
            <h3>Quản lý thực đơn — {{ activeMenuRestaurant.name }}</h3>
            <p style="font-size: 0.85rem; color: var(--c-text-muted);">
              Cập nhật nhóm danh mục và món ăn trực tiếp vào cơ sở dữ liệu PostgreSQL
            </p>
          </div>
          <button type="button" class="modal-close" @click="showMenuModal = false">×</button>
        </div>

        <!-- Menu Tabs -->
        <div class="tab-buttons" style="margin: 12px 0;">
          <button
            type="button"
            class="tab-btn"
            :class="{ active: menuTab === 'dishes' }"
            @click="menuTab = 'dishes'"
          >
            Món ăn ({{ dishes.length }})
          </button>
          <button
            type="button"
            class="tab-btn"
            :class="{ active: menuTab === 'categories' }"
            @click="menuTab = 'categories'"
          >
            Nhóm danh mục ({{ categories.length }})
          </button>
        </div>

        <div v-if="menuLoading" class="state-box" style="padding: 20px 0;">
          <div class="spinner"></div>
          <p style="margin-top: 12px;">Đang tải dữ liệu thực đơn...</p>
        </div>

        <div v-else-if="menuError" class="alert alert-error">
          {{ menuError }}
        </div>

        <!-- TAB DISHES -->
        <div v-else-if="menuTab === 'dishes'" class="menu-tab-content">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
            <span style="font-weight: 600;">Danh sách món ăn</span>
            <button type="button" class="btn btn-primary btn-sm" @click="openAddDishForm">
              Thêm món mới
            </button>
          </div>

          <!-- Dish Form Modal / Inlined -->
          <div v-if="showDishForm" class="dish-form-box">
            <h4 style="margin-bottom: 10px;">{{ dishEditingId == null ? 'Thêm món ăn mới' : 'Chỉnh sửa món ăn' }}</h4>
            <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 10px;">
              <div class="form-group">
                <label class="label">Tên món *</label>
                <input v-model="dishName" type="text" class="input" placeholder="Cơm tấm sườn bì" required />
              </div>
              <div class="form-group">
                <label class="label">Giá bán (VNĐ) *</label>
                <input v-model.number="dishPrice" type="number" step="1000" min="0" class="input" required />
              </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
              <div class="form-group">
                <label class="label">Nhóm danh mục (Category)</label>
                <select v-model="dishCategoryId" class="input">
                  <option :value="null">-- Chưa phân loại --</option>
                  <option v-for="c in categories" :key="c.id" :value="c.id">
                    {{ c.name }}
                  </option>
                </select>
              </div>
              <div class="form-group">
                <label class="label">Bữa ăn (Meal Type)</label>
                <select v-model="dishMealType" class="input">
                  <option value="all_day">Cả ngày (all_day)</option>
                  <option value="breakfast">Bữa sáng (breakfast)</option>
                  <option value="lunch">Bữa trưa (lunch)</option>
                  <option value="dinner">Bữa tối (dinner)</option>
                  <option value="snack">Ăn vặt (snack)</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label class="label">Nguyên liệu chính (cách nhau bởi dấu phẩy)</label>
              <input v-model="dishIngredients" type="text" class="input" placeholder="Thịt bò, Bánh phở, Hành hoa" />
            </div>

            <div class="form-group">
              <label class="label">Mô tả món ăn</label>
              <input v-model="dishDesc" type="text" class="input" placeholder="Nguyên liệu, hương vị..." />
            </div>

            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 12px;">
              <input id="dishAvail" v-model="dishAvailable" type="checkbox" />
              <label for="dishAvail" style="font-size: 0.9rem;">Đang còn món phục vụ</label>
            </div>

            <div style="display: flex; gap: 8px; justify-content: flex-end;">
              <button type="button" class="btn btn-outline btn-sm" @click="showDishForm = false">Hủy</button>
              <button type="button" class="btn btn-primary btn-sm" :disabled="dishLoading" @click="handleSaveDish">
                {{ dishLoading ? 'Đang lưu...' : 'Lưu món' }}
              </button>
            </div>
          </div>

          <!-- Dishes list -->
          <div v-if="dishes.length === 0" class="state-box" style="padding: 16px 0;">
            <p>Quán chưa có món ăn nào. Hãy thêm món đầu tiên!</p>
          </div>
          <div v-else class="dish-admin-list">
            <div v-for="d in dishes" :key="d.id" class="dish-admin-row">
              <div class="dish-admin-info">
                <strong>{{ d.name }}</strong>
                <span class="price">{{ formatPrice(d.price) }}</span>
                <span v-if="d.category_name || d.category" class="badge badge-info">
                  {{ d.category_name || d.category }}
                </span>
                <span class="badge badge-info">{{ d.meal_type }}</span>
                <span v-if="!d.is_available" class="badge badge-danger">Tạm hết</span>
              </div>
              <div class="dish-admin-actions">
                <button type="button" class="btn btn-outline btn-sm" @click="openEditDishForm(d)">Sửa</button>
                <button type="button" class="btn btn-danger btn-sm" @click="handleDeleteDish(d)">Xoá</button>
              </div>
            </div>
          </div>
        </div>

        <!-- TAB CATEGORIES -->
        <div v-else class="menu-tab-content">
          <div class="category-add-box">
            <h4 style="margin-bottom: 8px;">Thêm nhóm danh mục mới</h4>
            <div style="display: grid; grid-template-columns: 2fr 1fr auto; gap: 10px; align-items: flex-end;">
              <div class="form-group" style="margin-bottom: 0;">
                <label class="label">Tên danh mục *</label>
                <input v-model="catName" type="text" class="input" placeholder="Ví dụ: Đồ uống, Món xào" />
              </div>
              <div class="form-group" style="margin-bottom: 0;">
                <label class="label">Thứ tự hiển thị</label>
                <input v-model.number="catOrder" type="number" class="input" placeholder="0" />
              </div>
              <button type="button" class="btn btn-primary btn-sm" :disabled="catLoading || !catName.trim()" @click="handleAddCategory">
                {{ catLoading ? 'Đang thêm...' : 'Thêm' }}
              </button>
            </div>
          </div>

          <div style="margin-top: 16px;">
            <h4 style="margin-bottom: 10px;">Các danh mục hiện có</h4>
            <div v-if="categories.length === 0" class="state-box" style="padding: 16px 0;">
              <p>Chưa có danh mục nào. Thêm danh mục để phân loại món ăn dễ dàng hơn.</p>
            </div>
            <div v-else class="category-list">
              <div v-for="c in categories" :key="c.id" class="category-row">
                <div>
                  <strong>{{ c.name }}</strong>
                  <span style="font-size: 0.85rem; color: var(--c-text-muted); margin-left: 8px;">
                    Thứ tự: {{ c.display_order }} • {{ c.dish_count || 0 }} món
                  </span>
                </div>
                <button type="button" class="btn btn-danger btn-sm" @click="handleDeleteCategory(c)">
                  Xoá
                </button>
              </div>
            </div>
          </div>
        </div>

        <div style="margin-top: 16px; text-align: right;">
          <button type="button" class="btn btn-secondary btn-sm" @click="showMenuModal = false">
            Đóng
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.seller-dashboard {
  max-width: 1000px;
  margin: 0 auto;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 24px;
}

.seller-card {
  display: flex;
  flex-direction: column;
}

.seller-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.seller-card .name {
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--c-text);
}

.seller-card .meta {
  font-size: 0.9rem;
  color: var(--c-text-muted);
  margin-bottom: 4px;
}

.seller-card .desc {
  font-size: 0.9rem;
  color: var(--c-text);
  margin: 8px 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.seller-card .coords {
  margin-top: auto;
  padding-top: 10px;
  font-size: 0.8rem;
  color: var(--c-text-muted);
}

.seller-card .actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
  flex-wrap: wrap;
}

.menu-modal {
  max-width: 720px;
  width: 95%;
  max-height: 88vh;
  overflow-y: auto;
}

.tab-buttons {
  display: flex;
  gap: 8px;
  border-bottom: 1px solid var(--c-border);
  padding-bottom: 8px;
}

.tab-btn {
  background: none;
  border: none;
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--c-text-muted);
  cursor: pointer;
  padding: 6px 12px;
  border-radius: 6px;
  transition: all 0.15s;
}

.tab-btn.active {
  background: #000000;
  color: #ffffff;
}

.dish-form-box,
.category-add-box {
  background: var(--c-bg);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-sm);
  padding: 14px;
  margin-bottom: 16px;
}

.dish-admin-list,
.category-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.dish-admin-row,
.category-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 12px;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-sm);
  background: var(--c-surface);
}

.dish-admin-info {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.dish-admin-info .price {
  color: #000000;
  font-weight: 700;
  font-size: 0.95rem;
}

.dish-admin-actions {
  display: flex;
  gap: 6px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
</style>
