<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type {
  RoleLoginResponse,
  Weather,
  Restaurant,
  Category,
  Dish,
  SystemStats,
  AdminUser,
} from '../types';
import { api } from '../services/api';
import AppLayout from './common/AppLayout.vue';
import DashboardOverviewTab from './admin/DashboardOverviewTab.vue';
import RestaurantsTab from './admin/RestaurantsTab.vue';
import MenusTab from './admin/MenusTab.vue';
import UsersTab from './admin/UsersTab.vue';
import WeatherRulesTab from './admin/WeatherRulesTab.vue';
import { useToast } from '../composables/useToast';

const props = defineProps<{
  admin: RoleLoginResponse;
}>();

const emit = defineEmits<{
  (e: 'logout'): void;
}>();

// --- NAVIGATION STATE ---
type TabKey = 'dashboard' | 'restaurants' | 'menus' | 'accounts' | 'weather_rules';
const currentTab = ref<TabKey>('dashboard');

const { showToast } = useToast();

function handleRefreshDashboard() {
  loadStats();
  loadRestaurants();
  loadAccounts();
  loadMasterCategories();
  showToast('Đã làm mới dữ liệu tổng quan');
}

function handleDishCreated(dish: Dish) {
  menuDishes.value.unshift(dish);
  loadStats();
}

function handleDishUpdated(dish: Dish) {
  const idx = menuDishes.value.findIndex((d) => d.id === dish.id);
  if (idx !== -1) {
    menuDishes.value[idx] = dish;
  }
  loadStats();
}

function handleDishDeleted(dishId: number) {
  menuDishes.value = menuDishes.value.filter((d) => d.id !== dishId);
  loadStats();
}

function handleCategoryCreated(cat: Category) {
  masterCategories.value.push(cat);
  if (!menuCategories.value.some((c) => c.id === cat.id)) {
    menuCategories.value.push(cat);
  }
  loadStats();
}

function handleCategoryUpdated(cat: Category) {
  const updateInList = (list: Category[]) => {
    const idx = list.findIndex((c) => c.id === cat.id);
    if (idx !== -1) {
      list[idx] = { ...list[idx], ...cat };
    }
  };
  updateInList(masterCategories.value);
  updateInList(menuCategories.value);
  updateInList(globalCategories.value);
}

function handleCategoryDeleted(catId: number) {
  menuCategories.value = menuCategories.value.filter((c) => c.id !== catId);
  masterCategories.value = masterCategories.value.filter((c) => c.id !== catId);
  globalCategories.value = globalCategories.value.filter((c) => c.id !== catId);
  weatherCategoryIds.value.delete(catId);
  weatherCategoryIds.value = new Set(weatherCategoryIds.value);
  loadMenuData();
  loadStats();
}

function handleTabChange(tab: TabKey) {
  currentTab.value = tab;
  if (tab === 'menus') loadMenuData();
  else if (tab === 'accounts') loadAccounts();
  else if (tab === 'weather_rules') loadWeatherRulesData();
}

function handleRestaurantCreated(r: Restaurant) {
  restaurants.value.unshift(r);
  selectedMenuRestaurantId.value = r.id;
  loadStats();
}

function handleRestaurantUpdated(r: Restaurant) {
  const idx = restaurants.value.findIndex((item) => item.id === r.id);
  if (idx !== -1) {
    restaurants.value[idx] = r;
  }
  loadStats();
}

function handleRestaurantDeleted(id: number) {
  restaurants.value = restaurants.value.filter((r) => r.id !== id);
  if (selectedMenuRestaurantId.value === id) {
    selectedMenuRestaurantId.value = restaurants.value.length > 0 ? restaurants.value[0].id : null;
    loadMenuData();
  }
  loadStats();
}

// --- DATA STATES ---
const stats = ref<SystemStats | null>(null);
const statsLoading = ref(false);

const restaurants = ref<Restaurant[]>([]);
const restaurantsLoading = ref(false);
// Menus State
const selectedMenuRestaurantId = ref<number | null>(null);
const menuCategories = ref<Category[]>([]);
const masterCategories = ref<Category[]>([]);
const menuDishes = ref<Dish[]>([]);

const availableDishCategories = computed(() => {
  const map = new Map<number, Category>();
  for (const c of masterCategories.value) {
    map.set(c.id, c);
  }
  for (const c of menuCategories.value) {
    map.set(c.id, c);
  }
  return Array.from(map.values()).sort((a, b) => a.display_order - b.display_order || a.name.localeCompare(b.name));
});

async function loadMasterCategories() {
  try {
    masterCategories.value = await api.getAllCategories(false);
  } catch (err: any) {
    console.error('Khong the nap danh muc he thong', err);
  }
}
const menuLoading = ref(false);

// Create Dish Modal State

// Edit Dish Modal State

// Create Category Modal State

// Weather Rules State
const weathers = ref<Weather[]>([]);
const globalCategories = ref<Category[]>([]);
const weatherRulesLoading = ref(false);
const selectedWeather = ref<Weather | null>(null);
const weatherCategoryIds = ref<Set<number>>(new Set());
const weatherLinkingMap = ref<Record<number, boolean>>({});

async function loadWeatherRulesData() {
  weatherRulesLoading.value = true;
  try {
    const [wList, catList] = await Promise.all([
      api.getAllWeathers(false),
      api.getAllCategories(false),
    ]);
    weathers.value = wList;
    globalCategories.value = catList;
    if (!selectedWeather.value && wList.length > 0) {
      selectWeather(wList[0]);
    } else if (selectedWeather.value) {
      const current = (wList as Weather[]).find((w: Weather) => w.id === selectedWeather.value!.id) || wList[0];
      if (current) selectWeather(current);
    }
  } catch (err: any) {
    showError(err?.message || 'Không thể nạp dữ liệu thời tiết và danh mục');
  } finally {
    weatherRulesLoading.value = false;
  }
}

async function selectWeather(w: Weather) {
  selectedWeather.value = w;
  try {
    const linkedCats = await api.getCategoriesByWeather(w.id);
    weatherCategoryIds.value = new Set(linkedCats.map(cat => cat.id));
  } catch (err: any) {
    showError(err?.message || 'Không thể tải danh mục liên kết thời tiết');
  }
}

async function handleToggleWeatherCategory(cat: Category) {
  if (!selectedWeather.value) return;
  const wId = selectedWeather.value.id;
  const isLinked = weatherCategoryIds.value.has(cat.id);
  weatherLinkingMap.value[cat.id] = true;
  try {
    if (isLinked) {
      await api.unlinkWeatherCategory(wId, cat.id);
      weatherCategoryIds.value.delete(cat.id);
      weatherCategoryIds.value = new Set(weatherCategoryIds.value);
      showNotice(`Đã gỡ danh mục "${cat.name}" khỏi thời tiết "${selectedWeather.value.name}"`);
    } else {
      await api.linkWeatherCategory(wId, cat.id);
      weatherCategoryIds.value.add(cat.id);
      weatherCategoryIds.value = new Set(weatherCategoryIds.value);
      showNotice(`Đã liên kết danh mục "${cat.name}" vào thời tiết "${selectedWeather.value.name}"`);
    }
  } catch (err: any) {
    showError(err?.message || 'Không thể cập nhật liên kết thời tiết');
  } finally {
    weatherLinkingMap.value[cat.id] = false;
  }
}



// Accounts State
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

function handleWeatherCreated(w: Weather) {
  weathers.value.push(w);
  selectedWeather.value = w;
  weatherCategoryIds.value = new Set();
  loadStats();
}

function handleWeatherUpdated(w: Weather) {
  const idx = weathers.value.findIndex(item => item.id === w.id);
  if (idx !== -1) {
    weathers.value[idx] = { ...weathers.value[idx], ...w };
  }
  if (selectedWeather.value?.id === w.id) {
    selectedWeather.value = { ...selectedWeather.value, ...w };
  }
  loadStats();
}

function handleWeatherDeleted(id: number) {
  weathers.value = weathers.value.filter(item => item.id !== id);
  if (selectedWeather.value?.id === id) {
    selectedWeather.value = weathers.value[0] || null;
    if (selectedWeather.value) {
      selectWeather(selectedWeather.value);
    } else {
      weatherCategoryIds.value = new Set();
    }
  }
  loadStats();
}

function handleGlobalCategoryCreated(cat: Category) {
  globalCategories.value.push(cat);
  masterCategories.value.push(cat);
  loadStats();
}

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
    restaurants.value = await api.getAdminRestaurants(0);
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

let currentMenuRequestId = 0;
async function loadMenuData() {
  if (!selectedMenuRestaurantId.value) {
    menuCategories.value = [];
    menuDishes.value = [];
    return;
  }
  const reqId = ++currentMenuRequestId;
  menuLoading.value = true;
  try {
    const targetId = selectedMenuRestaurantId.value;
    const [cats, dishes] = await Promise.all([
      api.getRestaurantCategories(targetId),
      api.getRestaurantDishes(targetId),
    ]);
    if (reqId !== currentMenuRequestId) return;
    menuCategories.value = cats;
    menuDishes.value = dishes;
    if (masterCategories.value.length === 0) {
      loadMasterCategories();
    }
  } catch (err: any) {
    if (reqId !== currentMenuRequestId) return;
    showError(err.message || 'Không thể nạp dữ liệu thực đơn của quán');
  } finally {
    if (reqId === currentMenuRequestId) {
      menuLoading.value = false;
    }
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



onMounted(() => {
  loadStats();
  loadRestaurants();
  loadAccounts();
  loadMasterCategories();
});
</script>

<template>
  <AppLayout
    :current-tab="currentTab"
    :admin="admin"
    :restaurant-count="stats?.total_restaurants ?? restaurants.length"
    :user-count="stats?.total_users ?? users.length"
    :weather-count="weathers.length"
    @update:current-tab="handleTabChange($event as TabKey)"
    @logout="emit('logout')"
  >
    <!-- ============================================== -->
    <!-- TAB 1: TỔNG QUAN (DASHBOARD)                   -->
    <!-- ============================================== -->
    <DashboardOverviewTab
      v-if="currentTab === 'dashboard'"
      :stats="stats"
      :restaurants="restaurants"
      :categories="availableDishCategories"
      :users="users"
      :loading="statsLoading || restaurantsLoading"
      @refresh="handleRefreshDashboard"
      @select-restaurant-menu="selectRestaurantForMenu"
      @switch-tab="handleTabChange($event as TabKey)"
    />

    <!-- ============================================== -->
    <!-- TAB 2: QUẢN LÝ QUÁN ĂN (RESTAURANTS)           -->
    <!-- ============================================== -->
    <RestaurantsTab
      v-else-if="currentTab === 'restaurants'"
      :restaurants="restaurants"
      :loading="restaurantsLoading"
      @select-restaurant-menu="selectRestaurantForMenu"
      @restaurant-created="handleRestaurantCreated"
      @restaurant-updated="handleRestaurantUpdated"
      @restaurant-deleted="handleRestaurantDeleted"
      @refresh="loadRestaurants"
    />

    <!-- ============================================== -->
    <!-- TAB 3: QUẢN LÝ THỰC ĐƠN (MENUS)                -->
    <!-- ============================================== -->
    <!-- ============================================== -->
    <!-- TAB 3: QUẢN LÝ THỰC ĐƠN (MENUS)                -->
    <!-- ============================================== -->
    <MenusTab
      v-else-if="currentTab === 'menus'"
      :restaurants="restaurants"
      :selected-restaurant-id="selectedMenuRestaurantId"
      :categories="menuCategories"
      :master-categories="masterCategories"
      :dishes="menuDishes"
      :loading="menuLoading"
      @select-restaurant="selectRestaurantForMenu"
      @dish-created="handleDishCreated"
      @dish-updated="handleDishUpdated"
      @dish-deleted="handleDishDeleted"
      @category-created="handleCategoryCreated"
      @category-updated="handleCategoryUpdated"
      @category-deleted="handleCategoryDeleted"
      @retry="loadMenuData"
    />
      <!-- ============================================== -->
    <!-- TAB 4: QUẢN LÝ NGƯỜI DÙNG (USERS)              -->
    <!-- ============================================== -->
    <UsersTab
      v-else-if="currentTab === 'accounts'"
      :users="users"
      :categories="masterCategories"
      :loading="accountsLoading"
      @refresh="loadAccounts"
      @retry="loadAccounts"
    />

      <!-- ============================================== -->
      <!-- TAB 5: LUẬT THỜI TIẾT & DANH MỤC MÓN ĂN        -->
      <!-- ============================================== -->
      <!-- ============================================== -->
    <!-- TAB 5: QUẢN LÝ LUẬT THỜI TIẾT                  -->
    <!-- ============================================== -->
    <WeatherRulesTab
      v-else-if="currentTab === 'weather_rules'"
      :weathers="weathers"
      :global-categories="globalCategories"
      :selected-weather="selectedWeather"
      :weather-category-ids="weatherCategoryIds"
      :weather-linking-map="weatherLinkingMap"
      :loading="weatherRulesLoading"
      @select-weather="selectWeather"
      @toggle-category="handleToggleWeatherCategory"
      @weather-created="handleWeatherCreated"
      @weather-updated="handleWeatherUpdated"
      @weather-deleted="handleWeatherDeleted"
      @category-created="handleGlobalCategoryCreated"
      @category-updated="handleCategoryUpdated"
      @category-deleted="handleCategoryDeleted"
      @refresh="loadWeatherRulesData"
      @retry="loadWeatherRulesData"
    />


  </AppLayout>
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
  font-family: 'Be Vietnam Pro', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
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

.cat-edit-btn {
  background: transparent;
  border: none;
  color: #94a3b8;
  font-size: 11px;
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 4px;
  transition: color 0.15s ease;
}

.cat-edit-btn:hover {
  color: #3b82f6;
}

.cat-pill-wrapper:has(.active) .cat-edit-btn {
  color: #cbd5e1;
}

.weather-title-with-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 6px;
  flex-wrap: wrap;
}

.weather-actions-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-action-pill {
  font-size: 12px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: 6px;
  cursor: pointer;
  border: 1px solid #cbd5e1;
  background-color: #f8fafc;
  color: #334155;
  transition: all 0.15s ease;
}

.btn-action-edit:hover {
  background-color: #eff6ff;
  border-color: #93c5fd;
  color: #1d4ed8;
}

.btn-action-del:hover {
  background-color: #fef2f2;
  border-color: #fca5a5;
  color: #dc2626;
}

.weather-cat-inline-actions {
  display: flex;
  align-items: center;
  gap: 4px;
}

.cat-inline-btn {
  background: transparent;
  border: 1px solid transparent;
  border-radius: 4px;
  color: #94a3b8;
  font-size: 11px;
  cursor: pointer;
  padding: 2px 5px;
  line-height: 1;
  transition: all 0.15s ease;
}

.cat-inline-btn:hover {
  background-color: #f1f5f9;
  color: #2563eb;
  border-color: #cbd5e1;
}

.cat-inline-del:hover {
  color: #ef4444 !important;
  background-color: #fef2f2 !important;
  border-color: #fca5a5 !important;
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

/* USER DETAIL MODAL & ACCOUNTS TABLE STYLES */
.clickable-row {
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.clickable-row:hover {
  background-color: #f8fafc !important;
}
.cell-sub-code {
  font-size: 11px;
  color: #64748b;
  font-family: monospace;
}
.actions-cell {
  display: flex;
  justify-content: flex-end;
  gap: 6px;
}
.btn-tbl-action {
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 600;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  background-color: #ffffff;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-tbl-action:hover {
  background-color: #f1f5f9;
  border-color: #94a3b8;
}
.btn-tbl-warn {
  border-color: #fca5a5;
  color: #b91c1c;
  background-color: #fef2f2;
}
.btn-tbl-warn:hover {
  background-color: #fee2e2;
  border-color: #f87171;
}
.btn-tbl-success {
  border-color: #86efac;
  color: #15803d;
  background-color: #f0fdf4;
}
.btn-tbl-success:hover {
  background-color: #dcfce7;
  border-color: #4ade80;
}

.modal-sheet-user-detail {
  max-width: 680px !important;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
}
.user-detail-header-left {
  display: flex;
  align-items: center;
  gap: 14px;
}
.modal-avatar {
  width: 44px;
  height: 44px;
  font-size: 18px;
  font-weight: 700;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: #ffffff;
}
.modal-title-with-badge {
  display: flex;
  align-items: center;
  gap: 10px;
}
.modal-title-with-badge h3 {
  margin: 0;
  font-size: 17px;
  font-weight: 700;
  color: #0f172a;
}
.modal-subtitle {
  font-size: 13px;
  color: #64748b;
  margin-top: 2px;
}
.user-detail-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px 22px;
  gap: 18px;
}
.user-detail-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.detail-section {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
}
.section-title {
  margin: 0 0 12px 0;
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
}
.section-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.section-header-flex .section-title {
  margin: 0;
}
.grid-info-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 10px;
}
.info-cell {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.info-label {
  font-size: 11px;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  font-weight: 600;
}
.info-val {
  font-size: 13px;
  color: #1e293b;
  word-break: break-all;
}
.text-accent {
  color: #059669;
}
.badge-tag-success {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  background-color: #dcfce7;
  color: #166534;
}
.badge-tag-warn {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  background-color: #fef3c7;
  color: #92400e;
}

/* BMI DASHBOARD */
.bmi-dashboard-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1.3fr;
  gap: 10px;
}
.stat-box {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.highlight-bmi {
  background-color: #f0fdf4;
  border-color: #86efac;
}
.stat-label {
  font-size: 11px;
  color: #64748b;
  margin-bottom: 2px;
}
.stat-number {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
}
.bmi-badge {
  display: inline-block;
  margin-top: 4px;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
}
.bmi-normal {
  background-color: #dcfce7;
  color: #15803d;
}
.bmi-underweight {
  background-color: #e0f2fe;
  color: #0369a1;
}
.bmi-overweight {
  background-color: #ffedd5;
  color: #c2410c;
}
.bmi-obese {
  background-color: #fee2e2;
  color: #b91c1c;
}

/* TAGS GROUP */
.tags-group {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
}
.tag-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}
.tag-title {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  min-width: 140px;
}
.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.tag-item {
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
}
.diet-tag {
  background-color: #ecfdf5;
  color: #047857;
  border: 1px solid #a7f3d0;
}
.allergy-tag {
  background-color: #fef2f2;
  color: #b91c1c;
  border: 1px solid #fecaca;
}
.text-muted-desc {
  font-size: 12px;
  color: #94a3b8;
  font-style: italic;
}

/* FAVOURITE DISHES */
.tag-count-pill {
  font-size: 11px;
  font-weight: 700;
  background-color: #e2e8f0;
  color: #334155;
  padding: 2px 8px;
  border-radius: 12px;
}
.empty-fav-card {
  background-color: #ffffff;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  padding: 14px;
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
}
.fav-dishes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 8px;
}
.fav-dish-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
}
.fav-dish-title {
  font-size: 13px;
  font-weight: 600;
  color: #0f172a;
}
.fav-dish-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 4px;
  font-size: 11px;
}
.fav-price {
  color: #059669;
  font-weight: 700;
}
.fav-date {
  color: #94a3b8;
}

/* USER EDIT MODE STYLES */
.user-modal-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-edit-header {
  padding: 5px 12px;
  font-size: 13px;
  font-weight: 600;
  border-radius: 6px;
  border: 1px solid #059669;
  background-color: #ecfdf5;
  color: #047857;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-edit-header:hover {
  background-color: #d1fae5;
  color: #065f46;
}
.btn-cancel-header {
  padding: 5px 12px;
  font-size: 13px;
  font-weight: 600;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  background-color: #ffffff;
  color: #475569;
  cursor: pointer;
}
.btn-cancel-header:hover {
  background-color: #f1f5f9;
}
.btn-save-header {
  padding: 5px 14px;
  font-size: 13px;
  font-weight: 600;
  border-radius: 6px;
  border: 1px solid #059669;
  background-color: #059669;
  color: #ffffff;
  cursor: pointer;
}
.btn-save-header:hover {
  background-color: #047857;
}

.edit-form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.edit-form-grid-3 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
}
.edit-form-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.edit-field-label {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
}
.input-disabled {
  background-color: #f1f5f9 !important;
  color: #64748b !important;
  cursor: not-allowed;
}
.edit-hint {
  font-size: 11px;
  color: #94a3b8;
}
.field-select {
  padding: 8px 12px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 13px;
  color: #1e293b;
  background-color: #ffffff;
  outline: none;
  transition: border-color 0.15s ease;
}
.field-select:focus {
  border-color: #059669;
}

.edit-tag-select-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.edit-tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.tag-toggle-btn {
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 500;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.tag-toggle-btn:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}
.tag-toggle-btn.active {
  background-color: #ecfdf5;
  color: #047857;
  border-color: #10b981;
  font-weight: 600;
}
.tag-toggle-allergy.active {
  background-color: #fef2f2;
  color: #b91c1c;
  border-color: #ef4444;
}

.edit-footer-row {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 6px;
  padding-top: 10px;
  border-top: 1px solid #e2e8f0;
}


/* WEATHER RULES STYLES */
.weather-master-item {
  padding: 12px 14px;
}
.weather-item-main {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.weather-meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 2px;
}
.weather-code-pill {
  font-size: 11px;
  font-family: monospace;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #475569;
}
.weather-temp-range {
  font-size: 11px;
  color: #64748b;
  font-weight: 500;
}

.weather-rules-detail-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.weather-selected-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}
.weather-selected-title {
  margin: 0 0 6px 0;
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}
.weather-selected-desc {
  margin: 0 0 12px 0;
  font-size: 13px;
  color: #475569;
  line-height: 1.5;
}
.weather-selected-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 12px;
  color: #64748b;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
}
.weather-selected-meta strong {
  color: #0f172a;
}

.weather-category-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.section-title-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.rule-section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}
.rule-section-desc {
  font-size: 12px;
  color: #64748b;
}

.weather-category-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
}
.weather-cat-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.weather-cat-card:hover {
  border-color: #cbd5e1;
  background-color: #fafafa;
}
.weather-cat-card.is-linked {
  border-color: #86efac;
  background-color: #f0fdf4;
}
.weather-cat-card-body {
  flex: 1;
  min-width: 0;
}
.weather-cat-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 4px;
}
.weather-cat-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}
.weather-cat-status {
  font-size: 11px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
}
.status-linked {
  background-color: #dcfce7;
  color: #15803d;
}
.status-unlinked {
  background-color: #f1f5f9;
  color: #64748b;
}
.weather-cat-desc {
  margin: 0;
  font-size: 12px;
  color: #64748b;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* SWITCH TOGGLE */
.switch-toggle {
  position: relative;
  display: inline-block;
  width: 40px;
  height: 22px;
  flex-shrink: 0;
  cursor: pointer;
}
.switch-toggle input {
  opacity: 0;
  width: 0;
  height: 0;
}
.switch-slider {
  position: absolute;
  cursor: pointer;
  inset: 0;
  background-color: #cbd5e1;
  transition: 0.2s;
  border-radius: 22px;
}
.switch-slider:before {
  position: absolute;
  content: "";
  height: 16px;
  width: 16px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.2s;
  border-radius: 50%;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
}
.switch-toggle input:checked + .switch-slider {
  background-color: #10b981;
}
.switch-toggle input:checked + .switch-slider:before {
  transform: translateX(18px);
}


.weather-season-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
  background-color: #ecfdf5;
  color: #047857;
  border: 1px solid #a7f3d0;
}


.dish-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-dish-edit {
  background: transparent;
  border: none;
  color: #059669;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
  transition: all 0.15s ease;
}
.btn-dish-edit:hover {
  background-color: #ecfdf5;
  color: #047857;
}

</style>
