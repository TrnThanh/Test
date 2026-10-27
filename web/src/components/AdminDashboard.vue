<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type {
  RoleLoginResponse,
  Restaurant,
  Category,
  Dish,
  MealType,
  SystemStats,
  AdminUser,
} from '../types';
import { api } from '../services/api';

const props = defineProps<{
  admin: RoleLoginResponse;
}>();

const emit = defineEmits<{
  (e: 'logout'): void;
}>();

// --- NAVIGATION STATE ---
type TabKey = 'dashboard' | 'restaurants' | 'menus' | 'accounts';
const currentTab = ref<TabKey>('dashboard');

// --- DATA STATES ---
const stats = ref<SystemStats | null>(null);
const statsLoading = ref(false);

const restaurants = ref<Restaurant[]>([]);
const restaurantsLoading = ref(false);
const restaurantSearch = ref('');
const restaurantStatusFilter = ref<'all' | 'active' | 'inactive'>('all');

// Edit Restaurant Modal State
const showEditModal = ref(false);
const editingRestaurant = ref<Restaurant | null>(null);
const editName = ref('');
const editAddress = ref('');
const editPhone = ref('');
const editDesc = ref('');
const editOpenTime = ref('');
const editCloseTime = ref('');
const editLat = ref(21.0055);
const editLon = ref(105.9325);
const editIsActive = ref(true);
const editSaving = ref(false);
const editLicenses = ref('');

// Create Restaurant Modal State
const showCreateRestaurantModal = ref(false);
const newRestName = ref('');
const newRestAddress = ref('');
const newRestPhone = ref('');
const newRestDesc = ref('');
const newRestOpenTime = ref('08:00');
const newRestCloseTime = ref('22:00');
const newRestLat = ref(21.0055); // Toạ độ trung tâm HVNN Gia Lâm
const newRestLon = ref(105.9325);
const newRestSaving = ref(false);
const newRestLicenses = ref('');

// Menus State
const selectedMenuRestaurantId = ref<number | null>(null);
const menuCategories = ref<Category[]>([]);
const menuDishes = ref<Dish[]>([]);
const menuLoading = ref(false);
const selectedCategoryId = ref<number | 'all'>('all');
const dishSearchQuery = ref('');
const menuRestSearch = ref('');

// Create Dish Modal State
const showCreateDishModal = ref(false);
const newDishName = ref('');
const newDishPrice = ref(35000);
const newDishDesc = ref('');
const newDishCategoryId = ref<number | null>(null);
const newDishMealType = ref<MealType>('all_day');
const newDishIngredients = ref('');
const newDishCalories = ref<number | null>(null);
const newDishSaving = ref(false);

// Create Category Modal State
const showCreateCategoryModal = ref(false);
const newCatName = ref('');
const newCatDesc = ref('');
const newCatSaving = ref(false);

// Accounts State
const users = ref<AdminUser[]>([]);
const accountsLoading = ref(false);
const userSearchQuery = ref('');

// Notification Alert
const noticeMsg = ref<string | null>(null);
const errorMsg = ref<string | null>(null);

function showNotice(msg: string) {
  noticeMsg.value = msg;
  setTimeout(() => {
    if (noticeMsg.value === msg) noticeMsg.value = null;
  }, 4000);
}

function showError(msg: string) {
  errorMsg.value = msg;
  setTimeout(() => {
    if (errorMsg.value === msg) errorMsg.value = null;
  }, 5000);
}

// --- API ACTIONS ---
async function loadStats() {
  statsLoading.value = true;
  try {
    stats.value = await api.getAdminStats();
  } catch (err: any) {
    showError(err.message || 'Không thể nạp chỉ số thống kê hệ thống');
  } finally {
    statsLoading.value = false;
  }
}

async function loadRestaurants() {
  restaurantsLoading.value = true;
  try {
    restaurants.value = await api.getAdminRestaurants(0, 100);
    // Nếu chưa chọn quán cho tab menu thì mặc định quán đầu tiên
    if (!selectedMenuRestaurantId.value && restaurants.value.length > 0) {
      selectedMenuRestaurantId.value = restaurants.value[0].id;
    }
  } catch (err: any) {
    showError(err.message || 'Không thể nạp danh sách quán ăn');
  } finally {
    restaurantsLoading.value = false;
  }
}

async function toggleRestaurantStatus(rest: Restaurant) {
  const newStatus = !rest.is_active;
  try {
    const updated = await api.updateRestaurantAsAdmin(rest.id, { is_active: newStatus });
    const idx = restaurants.value.findIndex((r) => r.id === rest.id);
    if (idx !== -1) {
      restaurants.value[idx] = updated;
    }
    showNotice(`Đã chuyển trạng thái "${rest.name}" sang: ${newStatus ? 'Đang hoạt động' : 'Tạm dừng'}`);
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể cập nhật trạng thái quán');
  }
}

function openEditRestaurant(rest: Restaurant) {
  editingRestaurant.value = rest;
  editName.value = rest.name;
  editAddress.value = rest.address || '';
  editPhone.value = rest.phone || '';
  editDesc.value = rest.description || '';
  editOpenTime.value = rest.open_time || '';
  editCloseTime.value = rest.close_time || '';
  editLat.value = rest.latitude;
  editLon.value = rest.longitude;
  editIsActive.value = rest.is_active;
  editLicenses.value = (rest.service_licenses || []).join(', ');
  showEditModal.value = true;
}

async function saveRestaurantChanges() {
  if (!editingRestaurant.value) return;
  if (!editName.value.trim() || !editAddress.value.trim()) {
    showError('Vui lòng nhập tên quán và địa chỉ');
    return;
  }

  editSaving.value = true;
  try {
    const updated = await api.updateRestaurantAsAdmin(editingRestaurant.value.id, {
      name: editName.value.trim(),
      address: editAddress.value.trim(),
      phone: editPhone.value.trim() || undefined,
      description: editDesc.value.trim() || undefined,
      open_time: editOpenTime.value || null,
      close_time: editCloseTime.value || null,
      latitude: Number(editLat.value),
      longitude: Number(editLon.value),
      is_active: editIsActive.value,
      service_licenses: editLicenses.value.split(',').map((s) => s.trim()).filter((s) => s.length > 0),
    });

    const idx = restaurants.value.findIndex((r) => r.id === updated.id);
    if (idx !== -1) {
      restaurants.value[idx] = updated;
    }

    showNotice(`Cập nhật thông tin quán "${updated.name}" thành công!`);
    showEditModal.value = false;
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể cập nhật quán ăn');
  } finally {
    editSaving.value = false;
  }
}

async function deleteRestaurant(rest: Restaurant) {
  if (!confirm(`Bạn có chắc muốn xoá vĩnh viễn quán "${rest.name}"? Dữ liệu thực đơn và món ăn của quán sẽ bị xoá kèm.`)) {
    return;
  }

  try {
    await api.deleteRestaurant(rest.id);
    restaurants.value = restaurants.value.filter((r) => r.id !== rest.id);
    if (selectedMenuRestaurantId.value === rest.id) {
      selectedMenuRestaurantId.value = restaurants.value.length > 0 ? restaurants.value[0].id : null;
      loadMenuData();
    }
    showNotice(`Đã xoá quán "${rest.name}" khỏi hệ thống.`);
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể xoá quán ăn.');
  }
}

// Menus
async function loadMenuData() {
  if (!selectedMenuRestaurantId.value) {
    menuCategories.value = [];
    menuDishes.value = [];
    return;
  }
  menuLoading.value = true;
  selectedCategoryId.value = 'all';
  try {
    const [cats, dishes] = await Promise.all([
      api.getRestaurantCategories(selectedMenuRestaurantId.value),
      api.getRestaurantDishes(selectedMenuRestaurantId.value),
    ]);
    menuCategories.value = cats;
    menuDishes.value = dishes;
  } catch (err: any) {
    showError(err.message || 'Không thể nạp dữ liệu thực đơn của quán');
  } finally {
    menuLoading.value = false;
  }
}

function selectRestaurantForMenu(restId: number) {
  selectedMenuRestaurantId.value = restId;
  currentTab.value = 'menus';
  loadMenuData();
}

// Accounts
async function loadAccounts() {
  accountsLoading.value = true;
  try {
    users.value = await api.getAdminUsers();
  } catch (err: any) {
    showError(err.message || 'Không thể nạp danh sách tài khoản');
  } finally {
    accountsLoading.value = false;
  }
}

function openCreateRestaurantModal() {
  newRestName.value = '';
  newRestAddress.value = '';
  newRestPhone.value = '';
  newRestDesc.value = '';
  newRestOpenTime.value = '08:00';
  newRestCloseTime.value = '22:00';
  newRestLat.value = 21.0055;
  newRestLon.value = 105.9325;
  newRestLicenses.value = '';
  showCreateRestaurantModal.value = true;
}

function applyHvnnPreset() {
  newRestAddress.value = 'Thị trấn Trâu Quỳ, Huyện Gia Lâm, Hà Nội';
  newRestLat.value = 21.0055;
  newRestLon.value = 105.9325;
}

async function handleCreateRestaurant() {
  if (!newRestName.value.trim() || !newRestAddress.value.trim()) {
    showError('Vui lòng nhập đầy đủ tên quán và địa chỉ');
    return;
  }
  newRestSaving.value = true;
  try {
    const created = await api.createRestaurantAsAdmin({
      name: newRestName.value.trim(),
      address: newRestAddress.value.trim(),
      phone: newRestPhone.value.trim() || undefined,
      description: newRestDesc.value.trim() || undefined,
      open_time: newRestOpenTime.value || null,
      close_time: newRestCloseTime.value || null,
      latitude: Number(newRestLat.value),
      longitude: Number(newRestLon.value),
      service_licenses: newRestLicenses.value.split(',').map((s) => s.trim()).filter((s) => s.length > 0),
    });
    restaurants.value.unshift(created);
    selectedMenuRestaurantId.value = created.id;
    showNotice(`Đã thêm quán mới "${created.name}" thành công!`);
    showCreateRestaurantModal.value = false;
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể tạo mới quán ăn');
  } finally {
    newRestSaving.value = false;
  }
}

function openCreateDishModal() {
  if (!selectedMenuRestaurantId.value) {
    showError('Vui lòng chọn một quán ăn trước');
    return;
  }
  newDishName.value = '';
  newDishPrice.value = 35000;
  newDishDesc.value = '';
  newDishCategoryId.value = menuCategories.value.length > 0 ? menuCategories.value[0].id : null;
  newDishMealType.value = 'all_day';
  newDishIngredients.value = '';
  newDishCalories.value = null;
  showCreateDishModal.value = true;
}

async function handleCreateDish() {
  if (!selectedMenuRestaurantId.value) return;
  if (!newDishName.value.trim()) {
    showError('Tên món ăn không được để trống');
    return;
  }
  if (newDishPrice.value < 0) {
    showError('Đơn giá món ăn không được âm');
    return;
  }
  newDishSaving.value = true;
  try {
    const ingList = newDishIngredients.value
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    const created = await api.createDish(selectedMenuRestaurantId.value, {
      name: newDishName.value.trim(),
      price: Number(newDishPrice.value),
      calories: newDishCalories.value != null ? Number(newDishCalories.value) : undefined,
      description: newDishDesc.value.trim() || undefined,
      category_id: newDishCategoryId.value || undefined,
      meal_type: newDishMealType.value,
      ingredients: ingList,
      is_available: true,
    });
    menuDishes.value.unshift(created);
    showNotice(`Đã thêm món "${created.name}" vào thực đơn.`);
    showCreateDishModal.value = false;
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể tạo món ăn mới');
  } finally {
    newDishSaving.value = false;
  }
}

async function deleteDishItem(dish: Dish) {
  if (!confirm(`Bạn có chắc chắn muốn xóa món "${dish.name}" khỏi thực đơn?`)) return;
  try {
    await api.deleteDish(dish.id);
    menuDishes.value = menuDishes.value.filter((d) => d.id !== dish.id);
    showNotice(`Đã xóa món "${dish.name}".`);
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể xóa món ăn');
  }
}

function openCreateCategoryModal() {
  if (!selectedMenuRestaurantId.value) {
    showError('Vui lòng chọn một quán ăn trước');
    return;
  }
  newCatName.value = '';
  newCatDesc.value = '';
  showCreateCategoryModal.value = true;
}

async function handleCreateCategory() {
  if (!selectedMenuRestaurantId.value) return;
  if (!newCatName.value.trim()) {
    showError('Tên danh mục không được để trống');
    return;
  }
  newCatSaving.value = true;
  try {
    const created = await api.createCategory(selectedMenuRestaurantId.value, {
      name: newCatName.value.trim(),
      description: newCatDesc.value.trim() || undefined,
      is_active: true,
      display_order: menuCategories.value.length,
    });
    menuCategories.value.push(created);
    showNotice(`Đã tạo nhóm món "${created.name}" thành công!`);
    showCreateCategoryModal.value = false;
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể tạo danh mục');
  } finally {
    newCatSaving.value = false;
  }
}

async function deleteCategoryItem(cat: Category) {
  if (!confirm(`Xác nhận xóa danh mục "${cat.name}"? Các món trong danh mục sẽ được đưa về nhóm Chung.`)) {
    return;
  }
  try {
    await api.deleteCategory(cat.id);
    menuCategories.value = menuCategories.value.filter((c) => c.id !== cat.id);
    if (selectedCategoryId.value === cat.id) {
      selectedCategoryId.value = 'all';
    }
    loadMenuData();
    showNotice(`Đã xóa danh mục "${cat.name}".`);
  } catch (err: any) {
    showError(err.message || 'Không thể xóa danh mục');
  }
}

// --- COMPUTED PROPERTIES ---

// Lọc quán ăn theo từ khóa và trạng thái
const filteredRestaurants = computed(() => {
  return restaurants.value.filter((r) => {
    const q = restaurantSearch.value.trim().toLowerCase();
    const matchesSearch = !q || r.name.toLowerCase().includes(q) || (r.address && r.address.toLowerCase().includes(q));

    const matchesStatus =
      restaurantStatusFilter.value === 'all' ||
      (restaurantStatusFilter.value === 'active' && r.is_active) ||
      (restaurantStatusFilter.value === 'inactive' && !r.is_active);

    return matchesSearch && matchesStatus;
  });
});

// Quán đang được chọn ở tab Thực đơn
const selectedMenuRestaurant = computed(() => {
  return restaurants.value.find((r) => r.id === selectedMenuRestaurantId.value) || null;
});

// Danh sách quán lọc ở cột Master tab Thực đơn
const filteredMenuRestaurants = computed(() => {
  const q = menuRestSearch.value.trim().toLowerCase();
  if (!q) return restaurants.value;
  return restaurants.value.filter(
    (r) => r.name.toLowerCase().includes(q) || (r.address && r.address.toLowerCase().includes(q))
  );
});

// Lọc món ăn theo Category và Search
const filteredMenuDishes = computed(() => {
  return menuDishes.value.filter((d) => {
    const matchCat =
      selectedCategoryId.value === 'all' ||
      d.category_id === selectedCategoryId.value;

    const q = dishSearchQuery.value.trim().toLowerCase();
    const matchSearch =
      !q ||
      d.name.toLowerCase().includes(q) ||
      (d.description && d.description.toLowerCase().includes(q)) ||
      (d.ingredients && d.ingredients.some((ing) => ing.toLowerCase().includes(q)));

    return matchCat && matchSearch;
  });
});

// Lọc tài khoản người dùng
const filteredUsers = computed(() => {
  const q = userSearchQuery.value.trim().toLowerCase();
  if (!q) return users.value;
  return users.value.filter(
    (u) => u.email.toLowerCase().includes(q) || (u.full_name && u.full_name.toLowerCase().includes(q))
  );
});

// Helper chuyển meal type sang tiếng Việt
function formatMealType(mt?: MealType | string | null): string {
  if (!mt) return 'Cả ngày';
  switch (mt) {
    case 'breakfast':
      return 'Bữa sáng';
    case 'lunch':
      return 'Bữa trưa';
    case 'dinner':
      return 'Bữa tối';
    case 'snack':
      return 'Ăn vặt';
    default:
      return 'Cả ngày';
  }
}

onMounted(() => {
  loadStats();
  loadRestaurants();
  loadAccounts();
});
</script>

<template>
  <div class="admin-portal">
    <!-- Top Bar: Minimalist Modern Navbar -->
    <header class="admin-topbar">
      <div class="topbar-inner">
        <!-- Brand -->
        <div class="brand-cluster">
          <div class="brand-logo">P</div>
          <div>
            <div class="brand-title">PTC1 Platform</div>
            <div class="brand-subtitle">Cổng Quản Trị Hệ Thống</div>
          </div>
        </div>

        <!-- Navigation Tabs -->
        <nav class="nav-cluster">
          <button
            type="button"
            class="nav-tab"
            :class="{ active: currentTab === 'dashboard' }"
            @click="currentTab = 'dashboard'"
          >
            Tổng quan
          </button>
          <button
            type="button"
            class="nav-tab"
            :class="{ active: currentTab === 'restaurants' }"
            @click="currentTab = 'restaurants'"
          >
            Cơ sở quán ăn
            <span class="tab-badge">{{ restaurants.length }}</span>
          </button>
          <button
            type="button"
            class="nav-tab"
            :class="{ active: currentTab === 'menus' }"
            @click="currentTab = 'menus'; loadMenuData()"
          >
            Thực đơn món
          </button>
          <button
            type="button"
            class="nav-tab"
            :class="{ active: currentTab === 'accounts' }"
            @click="currentTab = 'accounts'; loadAccounts()"
          >
            Người dùng
            <span class="tab-badge">{{ users.length }}</span>
          </button>
        </nav>

        <!-- Admin Profile -->
        <div class="user-cluster">
          <div class="user-chip">
            <span class="avatar-circle">A</span>
            <span class="user-email-text" :title="admin.email">{{ admin.email }}</span>
          </div>
          <button type="button" class="btn-logout" title="Đăng xuất" @click="emit('logout')">
            Thoát
          </button>
        </div>
      </div>
    </header>

    <!-- Thông báo nổi -->
    <div v-if="noticeMsg" class="banner-notice">
      <span>{{ noticeMsg }}</span>
    </div>
    <div v-if="errorMsg" class="banner-error">
      <span>{{ errorMsg }}</span>
    </div>

    <!-- Main Workspace -->
    <main class="admin-body">
      <!-- ============================================== -->
      <!-- TAB 1: TỔNG QUAN (DASHBOARD)                   -->
      <!-- ============================================== -->
      <section v-if="currentTab === 'dashboard'" class="view-panel">
        <div class="view-header">
          <div>
            <h1 class="view-title">Tổng quan hệ thống</h1>
            <p class="view-desc">Tóm tắt các chỉ số cốt lõi và các cơ sở ẩm thực cập nhật mới nhất</p>
          </div>
          <button
            type="button"
            class="btn-refresh"
            :disabled="statsLoading"
            @click="loadStats(); loadRestaurants(); loadAccounts()"
          >
            {{ statsLoading ? 'Đang nạp...' : '↻ Làm mới' }}
          </button>
        </div>

        <!-- 4 KPI Metrics tinh gọn -->
        <div class="kpi-row">
          <div class="kpi-box">
            <span class="kpi-label">Tổng cơ sở quán</span>
            <div class="kpi-num">{{ stats?.total_restaurants ?? restaurants.length }}</div>
            <div class="kpi-footnote">
              <span class="dot-online"></span> {{ stats?.active_restaurants ?? restaurants.filter(r => r.is_active).length }} đang mở cửa
            </div>
          </div>

          <div class="kpi-box">
            <span class="kpi-label">Tổng món ăn</span>
            <div class="kpi-num">{{ stats?.total_dishes ?? 0 }}</div>
            <div class="kpi-footnote">
              {{ stats?.total_categories ?? 0 }} nhóm danh mục món
            </div>
          </div>

          <div class="kpi-box">
            <span class="kpi-label">Người dùng đăng ký</span>
            <div class="kpi-num">{{ stats?.total_users ?? users.length }}</div>
            <div class="kpi-footnote">Tài khoản Mobile App</div>
          </div>

          <div class="kpi-box">
            <span class="kpi-label">Tỷ lệ hoạt động</span>
            <div class="kpi-num">
              {{
                restaurants.length > 0
                  ? Math.round((restaurants.filter(r => r.is_active).length / restaurants.length) * 100)
                  : 100
              }}%
            </div>
            <div class="kpi-footnote">Cơ sở sẵn sàng phục vụ</div>
          </div>
        </div>

        <!-- Bảng tóm tắt hoạt động gần đây -->
        <div class="recent-box">
          <div class="box-head">
            <h2 class="box-title">Cơ sở hoạt động gần đây</h2>
            <button type="button" class="btn-link" @click="currentTab = 'restaurants'">
              Xem tất cả quán ăn →
            </button>
          </div>

          <div v-if="restaurantsLoading" class="compact-loading">
            <div class="spinner-small"></div> Đang nạp dữ liệu...
          </div>
          <div v-else-if="restaurants.length === 0" class="compact-empty">
            Chưa có quán ăn nào trên hệ thống.
          </div>
          <div v-else class="table-wrap">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Cơ sở</th>
                  <th>Địa chỉ</th>
                  <th>Giờ phục vụ</th>
                  <th>Trạng thái</th>
                  <th style="text-align: right;">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in restaurants.slice(0, 5)" :key="r.id">
                  <td>
                    <div class="rest-title-cell">
                      <div class="rest-avatar">{{ r.name.charAt(0).toUpperCase() }}</div>
                      <div>
                        <strong>{{ r.name }}</strong>
                        <div v-if="r.phone" class="text-sub">{{ r.phone }}</div>
                      </div>
                    </div>
                  </td>
                  <td class="text-sub">{{ r.address || '—' }}</td>
                  <td>
                    <span v-if="r.open_time && r.close_time" class="time-pill">
                      {{ r.open_time }} – {{ r.close_time }}
                    </span>
                    <span v-else class="text-sub">—</span>
                  </td>
                  <td>
                    <span :class="['status-dot-badge', r.is_active ? 'active' : 'inactive']">
                      {{ r.is_active ? 'Đang mở' : 'Tạm dừng' }}
                    </span>
                  </td>
                  <td style="text-align: right;">
                    <button
                      type="button"
                      class="btn-sub-action"
                      @click="selectRestaurantForMenu(r.id)"
                    >
                      Thực đơn
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 2: QUẢN LÝ QUÁN ĂN (RESTAURANTS)           -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'restaurants'" class="view-panel">
        <div class="view-header">
          <div>
            <h1 class="view-title">Cơ sở quán ăn</h1>
            <p class="view-desc">Quản lý danh sách, thông tin liên hệ và trạng thái hoạt động của từng quán</p>
          </div>
          <button type="button" class="btn-primary-action" @click="openCreateRestaurantModal">
            + Thêm quán mới
          </button>
        </div>

        <!-- Toolbar: Search & Filter -->
        <div class="toolbar-row">
          <div class="search-box">
            <span class="search-icon">🔍</span>
            <input
              v-model="restaurantSearch"
              type="text"
              placeholder="Tìm theo tên quán, địa chỉ..."
              class="toolbar-input"
            />
          </div>
          <div class="filter-cluster">
            <label class="filter-label">Trạng thái:</label>
            <select v-model="restaurantStatusFilter" class="toolbar-select">
              <option value="all">Tất cả ({{ restaurants.length }})</option>
              <option value="active">Đang mở ({{ restaurants.filter(r => r.is_active).length }})</option>
              <option value="inactive">Tạm dừng ({{ restaurants.filter(r => !r.is_active).length }})</option>
            </select>
          </div>
        </div>

        <!-- Content Table -->
        <div v-if="restaurantsLoading" class="panel-loading">
          <div class="spinner-small"></div> Đang tải danh sách cơ sở...
        </div>
        <div v-else-if="filteredRestaurants.length === 0" class="panel-empty">
          Không tìm thấy quán ăn nào phù hợp với bộ lọc.
        </div>
        <div v-else class="table-wrap main-card">
          <table class="data-table">
            <thead>
              <tr>
                <th style="width: 50px;">#</th>
                <th>Cơ sở quán ăn</th>
                <th>Địa chỉ & Giờ phục vụ</th>
                <th>Trạng thái</th>
                <th style="width: 240px; text-align: right;">Hành động</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in filteredRestaurants" :key="r.id">
                <td class="text-sub">#{{ r.id }}</td>
                <td>
                  <div class="rest-title-cell">
                    <div class="rest-avatar">{{ r.name.charAt(0).toUpperCase() }}</div>
                    <div>
                      <div class="cell-main-title">{{ r.name }}</div>
                      <div v-if="r.phone" class="text-sub">Hotline: {{ r.phone }}</div>
                      <div v-if="r.service_licenses && r.service_licenses.length > 0" style="display: flex; gap: 4px; flex-wrap: wrap; margin-top: 4px;">
                        <span v-for="lic in r.service_licenses" :key="lic" class="status-dot-badge active" style="font-size: 11px;">📜 {{ lic }}</span>
                      </div>
                    </div>
                  </div>
                </td>
                <td>
                  <div>{{ r.address || '—' }}</div>
                  <div class="text-sub" style="margin-top: 2px;">
                    <span v-if="r.open_time && r.close_time">🕒 {{ r.open_time }} – {{ r.close_time }}</span>
                    <span v-else>🕒 Chưa cấu hình giờ</span>
                  </div>
                </td>
                <td>
                  <span :class="['status-dot-badge', r.is_active ? 'active' : 'inactive']">
                    {{ r.is_active ? 'Đang hoạt động' : 'Tạm dừng' }}
                  </span>
                </td>
                <td style="text-align: right;">
                  <div class="actions-group">
                    <button
                      type="button"
                      class="btn-action-ghost"
                      title="Xem thực đơn của quán"
                      @click="selectRestaurantForMenu(r.id)"
                    >
                      Thực đơn
                    </button>
                    <button
                      type="button"
                      class="btn-action-ghost"
                      title="Sửa thông tin"
                      @click="openEditRestaurant(r)"
                    >
                      Sửa
                    </button>
                    <button
                      type="button"
                      class="btn-action-ghost"
                      :title="r.is_active ? 'Tạm dừng quán' : 'Mở bán lại'"
                      @click="toggleRestaurantStatus(r)"
                    >
                      {{ r.is_active ? 'Tắt' : 'Bật' }}
                    </button>
                    <button
                      type="button"
                      class="btn-action-danger"
                      title="Xóa quán vĩnh viễn"
                      @click="deleteRestaurant(r)"
                    >
                      Xóa
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 3: THỰC ĐƠN & NHÓM MÓN (MASTER-DETAIL)     -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'menus'" class="view-panel">
        <div class="view-header">
          <div>
            <h1 class="view-title">Thực đơn & Nhóm món</h1>
            <p class="view-desc">Quản lý thực đơn phân nhóm theo từng cơ sở ẩm thực</p>
          </div>
          <div class="header-actions">
            <button
              type="button"
              class="btn-secondary-action"
              :disabled="!selectedMenuRestaurantId"
              @click="openCreateCategoryModal"
            >
              + Nhóm món
            </button>
            <button
              type="button"
              class="btn-primary-action"
              :disabled="!selectedMenuRestaurantId"
              @click="openCreateDishModal"
            >
              + Thêm món ăn
            </button>
          </div>
        </div>

        <!-- Layout Master - Detail 2 cột -->
        <div class="master-detail-layout">
          <!-- Cột Master (Trái): Chọn quán -->
          <aside class="master-pane">
            <div class="master-search-box">
              <input
                v-model="menuRestSearch"
                type="text"
                placeholder="Tìm quán ăn..."
                class="master-input"
              />
            </div>

            <div class="master-list">
              <div
                v-for="r in filteredMenuRestaurants"
                :key="r.id"
                class="master-item"
                :class="{ active: selectedMenuRestaurantId === r.id }"
                @click="selectedMenuRestaurantId = r.id; loadMenuData()"
              >
                <div class="master-item-avatar">{{ r.name.charAt(0).toUpperCase() }}</div>
                <div class="master-item-info">
                  <div class="master-item-name">{{ r.name }}</div>
                  <div class="master-item-sub">{{ r.address || '—' }}</div>
                </div>
              </div>
              <div v-if="filteredMenuRestaurants.length === 0" class="master-empty">
                Không tìm thấy quán
              </div>
            </div>
          </aside>

          <!-- Cột Detail (Phải): Thực đơn & Món ăn -->
          <section class="detail-pane">
            <div v-if="!selectedMenuRestaurant" class="panel-empty">
              Vui lòng chọn một quán ăn ở cột bên trái để quản lý thực đơn.
            </div>

            <div v-else>
              <!-- Info Bar của quán đang chọn -->
              <div class="detail-header-card">
                <div>
                  <h2 class="detail-rest-name">{{ selectedMenuRestaurant.name }}</h2>
                  <div class="detail-rest-sub">
                    <span>📍 {{ selectedMenuRestaurant.address || 'Chưa cập nhật địa chỉ' }}</span>
                    <span v-if="selectedMenuRestaurant.open_time"> • 🕒 {{ selectedMenuRestaurant.open_time }} – {{ selectedMenuRestaurant.close_time }}</span>
                  </div>
                </div>
                <div class="detail-stats-pill">
                  {{ menuDishes.length }} món ăn • {{ menuCategories.length }} nhóm
                </div>
              </div>

              <!-- Thanh lọc Category Pills -->
              <div class="category-pills-bar">
                <button
                  type="button"
                  class="cat-pill"
                  :class="{ active: selectedCategoryId === 'all' }"
                  @click="selectedCategoryId = 'all'"
                >
                  Tất cả ({{ menuDishes.length }})
                </button>
                <div
                  v-for="c in menuCategories"
                  :key="c.id"
                  class="cat-pill-wrapper"
                >
                  <button
                    type="button"
                    class="cat-pill"
                    :class="{ active: selectedCategoryId === c.id }"
                    @click="selectedCategoryId = c.id"
                  >
                    {{ c.name }}
                  </button>
                  <button
                    type="button"
                    class="cat-del-btn"
                    title="Xóa nhóm này"
                    @click.stop="deleteCategoryItem(c)"
                  >
                    ✕
                  </button>
                </div>
                <button
                  type="button"
                  class="cat-pill add-cat-pill"
                  @click="openCreateCategoryModal"
                >
                  + Thêm nhóm
                </button>
              </div>

              <!-- Thanh tìm kiếm món -->
              <div class="dish-search-bar">
                <input
                  v-model="dishSearchQuery"
                  type="text"
                  placeholder="Lọc món ăn theo tên hoặc nguyên liệu..."
                  class="dish-search-input"
                />
              </div>

              <!-- Trạng thái Loading hoặc Empty -->
              <div v-if="menuLoading" class="panel-loading">
                <div class="spinner-small"></div> Đang nạp thực đơn...
              </div>

              <div v-else-if="filteredMenuDishes.length === 0" class="panel-empty-box">
                <div style="font-size: 1.5rem; margin-bottom: 8px;">🍽️</div>
                <div style="font-weight: 600; margin-bottom: 4px;">Chưa có món ăn nào</div>
                <p class="text-sub">Thêm món ăn mới để hoàn thiện thực đơn cho quán.</p>
                <button
                  type="button"
                  class="btn-primary-action"
                  style="margin-top: 12px;"
                  @click="openCreateDishModal"
                >
                  + Thêm món ăn ngay
                </button>
              </div>

              <!-- Lưới món ăn (Dish Cards Grid) -->
              <div v-else class="dish-grid">
                <div v-for="d in filteredMenuDishes" :key="d.id" class="dish-card">
                  <div class="dish-card-body">
                    <div class="dish-card-header">
                      <div class="dish-card-title">{{ d.name }}</div>
                      <div class="dish-price">{{ Number(d.price).toLocaleString('vi-VN') }} đ</div>
                    </div>
                    <p v-if="d.description" class="dish-card-desc">{{ d.description }}</p>

                    <div class="dish-meta-row">
                      <span class="meal-tag">{{ formatMealType((d.meal_types && d.meal_types.length > 0) ? d.meal_types[0] : d.meal_type) }}</span>
                      <span v-if="d.category_name" class="category-tag">{{ d.category_name }}</span>
                      <span v-if="d.calories" class="meal-tag" style="background: #fff1f2; color: #e11d48; border-color: #fecdd3;">🔥 {{ d.calories }} kcal</span>
                      <span v-if="d.spicy_level && d.spicy_level > 0" class="spicy-tag">🌶️ {{ d.spicy_level === 1 ? 'Cay nhẹ' : d.spicy_level === 2 ? 'Cay vừa' : 'Rất cay' }}</span>
                    </div>

                    <div v-if="d.ingredients && d.ingredients.length > 0" class="dish-ingredients">
                      <span v-for="ing in d.ingredients" :key="ing" class="ing-tag">{{ ing }}</span>
                    </div>
                  </div>

                  <div class="dish-card-footer">
                    <span :class="['avail-badge', d.is_available ? 'available' : 'out-of-stock']">
                      {{ d.is_available ? 'Còn món' : 'Hết món' }}
                    </span>
                    <button
                      type="button"
                      class="btn-dish-delete"
                      title="Xóa món ăn"
                      @click="deleteDishItem(d)"
                    >
                      Xóa
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 4: THỰC KHÁCH (ACCOUNTS)                   -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'accounts'" class="view-panel">
        <div class="view-header">
          <div>
            <h1 class="view-title">Tài khoản người dùng</h1>
            <p class="view-desc">Danh sách người dùng đã đăng ký sử dụng ứng dụng di động PTC1</p>
          </div>
          <button
            type="button"
            class="btn-refresh"
            :disabled="accountsLoading"
            @click="loadAccounts"
          >
            {{ accountsLoading ? 'Đang nạp...' : '↻ Làm mới' }}
          </button>
        </div>

        <div class="toolbar-row">
          <div class="search-box">
            <span class="search-icon">🔍</span>
            <input
              v-model="userSearchQuery"
              type="text"
              placeholder="Tìm theo email hoặc họ tên..."
              class="toolbar-input"
            />
          </div>
        </div>

        <div v-if="accountsLoading" class="panel-loading">
          <div class="spinner-small"></div> Đang tải danh sách tài khoản...
        </div>
        <div v-else-if="filteredUsers.length === 0" class="panel-empty">
          Không tìm thấy tài khoản người dùng nào.
        </div>
        <div v-else class="table-wrap main-card">
          <table class="data-table">
            <thead>
              <tr>
                <th>Người dùng</th>
                <th>Họ và tên</th>
                <th>Ngày tạo tài khoản</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="u in filteredUsers" :key="u.id">
                <td>
                  <div class="rest-title-cell">
                    <div class="user-avatar-circle">{{ (u.full_name || u.email).charAt(0).toUpperCase() }}</div>
                    <div>
                      <div class="cell-main-title">{{ u.email }}</div>
                    </div>
                  </div>
                </td>
                <td>{{ u.full_name || '—' }}</td>
                <td class="text-sub">{{ new Date(u.created_at).toLocaleString('vi-VN') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>

    <!-- ============================================== -->
    <!-- MODAL: THÊM QUÁN MỚI                          -->
    <!-- ============================================== -->
    <div v-if="showCreateRestaurantModal" class="modal-backdrop" @click.self="showCreateRestaurantModal = false">
      <div class="modal-sheet">
        <div class="modal-sheet-header">
          <h3>Thêm quán ăn mới</h3>
          <button type="button" class="btn-close" @click="showCreateRestaurantModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="handleCreateRestaurant">
          <div class="form-item">
            <label>Tên quán ăn *</label>
            <input v-model="newRestName" type="text" class="field-input" placeholder="Ví dụ: Cơm tấm Sài Gòn 99" required />
          </div>

          <div class="form-item">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
              <label>Địa chỉ cơ sở *</label>
              <button type="button" class="btn-preset-hint" @click="applyHvnnPreset">
                Gợi ý: HVNN Gia Lâm
              </button>
            </div>
            <input v-model="newRestAddress" type="text" class="field-input" placeholder="Số nhà, đường, thị trấn..." required />
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Số điện thoại</label>
              <input v-model="newRestPhone" type="text" class="field-input" placeholder="0987..." />
            </div>
            <div class="form-item">
              <label>Khung giờ mở cửa</label>
              <div style="display: flex; gap: 6px; align-items: center;">
                <input v-model="newRestOpenTime" type="time" class="field-input" />
                <span>–</span>
                <input v-model="newRestCloseTime" type="time" class="field-input" />
              </div>
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Vĩ độ (Latitude)</label>
              <input v-model.number="newRestLat" type="number" step="any" class="field-input" required />
            </div>
            <div class="form-item">
              <label>Kinh độ (Longitude)</label>
              <input v-model.number="newRestLon" type="number" step="any" class="field-input" required />
            </div>
          </div>

          <div class="form-item">
            <label>Mô tả ngắn</label>
            <textarea v-model="newRestDesc" class="field-textarea" rows="2" placeholder="Đặc sản, ghi chú thêm..."></textarea>
          </div>

          <div class="form-item">
            <label>Giấy phép dịch vụ (phân tách bằng dấu phẩy)</label>
            <input v-model="newRestLicenses" type="text" class="field-input" placeholder="Ví dụ: Giấy chứng nhận ATTP, PCCC, Giấy phép kinh doanh..." />
          </div>

          <div class="modal-sheet-footer">
            <button type="button" class="btn-cancel" @click="showCreateRestaurantModal = false">
              Hủy
            </button>
            <button type="submit" class="btn-primary-action" :disabled="newRestSaving">
              {{ newRestSaving ? 'Đang tạo...' : 'Tạo cơ sở' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ============================================== -->
    <!-- MODAL: SỬA QUÁN ĂN                            -->
    <!-- ============================================== -->
    <div v-if="showEditModal" class="modal-backdrop" @click.self="showEditModal = false">
      <div class="modal-sheet">
        <div class="modal-sheet-header">
          <h3>Sửa thông tin quán (#{{ editingRestaurant?.id }})</h3>
          <button type="button" class="btn-close" @click="showEditModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="saveRestaurantChanges">
          <div class="form-item">
            <label>Tên quán ăn *</label>
            <input v-model="editName" type="text" class="field-input" required />
          </div>

          <div class="form-item">
            <label>Địa chỉ *</label>
            <input v-model="editAddress" type="text" class="field-input" required />
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Số điện thoại</label>
              <input v-model="editPhone" type="text" class="field-input" />
            </div>
            <div class="form-item">
              <label>Trạng thái</label>
              <select v-model="editIsActive" class="field-select">
                <option :value="true">Đang hoạt động</option>
                <option :value="false">Tạm dừng</option>
              </select>
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Giờ mở cửa</label>
              <input v-model="editOpenTime" type="time" class="field-input" />
            </div>
            <div class="form-item">
              <label>Giờ đóng cửa</label>
              <input v-model="editCloseTime" type="time" class="field-input" />
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Vĩ độ</label>
              <input v-model.number="editLat" type="number" step="any" class="field-input" required />
            </div>
            <div class="form-item">
              <label>Kinh độ</label>
              <input v-model.number="editLon" type="number" step="any" class="field-input" required />
            </div>
          </div>

          <div class="form-item">
            <label>Mô tả quán</label>
            <textarea v-model="editDesc" class="field-textarea" rows="2"></textarea>
          </div>

          <div class="form-item">
            <label>Giấy phép dịch vụ (phân tách bằng dấu phẩy)</label>
            <input v-model="editLicenses" type="text" class="field-input" placeholder="Ví dụ: Giấy chứng nhận ATTP, PCCC, Giấy phép kinh doanh..." />
          </div>

          <div class="modal-sheet-footer">
            <button type="button" class="btn-cancel" @click="showEditModal = false">
              Hủy
            </button>
            <button type="submit" class="btn-primary-action" :disabled="editSaving">
              {{ editSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ============================================== -->
    <!-- MODAL: THÊM MÓN ĂN                            -->
    <!-- ============================================== -->
    <div v-if="showCreateDishModal" class="modal-backdrop" @click.self="showCreateDishModal = false">
      <div class="modal-sheet">
        <div class="modal-sheet-header">
          <h3>Thêm món ăn mới vào thực đơn</h3>
          <button type="button" class="btn-close" @click="showCreateDishModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="handleCreateDish">
          <div class="form-grid-2">
            <div class="form-item">
              <label>Tên món ăn *</label>
              <input v-model="newDishName" type="text" class="field-input" placeholder="Ví dụ: Phở bò đặc biệt" required />
            </div>
            <div class="form-item">
              <label>Đơn giá (VNĐ) *</label>
              <input v-model.number="newDishPrice" type="number" min="0" step="1000" class="field-input" required />
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Bữa ăn phù hợp</label>
              <select v-model="newDishMealType" class="field-select">
                <option value="all_day">Cả ngày (all_day)</option>
                <option value="breakfast">Bữa sáng (breakfast)</option>
                <option value="lunch">Bữa trưa (lunch)</option>
                <option value="dinner">Bữa tối (dinner)</option>
                <option value="snack">Ăn vặt / Xế (snack)</option>
              </select>
            </div>
            <div class="form-item">
              <label>Nhóm danh mục</label>
              <select v-model="newDishCategoryId" class="field-select">
                <option :value="null">-- Nhóm Chung --</option>
                <option v-for="c in menuCategories" :key="c.id" :value="c.id">
                  {{ c.name }}
                </option>
              </select>
            </div>
          </div>

          <div class="form-item">
            <label>Năng lượng Calo (kcal)</label>
            <input v-model.number="newDishCalories" type="number" min="0" class="field-input" placeholder="Ví dụ: 550" />
          </div>

          <div class="form-item">
            <label>Nguyên liệu (phân tách bằng dấu phẩy)</label>
            <input v-model="newDishIngredients" type="text" class="field-input" placeholder="Thịt bò, bánh phở, hành tây, rau thơm..." />
          </div>

          <div class="form-item">
            <label>Mô tả chi tiết món</label>
            <textarea v-model="newDishDesc" class="field-textarea" rows="2" placeholder="Hương vị, định lượng..."></textarea>
          </div>

          <div class="modal-sheet-footer">
            <button type="button" class="btn-cancel" @click="showCreateDishModal = false">
              Hủy
            </button>
            <button type="submit" class="btn-primary-action" :disabled="newDishSaving">
              {{ newDishSaving ? 'Đang thêm...' : 'Thêm món' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ============================================== -->
    <!-- MODAL: THÊM DANH MỤC                          -->
    <!-- ============================================== -->
    <div v-if="showCreateCategoryModal" class="modal-backdrop" @click.self="showCreateCategoryModal = false">
      <div class="modal-sheet" style="max-width: 440px;">
        <div class="modal-sheet-header">
          <h3>Thêm nhóm món mới</h3>
          <button type="button" class="btn-close" @click="showCreateCategoryModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="handleCreateCategory">
          <div class="form-item">
            <label>Tên nhóm danh mục *</label>
            <input v-model="newCatName" type="text" class="field-input" placeholder="Ví dụ: Đồ Uống, Món Nướng..." required />
          </div>

          <div class="form-item">
            <label>Mô tả ngắn</label>
            <textarea v-model="newCatDesc" class="field-textarea" rows="2" placeholder="Ghi chú thêm về nhóm món..."></textarea>
          </div>

          <div class="modal-sheet-footer">
            <button type="button" class="btn-cancel" @click="showCreateCategoryModal = false">
              Hủy
            </button>
            <button type="submit" class="btn-primary-action" :disabled="newCatSaving">
              {{ newCatSaving ? 'Đang tạo...' : 'Tạo nhóm' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ==================================================== */
/* MODERN SAAS ADMIN CONSOLE STYLES                     */
/* ==================================================== */

.admin-portal {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #f8fafc;
  color: #0f172a;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  font-size: 14px;
  line-height: 1.5;
}

/* TOPBAR */
.admin-topbar {
  background-color: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  position: sticky;
  top: 0;
  z-index: 50;
}

.topbar-inner {
  max-width: 1280px;
  margin: 0 auto;
  padding: 10px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
}

.brand-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

.brand-logo {
  width: 32px;
  height: 32px;
  background-color: #0f172a;
  color: #ffffff;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 16px;
  letter-spacing: -0.5px;
}

.brand-title {
  font-weight: 700;
  font-size: 14px;
  color: #0f172a;
  line-height: 1.2;
}

.brand-subtitle {
  font-size: 11px;
  color: #64748b;
}

/* NAVIGATION TABS */
.nav-cluster {
  display: flex;
  align-items: center;
  gap: 4px;
  background-color: #f1f5f9;
  padding: 3px;
  border-radius: 8px;
}

.nav-tab {
  background: transparent;
  border: none;
  font-size: 13px;
  font-weight: 500;
  color: #64748b;
  padding: 6px 14px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.nav-tab:hover {
  color: #0f172a;
}

.nav-tab.active {
  background-color: #ffffff;
  color: #0f172a;
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.tab-badge {
  background-color: #e2e8f0;
  color: #475569;
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 999px;
  font-weight: 600;
}

.nav-tab.active .tab-badge {
  background-color: #f1f5f9;
  color: #0f172a;
}

/* USER PROFILE */
.user-cluster {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #334155;
  background-color: #f8fafc;
  padding: 4px 10px 4px 4px;
  border-radius: 999px;
  border: 1px solid #e2e8f0;
}

.avatar-circle {
  width: 24px;
  height: 24px;
  background-color: #e2e8f0;
  color: #0f172a;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
}

.user-email-text {
  max-width: 150px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.btn-logout {
  background: transparent;
  border: 1px solid #e2e8f0;
  color: #64748b;
  font-size: 12px;
  padding: 5px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-logout:hover {
  background-color: #fee2e2;
  color: #dc2626;
  border-color: #fca5a5;
}

/* NOTICES */
.banner-notice,
.banner-error {
  max-width: 1280px;
  margin: 12px auto 0;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
}

.banner-notice {
  background-color: #f0fdf4;
  color: #166534;
  border: 1px solid #bbf7d0;
}

.banner-error {
  background-color: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

/* BODY WORKSPACE */
.admin-body {
  max-width: 1280px;
  width: 100%;
  margin: 0 auto;
  padding: 24px;
  flex: 1;
}

.view-panel {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.view-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.view-title {
  font-size: 20px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.02em;
  margin: 0 0 4px 0;
}

.view-desc {
  font-size: 13px;
  color: #64748b;
  margin: 0;
}

.header-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

/* BUTTONS */
.btn-primary-action {
  background-color: #0f172a;
  color: #ffffff;
  border: none;
  font-size: 13px;
  font-weight: 600;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
}

.btn-primary-action:hover:not(:disabled) {
  background-color: #1e293b;
}

.btn-primary-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary-action {
  background-color: #ffffff;
  color: #0f172a;
  border: 1px solid #cbd5e1;
  font-size: 13px;
  font-weight: 500;
  padding: 8px 14px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-secondary-action:hover:not(:disabled) {
  background-color: #f1f5f9;
}

.btn-refresh {
  background: transparent;
  border: 1px solid #e2e8f0;
  color: #475569;
  font-size: 12px;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-refresh:hover:not(:disabled) {
  background-color: #ffffff;
  color: #0f172a;
}

/* KPI ROW */
.kpi-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}

.kpi-box {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.kpi-label {
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.kpi-num {
  font-size: 26px;
  font-weight: 700;
  color: #0f172a;
  line-height: 1.1;
}

.kpi-footnote {
  font-size: 12px;
  color: #64748b;
  display: flex;
  align-items: center;
  gap: 6px;
}

.dot-online {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #16a34a;
}

/* RECENT BOX & TABLES */
.recent-box,
.main-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.box-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.box-title {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
  color: #0f172a;
}

.btn-link {
  background: transparent;
  border: none;
  color: #2563eb;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  padding: 0;
}

.btn-link:hover {
  text-decoration: underline;
}

.table-wrap {
  overflow-x: auto;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.data-table th {
  background-color: #f8fafc;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 12px 18px;
  border-bottom: 1px solid #e2e8f0;
}

.data-table td {
  padding: 14px 18px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.data-table tr:last-child td {
  border-bottom: none;
}

.data-table tr:hover td {
  background-color: #f8fafc;
}

.rest-title-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.rest-avatar,
.user-avatar-circle {
  width: 32px;
  height: 32px;
  background-color: #f1f5f9;
  border: 1px solid #e2e8f0;
  color: #334155;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 13px;
  flex-shrink: 0;
}

.cell-main-title {
  font-weight: 600;
  color: #0f172a;
}

.text-sub {
  font-size: 12px;
  color: #64748b;
}

.time-pill {
  font-size: 12px;
  color: #334155;
  background-color: #f1f5f9;
  padding: 2px 8px;
  border-radius: 4px;
}

.status-dot-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 500;
  padding: 2px 10px;
  border-radius: 999px;
}

.status-dot-badge::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: currentColor;
}

.status-dot-badge.active {
  background-color: #f0fdf4;
  color: #16a34a;
}

.status-dot-badge.inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

.actions-group {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.btn-action-ghost {
  background: transparent;
  border: 1px solid #e2e8f0;
  color: #334155;
  font-size: 12px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-ghost:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.btn-action-danger {
  background: transparent;
  border: 1px solid #fecaca;
  color: #dc2626;
  font-size: 12px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-danger:hover {
  background-color: #fef2f2;
}

.btn-sub-action {
  background: transparent;
  border: 1px solid #e2e8f0;
  color: #2563eb;
  font-size: 12px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: 5px;
  cursor: pointer;
}

.btn-sub-action:hover {
  background-color: #eff6ff;
}

/* TOOLBAR ROW */
.toolbar-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.search-box {
  display: flex;
  align-items: center;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  padding: 6px 12px;
  gap: 8px;
  min-width: 280px;
  flex: 1;
  max-width: 400px;
}

.search-icon {
  font-size: 13px;
  color: #94a3b8;
}

.toolbar-input {
  border: none;
  outline: none;
  font-size: 13px;
  color: #0f172a;
  width: 100%;
}

.filter-cluster {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-label {
  font-size: 13px;
  color: #64748b;
}

.toolbar-select {
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: 13px;
  color: #0f172a;
  outline: none;
}

/* MASTER-DETAIL LAYOUT (TAB MENUS) */
.master-detail-layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 20px;
  align-items: start;
}

.master-pane {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 180px);
  position: sticky;
  top: 80px;
  overflow: hidden;
}

.master-search-box {
  padding: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.master-input {
  width: 100%;
  padding: 6px 10px;
  font-size: 13px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  outline: none;
}

.master-list {
  overflow-y: auto;
  padding: 6px 0;
}

.master-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  cursor: pointer;
  border-left: 3px solid transparent;
  transition: all 0.15s;
}

.master-item:hover {
  background-color: #f8fafc;
}

.master-item.active {
  background-color: #f1f5f9;
  border-left-color: #0f172a;
}

.master-item-avatar {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background-color: #e2e8f0;
  color: #0f172a;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 12px;
  flex-shrink: 0;
}

.master-item-info {
  overflow: hidden;
}

.master-item-name {
  font-size: 13px;
  font-weight: 600;
  color: #0f172a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.master-item-sub {
  font-size: 11px;
  color: #64748b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.master-empty {
  padding: 24px;
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
}

/* DETAIL PANE */
.detail-pane {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-header-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.detail-rest-name {
  font-size: 17px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 4px 0;
}

.detail-rest-sub {
  font-size: 12px;
  color: #64748b;
}

.detail-stats-pill {
  font-size: 12px;
  font-weight: 600;
  color: #334155;
  background-color: #f1f5f9;
  padding: 4px 12px;
  border-radius: 999px;
  white-space: nowrap;
}

/* CATEGORY PILLS BAR */
.category-pills-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.cat-pill-wrapper {
  display: inline-flex;
  align-items: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  padding-right: 4px;
  transition: all 0.15s;
}

.cat-pill-wrapper:hover {
  border-color: #cbd5e1;
}

.cat-pill {
  background: transparent;
  border: none;
  font-size: 12px;
  font-weight: 500;
  color: #475569;
  padding: 5px 12px;
  cursor: pointer;
  border-radius: 999px;
}

button.cat-pill {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
}

button.cat-pill.active {
  background-color: #0f172a;
  color: #ffffff;
  border-color: #0f172a;
  font-weight: 600;
}

.cat-pill-wrapper:has(.active) {
  background-color: #0f172a;
  border-color: #0f172a;
}

.cat-pill-wrapper:has(.active) .cat-pill {
  color: #ffffff;
  font-weight: 600;
}

.cat-pill-wrapper:has(.active) .cat-del-btn {
  color: #94a3b8;
}

.cat-del-btn {
  background: transparent;
  border: none;
  color: #94a3b8;
  font-size: 11px;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 50%;
}

.cat-del-btn:hover {
  color: #ef4444;
}

.add-cat-pill {
  border-style: dashed;
  color: #64748b;
}

.add-cat-pill:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

/* DISH SEARCH BAR */
.dish-search-bar {
  width: 100%;
}

.dish-search-input {
  width: 100%;
  padding: 8px 14px;
  font-size: 13px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  background-color: #ffffff;
  outline: none;
}

/* DISH GRID */
.dish-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 16px;
}

.dish-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 16px;
  transition: all 0.15s;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.dish-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
}

.dish-card-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 6px;
}

.dish-card-title {
  font-size: 14px;
  font-weight: 600;
  color: #0f172a;
}

.dish-price {
  font-size: 14px;
  font-weight: 700;
  color: #e8590c;
  white-space: nowrap;
}

.dish-card-desc {
  font-size: 12px;
  color: #64748b;
  margin: 0 0 10px 0;
  line-height: 1.4;
}

.dish-meta-row {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}

.meal-tag {
  font-size: 11px;
  font-weight: 500;
  color: #334155;
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
}

.category-tag {
  font-size: 11px;
  color: #2563eb;
  background-color: #eff6ff;
  padding: 2px 6px;
  border-radius: 4px;
}

.dish-ingredients {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}

.ing-tag {
  font-size: 10px;
  color: #64748b;
  background-color: #f8fafc;
  border: 1px solid #f1f5f9;
  padding: 1px 5px;
  border-radius: 3px;
}

.dish-card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid #f1f5f9;
  padding-top: 10px;
}

.avail-badge {
  font-size: 11px;
  font-weight: 500;
}

.avail-badge.available {
  color: #16a34a;
}

.avail-badge.out-of-stock {
  color: #dc2626;
}

.btn-dish-delete {
  background: transparent;
  border: none;
  color: #94a3b8;
  font-size: 12px;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
}

.btn-dish-delete:hover {
  background-color: #fee2e2;
  color: #dc2626;
}

/* STATE BOXES */
.panel-loading,
.panel-empty,
.compact-loading,
.compact-empty {
  padding: 32px 16px;
  text-align: center;
  color: #64748b;
  font-size: 13px;
}

.panel-empty-box {
  background-color: #ffffff;
  border: 1px dashed #cbd5e1;
  border-radius: 10px;
  padding: 48px 24px;
  text-align: center;
}

.spinner-small {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid #cbd5e1;
  border-top-color: #0f172a;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  vertical-align: middle;
  margin-right: 6px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* MODALS */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 16px;
}

.modal-sheet {
  background-color: #ffffff;
  border-radius: 12px;
  max-width: 520px;
  width: 100%;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  overflow: hidden;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
}

.modal-sheet-header {
  padding: 16px 20px;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-sheet-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.btn-close {
  background: transparent;
  border: none;
  font-size: 16px;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
}

.btn-close:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.modal-sheet-body {
  padding: 20px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-item label {
  font-size: 12px;
  font-weight: 600;
  color: #334155;
}

.field-input,
.field-select,
.field-textarea {
  width: 100%;
  padding: 8px 12px;
  font-size: 13px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  outline: none;
  background-color: #ffffff;
  color: #0f172a;
  font-family: inherit;
}

.field-input:focus,
.field-select:focus,
.field-textarea:focus {
  border-color: #0f172a;
  box-shadow: 0 0 0 1px #0f172a;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.btn-preset-hint {
  background: transparent;
  border: none;
  color: #2563eb;
  font-size: 11px;
  cursor: pointer;
  padding: 0;
}

.btn-preset-hint:hover {
  text-decoration: underline;
}

.modal-sheet-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
  margin-top: 4px;
}

.btn-cancel {
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  color: #475569;
  font-size: 13px;
  font-weight: 500;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
}

.btn-cancel:hover {
  background-color: #f1f5f9;
}

/* RESPONSIVE */
@media (max-width: 860px) {
  .master-detail-layout {
    grid-template-columns: 1fr;
  }
  .master-pane {
    max-height: 240px;
    position: static;
  }
  .topbar-inner {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  .nav-cluster {
    overflow-x: auto;
  }
}
</style>
