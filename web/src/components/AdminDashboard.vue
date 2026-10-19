<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type {
  RoleLoginResponse,
  Restaurant,
  Category,
  Dish,
  SystemStats,
  AdminSeller,
  AdminUser,
} from '../types';
import { api } from '../services/api';

const props = defineProps<{
  admin: RoleLoginResponse;
}>();

const emit = defineEmits<{
  (e: 'logout'): void;
}>();

// Active View Tab: 'dashboard' | 'restaurants' | 'menus' | 'accounts'
const currentTab = ref<'dashboard' | 'restaurants' | 'menus' | 'accounts'>('dashboard');

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
const editLat = ref(21.0285);
const editLon = ref(105.8542);
const editIsActive = ref(true);
const editSaving = ref(false);

// Menus Tab State
const selectedMenuRestaurantId = ref<number | null>(null);
const menuCategories = ref<Category[]>([]);
const menuDishes = ref<Dish[]>([]);
const menuLoading = ref(false);

// Accounts Tab State
const accountSubTab = ref<'sellers' | 'users'>('sellers');
const sellers = ref<AdminSeller[]>([]);
const users = ref<AdminUser[]>([]);
const accountsLoading = ref(false);

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
    if (!selectedMenuRestaurantId.value && restaurants.value.length > 0) {
      selectedMenuRestaurantId.value = restaurants.value[0].id;
    }
  } catch (err: any) {
    showError(err.message || 'Không thể nạp danh sách quán ăn');
  } finally {
    restaurantsLoading.value = false;
  }
}

async function toggleRestaurantStatus(restaurant: Restaurant) {
  try {
    const updated = await api.toggleRestaurantStatus(restaurant.id, !restaurant.is_active);
    restaurant.is_active = updated.is_active;
    showNotice(
      `Đã ${updated.is_active ? 'kích hoạt' : 'tạm dừng'} hoạt động của quán "${restaurant.name}"`
    );
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Lỗi khi thay đổi trạng thái quán ăn');
  }
}

function openEditRestaurant(r: Restaurant) {
  editingRestaurant.value = r;
  editName.value = r.name;
  editAddress.value = r.address || '';
  editPhone.value = r.phone || '';
  editDesc.value = r.description || '';
  editOpenTime.value = r.open_time || '';
  editCloseTime.value = r.close_time || '';
  editLat.value = r.latitude;
  editLon.value = r.longitude;
  editIsActive.value = r.is_active;
  showEditModal.value = true;
}

async function saveRestaurantChanges() {
  if (!editingRestaurant.value) return;
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
    });

    const index = restaurants.value.findIndex((x) => x.id === updated.id);
    if (index !== -1) {
      restaurants.value[index] = updated;
    }

    showNotice(`Đã cập nhật thông tin quán "${updated.name}" thành công`);
    showEditModal.value = false;
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể lưu cập nhật quán ăn');
  } finally {
    editSaving.value = false;
  }
}

async function deleteRestaurant(r: Restaurant) {
  if (!confirm(`Bạn có chắc chắn muốn xoá vĩnh viễn quán ăn "${r.name}" (ID #${r.id})? Hành động này sẽ xoá cả thực đơn và không thể hoàn tác.`)) {
    return;
  }

  try {
    await api.deleteRestaurantAsAdmin(r.id);
    restaurants.value = restaurants.value.filter((x) => x.id !== r.id);
    showNotice(`Đã xoá quán ăn "${r.name}" thành công.`);
    loadStats();
  } catch (err: any) {
    showError(err.message || 'Không thể xoá quán ăn.');
  }
}

// Menus
async function loadMenuData() {
  if (!selectedMenuRestaurantId.value) return;
  menuLoading.value = true;
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
    const [sList, uList] = await Promise.all([
      api.getAdminSellers(),
      api.getAdminUsers(),
    ]);
    sellers.value = sList;
    users.value = uList;
  } catch (err: any) {
    showError(err.message || 'Không thể nạp danh sách tài khoản');
  } finally {
    accountsLoading.value = false;
  }
}

// Filtered Restaurants
const filteredRestaurants = computed(() => {
  return restaurants.value.filter((r) => {
    const matchesSearch =
      !restaurantSearch.value.trim() ||
      r.name.toLowerCase().includes(restaurantSearch.value.toLowerCase()) ||
      (r.address && r.address.toLowerCase().includes(restaurantSearch.value.toLowerCase()));

    const matchesStatus =
      restaurantStatusFilter.value === 'all' ||
      (restaurantStatusFilter.value === 'active' && r.is_active) ||
      (restaurantStatusFilter.value === 'inactive' && !r.is_active);

    return matchesSearch && matchesStatus;
  });
});

onMounted(() => {
  loadStats();
  loadRestaurants();
  loadAccounts();
});
</script>

<template>
  <div class="admin-portal">
    <!-- Top Header -->
    <header class="admin-header">
      <div class="header-container">
        <div class="header-brand">
          <span class="admin-badge">ADMIN CONSOLE</span>
          <div class="brand-text">
            <h1>PTC1 Spatial Platform</h1>
            <span class="brand-caption">Cổng Quản Trị & Giám Sát Cơ Sở Ẩm Thực</span>
          </div>
        </div>

        <!-- Navigation Tabs -->
        <nav class="admin-nav">
          <button
            type="button"
            class="nav-item"
            :class="{ active: currentTab === 'dashboard' }"
            @click="currentTab = 'dashboard'"
          >
            Tổng Quan
          </button>
          <button
            type="button"
            class="nav-item"
            :class="{ active: currentTab === 'restaurants' }"
            @click="currentTab = 'restaurants'"
          >
            Quán Ăn ({{ restaurants.length }})
          </button>
          <button
            type="button"
            class="nav-item"
            :class="{ active: currentTab === 'menus' }"
            @click="currentTab = 'menus'; loadMenuData()"
          >
            Thực Đơn & Nhóm Món
          </button>
          <button
            type="button"
            class="nav-item"
            :class="{ active: currentTab === 'accounts' }"
            @click="currentTab = 'accounts'; loadAccounts()"
          >
            Đối Tác & Người Dùng
          </button>
        </nav>

        <!-- Admin Profile & Logout -->
        <div class="header-user">
          <div class="user-pill">
            <span class="user-avatar">A</span>
            <div class="user-info">
              <span class="user-email">{{ admin.email }}</span>
              <span class="user-role">Quản Trị Viên</span>
            </div>
          </div>
          <button type="button" class="btn btn-outline btn-sm" @click="emit('logout')">
            Đăng xuất
          </button>
        </div>
      </div>
    </header>

    <!-- Notification Bars -->
    <div v-if="noticeMsg" class="container notice-bar">
      <div class="alert alert-success">
        {{ noticeMsg }}
      </div>
    </div>
    <div v-if="errorMsg" class="container notice-bar">
      <div class="alert alert-error">
        {{ errorMsg }}
      </div>
    </div>

    <!-- Main Workspace -->
    <main class="container admin-content">
      <!-- ============================================== -->
      <!-- TAB 1: TỔNG QUAN (DASHBOARD)                   -->
      <!-- ============================================== -->
      <section v-if="currentTab === 'dashboard'" class="tab-pane">
        <div class="pane-header">
          <div>
            <h2>Bảng Điều Khiển Tổng Quan (Dashboard)</h2>
            <p class="text-muted">Giám sát số lượng thực thể, dữ liệu toạ độ PostGIS và người dùng hệ thống</p>
          </div>
          <button type="button" class="btn btn-secondary btn-sm" :disabled="statsLoading" @click="loadStats(); loadRestaurants(); loadAccounts()">
            {{ statsLoading ? 'Đang cập nhật...' : 'Làm Mới Dữ Liệu' }}
          </button>
        </div>

        <!-- KPI Grid -->
        <div class="stats-grid">
          <div class="kpi-card">
            <div class="kpi-body">
              <span class="kpi-value">{{ stats?.total_restaurants ?? restaurants.length }}</span>
              <span class="kpi-label">Tổng Quán Ăn</span>
            </div>
            <div class="kpi-footer">
              <span class="kpi-sub green">{{ stats?.active_restaurants ?? restaurants.filter(r => r.is_active).length }} đang mở</span>
              <span class="kpi-divider">•</span>
              <span class="kpi-sub red">{{ stats?.inactive_restaurants ?? restaurants.filter(r => !r.is_active).length }} tạm dừng</span>
            </div>
          </div>

          <div class="kpi-card">
            <div class="kpi-body">
              <span class="kpi-value">{{ stats?.total_dishes ?? 0 }}</span>
              <span class="kpi-label">Tổng Món Ăn</span>
            </div>
            <div class="kpi-footer">
              <span class="kpi-sub">{{ stats?.total_categories ?? 0 }} nhóm danh mục thực đơn</span>
            </div>
          </div>

          <div class="kpi-card">
            <div class="kpi-body">
              <span class="kpi-value">{{ stats?.total_sellers ?? sellers.length }}</span>
              <span class="kpi-label">Chủ Quán (Sellers)</span>
            </div>
            <div class="kpi-footer">
              <span class="kpi-sub">Đối tác kinh doanh ẩm thực</span>
            </div>
          </div>

          <div class="kpi-card">
            <div class="kpi-body">
              <span class="kpi-value">{{ stats?.total_users ?? users.length }}</span>
              <span class="kpi-label">Thực Khách (Users)</span>
            </div>
            <div class="kpi-footer">
              <span class="kpi-sub">Truy cập từ ứng dụng Mobile</span>
            </div>
          </div>
        </div>

        <!-- Infrastructure & Platform Health Cards -->
        <div class="tech-grid">
          <div class="tech-card">
            <h3>Cấu Hình Nền Tảng Không Gian</h3>
            <ul class="tech-list">
              <li>
                <span class="tech-name">Hệ Quản Trị CSDL:</span>
                <span class="badge badge-primary">PostgreSQL 14 + PostGIS 3.6</span>
              </li>
              <li>
                <span class="tech-name">Loại dữ liệu địa lý:</span>
                <code>Geography(POINT, 4326 WGS84)</code>
              </li>
              <li>
                <span class="tech-name">Thuật toán lân cận:</span>
                <code>ST_DWithin & ST_Distance</code>
              </li>
              <li>
                <span class="tech-name">Dịch vụ Geocoding bản đồ:</span>
                <span class="badge badge-success">OpenStreetMap Nominatim</span>
              </li>
            </ul>
          </div>

          <div class="tech-card">
            <h3>Lối Tắt Quản Trị Nhanh</h3>
            <p class="text-muted" style="margin-bottom: 16px;">Truy cập nhanh các phân hệ điều hành quản lý cơ sở dữ liệu:</p>
            <div class="quick-links">
              <button type="button" class="btn btn-secondary" @click="currentTab = 'restaurants'">
                Quản lý danh sách Quán ăn
              </button>
              <button type="button" class="btn btn-secondary" @click="currentTab = 'menus'; loadMenuData()">
                Xem thực đơn & danh mục
              </button>
              <button type="button" class="btn btn-secondary" @click="currentTab = 'accounts'; loadAccounts()">
                Xem danh sách Sellers & Users
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 2: QUẢN LÝ QUÁN ĂN (RESTAURANTS)           -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'restaurants'" class="tab-pane">
        <div class="pane-header">
          <div>
            <h2>Quản Lý Cơ Sở Quán Ăn (Restaurants)</h2>
            <p class="text-muted">Giám sát toạ độ địa lý, thông tin liên hệ và trạng thái hoạt động của từng quán</p>
          </div>
          <button type="button" class="btn btn-secondary btn-sm" :disabled="restaurantsLoading" @click="loadRestaurants">
            {{ restaurantsLoading ? 'Đang tải...' : 'Làm Mới Danh Sách' }}
          </button>
        </div>

        <!-- Filter bar -->
        <div class="filter-bar">
          <input
            v-model="restaurantSearch"
            type="text"
            class="input search-input"
            placeholder="Tìm theo tên quán, địa chỉ..."
          />
          <div class="filter-group">
            <label>Trạng thái:</label>
            <select v-model="restaurantStatusFilter" class="input filter-select">
              <option value="all">Tất cả ({{ restaurants.length }})</option>
              <option value="active">Đang hoạt động ({{ restaurants.filter(r => r.is_active).length }})</option>
              <option value="inactive">Tạm dừng ({{ restaurants.filter(r => !r.is_active).length }})</option>
            </select>
          </div>
        </div>

        <!-- Restaurants Table -->
        <div v-if="restaurantsLoading" class="state-box">
          <div class="spinner"></div>
          <p>Đang tải danh sách cơ sở ẩm thực...</p>
        </div>

        <div v-else-if="filteredRestaurants.length === 0" class="state-box">
          <p>Không tìm thấy quán ăn nào phù hợp với bộ lọc.</p>
        </div>

        <div v-else class="table-container">
          <table class="admin-table">
            <thead>
              <tr>
                <th style="width: 60px;">ID</th>
                <th>Tên Quán Ăn</th>
                <th>Chủ Quán</th>
                <th>Địa Chỉ</th>
                <th>Giờ Mở Cửa</th>
                <th>Toạ Độ PostGIS</th>
                <th>Trạng Thái</th>
                <th style="width: 220px; text-align: right;">Hành Động Quản Trị</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="r in filteredRestaurants" :key="r.id">
                <td>#{{ r.id }}</td>
                <td class="name-cell">
                  <strong>{{ r.name }}</strong>
                  <span v-if="r.phone" class="sub-cell">SĐT: {{ r.phone }}</span>
                </td>
                <td>
                  <span class="badge badge-neutral">Seller #{{ r.seller_id }}</span>
                </td>
                <td class="addr-cell">{{ r.address || '—' }}</td>
                <td>
                  <span v-if="r.open_time && r.close_time">{{ r.open_time }} – {{ r.close_time }}</span>
                  <span v-else class="text-muted">—</span>
                </td>
                <td>
                  <code>{{ r.latitude.toFixed(4) }}, {{ r.longitude.toFixed(4) }}</code>
                </td>
                <td>
                  <span class="badge" :class="r.is_active ? 'badge-primary' : 'badge-danger'">
                    {{ r.is_active ? 'Hoạt động' : 'Tạm dừng' }}
                  </span>
                </td>
                <td style="text-align: right;">
                  <div class="action-buttons">
                    <button
                      type="button"
                      class="btn-action"
                      :title="r.is_active ? 'Tạm dừng hoạt động' : 'Kích hoạt hoạt động'"
                      @click="toggleRestaurantStatus(r)"
                    >
                      {{ r.is_active ? 'Tạm Dừng' : 'Mở Quán' }}
                    </button>
                    <button
                      type="button"
                      class="btn-action"
                      title="Chỉnh sửa thông tin cơ sở"
                      @click="openEditRestaurant(r)"
                    >
                      Sửa
                    </button>
                    <button
                      type="button"
                      class="btn-action"
                      title="Xem thực đơn của quán"
                      @click="selectRestaurantForMenu(r.id)"
                    >
                      Thực Đơn
                    </button>
                    <button
                      type="button"
                      class="btn-action btn-action-danger"
                      title="Xoá vĩnh viễn quán"
                      @click="deleteRestaurant(r)"
                    >
                      Xoá
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 3: THỰC ĐƠN & NHÓM MÓN (MENUS)             -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'menus'" class="tab-pane">
        <div class="pane-header">
          <div>
            <h2>Kiểm Duyệt Thực Đơn & Nhóm Món (Menus & Dishes)</h2>
            <p class="text-muted">Chọn một quán ăn để duyệt nhóm danh mục và danh sách món ăn đang phục vụ</p>
          </div>
          <div class="rest-selector-box">
            <label>Chọn Quán:</label>
            <select
              v-model="selectedMenuRestaurantId"
              class="input"
              style="min-width: 260px;"
              @change="loadMenuData"
            >
              <option v-for="r in restaurants" :key="r.id" :value="r.id">
                #{{ r.id }} - {{ r.name }}
              </option>
            </select>
          </div>
        </div>

        <div v-if="menuLoading" class="state-box">
          <div class="spinner"></div>
          <p>Đang nạp thực đơn của quán...</p>
        </div>

        <div v-else>
          <!-- Categories Overview -->
          <div class="section-card">
            <div class="section-header">
              <h3>Nhóm Danh Mục ({{ menuCategories.length }})</h3>
            </div>
            <div v-if="menuCategories.length === 0" class="text-muted" style="padding: 12px 0;">
              Quán chưa tạo nhóm danh mục nào.
            </div>
            <div v-else class="chips-container">
              <span v-for="c in menuCategories" :key="c.id" class="category-chip">
                <strong>{{ c.name }}</strong>
                <small v-if="c.description">({{ c.description }})</small>
              </span>
            </div>
          </div>

          <!-- Dishes Table -->
          <div class="section-card" style="margin-top: 20px;">
            <div class="section-header">
              <h3>Danh Sách Món Ăn ({{ menuDishes.length }})</h3>
            </div>

            <div v-if="menuDishes.length === 0" class="text-muted" style="padding: 12px 0;">
              Quán chưa có món ăn nào trong thực đơn.
            </div>
            <div v-else class="table-container">
              <table class="admin-table">
                <thead>
                  <tr>
                    <th style="width: 50px;">ID</th>
                    <th>Tên Món Ăn</th>
                    <th>Đơn Giá</th>
                    <th>Bữa Ăn</th>
                    <th>Nhóm Danh Mục</th>
                    <th>Thành Phần</th>
                    <th>Tình Trạng</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="d in menuDishes" :key="d.id">
                    <td>#{{ d.id }}</td>
                    <td>
                      <strong>{{ d.name }}</strong>
                      <p v-if="d.description" class="sub-cell">{{ d.description }}</p>
                    </td>
                    <td>
                      <span class="price-text">{{ Number(d.price).toLocaleString('vi-VN') }} đ</span>
                    </td>
                    <td>
                      <span class="badge badge-neutral">{{ d.meal_type }}</span>
                    </td>
                    <td>{{ d.category_name || '—' }}</td>
                    <td>
                      <span v-for="ing in (d.ingredients || [])" :key="ing" class="tag-badge">{{ ing }}</span>
                      <span v-if="!d.ingredients || d.ingredients.length === 0" class="text-muted">—</span>
                    </td>
                    <td>
                      <span class="badge" :class="d.is_available ? 'badge-primary' : 'badge-danger'">
                        {{ d.is_available ? 'Còn món' : 'Hết món' }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 4: ĐỐI TÁC & NGƯỜI DÙNG (ACCOUNTS)         -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'accounts'" class="tab-pane">
        <div class="pane-header">
          <div>
            <h2>Quản Lý Tài Khoản Đối Tác & Người Dùng</h2>
            <p class="text-muted">Danh sách các đối tác Chủ Quán (Sellers) và Thực Khách (Users) trên hệ thống</p>
          </div>
          <div class="subtab-buttons">
            <button
              type="button"
              class="btn btn-sm"
              :class="accountSubTab === 'sellers' ? 'btn-primary' : 'btn-secondary'"
              @click="accountSubTab = 'sellers'"
            >
              Chủ Quán (Sellers: {{ sellers.length }})
            </button>
            <button
              type="button"
              class="btn btn-sm"
              :class="accountSubTab === 'users' ? 'btn-primary' : 'btn-secondary'"
              @click="accountSubTab = 'users'"
            >
              Thực Khách (Users: {{ users.length }})
            </button>
          </div>
        </div>

        <div v-if="accountsLoading" class="state-box">
          <div class="spinner"></div>
          <p>Đang nạp danh sách tài khoản...</p>
        </div>

        <!-- Sellers List -->
        <div v-else-if="accountSubTab === 'sellers'" class="table-container">
          <table class="admin-table">
            <thead>
              <tr>
                <th style="width: 60px;">ID</th>
                <th>Tên Cửa Hàng (Shop)</th>
                <th>Email Đăng Nhập</th>
                <th>Họ Và Tên</th>
                <th>Số Điện Thoại</th>
                <th>Số Quán Sở Hữu</th>
                <th>Trạng Thái</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="s in sellers" :key="s.id">
                <td>#{{ s.id }}</td>
                <td><strong>{{ s.shop_name }}</strong></td>
                <td><code>{{ s.email }}</code></td>
                <td>{{ s.full_name || '—' }}</td>
                <td>{{ s.phone || '—' }}</td>
                <td>
                  <span class="badge badge-primary">{{ s.restaurant_count }} quán</span>
                </td>
                <td>
                  <span class="badge" :class="s.is_active ? 'badge-primary' : 'badge-danger'">
                    {{ s.is_active ? 'Hoạt động' : 'Khoá' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Users List -->
        <div v-else class="table-container">
          <table class="admin-table">
            <thead>
              <tr>
                <th style="width: 60px;">ID</th>
                <th>Email Đăng Ký</th>
                <th>Họ Và Tên</th>
                <th>Trạng Thái</th>
                <th>Ngày Tạo Tài Khoản</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="u in users" :key="u.id">
                <td>#{{ u.id }}</td>
                <td><code>{{ u.email }}</code></td>
                <td>{{ u.full_name || '—' }}</td>
                <td>
                  <span class="badge" :class="u.is_active ? 'badge-primary' : 'badge-danger'">
                    {{ u.is_active ? 'Hoạt động' : 'Khoá' }}
                  </span>
                </td>
                <td>{{ new Date(u.created_at).toLocaleString('vi-VN') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>

    <!-- Modal Chỉnh Sửa Quán Ăn (Admin Edit Modal) -->
    <div v-if="showEditModal" class="modal-backdrop" @click.self="showEditModal = false">
      <div class="modal-card">
        <div class="modal-header">
          <h3>Sửa Thông Tin Quán Ăn (#{{ editingRestaurant?.id }})</h3>
          <button type="button" class="modal-close" @click="showEditModal = false">×</button>
        </div>

        <form class="modal-body" @submit.prevent="saveRestaurantChanges">
          <div class="form-group">
            <label>Tên Quán Ăn *</label>
            <input v-model="editName" type="text" class="input" required />
          </div>

          <div class="form-group">
            <label>Địa Chỉ Cụ Thể *</label>
            <input v-model="editAddress" type="text" class="input" required />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Số Điện Thoại</label>
              <input v-model="editPhone" type="text" class="input" placeholder="0987..." />
            </div>
            <div class="form-group">
              <label>Trạng Thái Hoạt Động</label>
              <select v-model="editIsActive" class="input">
                <option :value="true">Hoạt động</option>
                <option :value="false">Tạm dừng</option>
              </select>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Giờ Mở Cửa (HH:MM)</label>
              <input v-model="editOpenTime" type="time" class="input" />
            </div>
            <div class="form-group">
              <label>Giờ Đóng Cửa (HH:MM)</label>
              <input v-model="editCloseTime" type="time" class="input" />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label>Vĩ Độ (Latitude)</label>
              <input v-model.number="editLat" type="number" step="any" class="input" required />
            </div>
            <div class="form-group">
              <label>Kinh Độ (Longitude)</label>
              <input v-model.number="editLon" type="number" step="any" class="input" required />
            </div>
          </div>

          <div class="form-group">
            <label>Mô Tả Giới Thiệu Quán</label>
            <textarea v-model="editDesc" class="input" rows="3"></textarea>
          </div>

          <div class="modal-actions">
            <button type="button" class="btn btn-secondary" @click="showEditModal = false">
              Hủy Bỏ
            </button>
            <button type="submit" class="btn btn-primary" :disabled="editSaving">
              {{ editSaving ? 'Đang lưu...' : 'Lưu Cập Nhật' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin-portal {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #fafafa;
}

/* Header */
.admin-header {
  background: #ffffff;
  border-bottom: 1px solid var(--c-border);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 12px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  flex-wrap: wrap;
}

.header-brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.admin-badge {
  background-color: #18181b;
  color: #ffffff;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  padding: 4px 8px;
  border-radius: 4px;
}

.brand-text h1 {
  font-size: 1.15rem;
  font-weight: 800;
  line-height: 1.2;
}

.brand-caption {
  font-size: 0.75rem;
  color: var(--c-text-muted);
}

.admin-nav {
  display: flex;
  align-items: center;
  gap: 4px;
  background-color: #f4f4f5;
  padding: 4px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
}

.nav-item {
  background: transparent;
  border: none;
  font-size: 0.88rem;
  font-weight: 500;
  color: var(--c-text-muted);
  padding: 6px 14px;
  border-radius: 6px;
  cursor: pointer;
  transition: var(--transition);
}

.nav-item:hover {
  color: var(--c-text);
}

.nav-item.active {
  color: #09090b;
  background-color: #ffffff;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.header-user {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f4f4f5;
  padding: 4px 10px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
}

.user-avatar {
  width: 26px;
  height: 26px;
  border-radius: 4px;
  background: #18181b;
  color: #ffffff;
  font-weight: 700;
  font-size: 0.8rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-email {
  font-size: 0.8rem;
  font-weight: 600;
  line-height: 1.2;
}

.user-role {
  font-size: 0.68rem;
  color: var(--c-text-muted);
}

/* Notice Bar */
.notice-bar {
  margin-top: 16px;
}

/* Main Content */
.admin-content {
  flex: 1;
  padding-top: 24px;
  padding-bottom: 40px;
  max-width: 1280px;
  margin: 0 auto;
}

.pane-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 24px;
}

.pane-header h2 {
  font-size: 1.4rem;
  font-weight: 800;
}

.text-muted {
  color: var(--c-text-muted);
  font-size: 0.9rem;
}

/* Stats KPI Cards */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.kpi-card {
  background: #ffffff;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.kpi-icon {
  font-size: 1.6rem;
  margin-bottom: 12px;
}

.kpi-value {
  font-size: 2.2rem;
  font-weight: 800;
  line-height: 1.1;
  color: #000000;
}

.kpi-label {
  font-size: 0.88rem;
  color: var(--c-text-muted);
  margin-top: 4px;
}

.kpi-footer {
  margin-top: 12px;
  padding-top: 10px;
  border-top: 1px solid #f4f4f5;
  font-size: 0.8rem;
  display: flex;
  gap: 6px;
  align-items: center;
}

.kpi-sub.green { color: #16a34a; font-weight: 600; }
.kpi-sub.red { color: #dc2626; font-weight: 600; }

/* Tech Grid */
.tech-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
  gap: 20px;
}

.tech-card {
  background: #ffffff;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 24px;
}

.tech-card h3 {
  font-size: 1.05rem;
  font-weight: 700;
  margin-bottom: 14px;
}

.tech-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.tech-list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.88rem;
}

.quick-links {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* Tables */
.table-container {
  overflow-x: auto;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  background: #ffffff;
}

.admin-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 0.9rem;
}

.admin-table th,
.admin-table td {
  padding: 12px 16px;
  border-bottom: 1px solid var(--c-border);
}

.admin-table th {
  background: #f8fafc;
  font-weight: 700;
  color: #1e293b;
  white-space: nowrap;
}

.admin-table tr:hover td {
  background: #f8fafc;
}

.name-cell strong {
  display: block;
}

.sub-cell {
  font-size: 0.78rem;
  color: var(--c-text-muted);
}

.addr-cell {
  max-width: 250px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.action-buttons {
  display: inline-flex;
  gap: 6px;
  justify-content: flex-end;
}

.btn-action {
  background: #f4f4f5;
  border: 1px solid var(--c-border);
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.btn-action:hover {
  background: #e4e4e7;
}

.btn-action-danger:hover {
  background: #fee2e2;
  border-color: #fca5a5;
  color: #b91c1c;
}

/* Filter Bar */
.filter-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.search-input {
  max-width: 380px;
}

.filter-group {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.88rem;
  font-weight: 600;
}

.filter-select {
  padding: 6px 12px;
}

/* Menus Tab */
.section-card {
  background: #ffffff;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 20px;
}

.section-header h3 {
  font-size: 1.05rem;
  font-weight: 700;
  margin-bottom: 12px;
}

.chips-container {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.category-chip {
  background: #f4f4f5;
  border: 1px solid var(--c-border);
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 0.85rem;
}

.category-chip small {
  color: var(--c-text-muted);
  margin-left: 4px;
}

.tag-badge {
  display: inline-block;
  background: #e0f2fe;
  color: #0369a1;
  font-size: 0.75rem;
  padding: 2px 6px;
  border-radius: 4px;
  margin-right: 4px;
}

.price-text {
  font-weight: 700;
  color: #0f172a;
}

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-card {
  background: #ffffff;
  border-radius: var(--radius-md);
  width: 100%;
  max-width: 560px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid var(--c-border);
}

.modal-header h3 {
  font-size: 1.15rem;
  font-weight: 700;
}

.modal-close {
  background: none;
  border: none;
  font-size: 1.4rem;
  cursor: pointer;
  color: var(--c-text-muted);
}

.modal-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-size: 0.85rem;
  font-weight: 600;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 12px;
}
</style>
