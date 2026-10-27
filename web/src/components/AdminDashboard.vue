<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type {
  RoleLoginResponse,
  Weather,
  Restaurant,
  Category,
  Dish,
  MealType,
  SystemStats,
  AdminUser,
  UserProfile,
  FavouriteDish,
} from '../types';
import { api } from '../services/api';

const props = defineProps<{
  admin: RoleLoginResponse;
}>();

const emit = defineEmits<{
  (e: 'logout'): void;
}>();

// --- NAVIGATION STATE ---
type TabKey = 'dashboard' | 'restaurants' | 'menus' | 'accounts' | 'weather_rules';
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

// Edit Dish Modal State
const showEditDishModal = ref(false);
const editingDish = ref<Dish | null>(null);
const editDishName = ref('');
const editDishPrice = ref(0);
const editDishDesc = ref('');
const editDishCategoryId = ref<number | null>(null);
const editDishMealType = ref<MealType>('all_day');
const editDishIngredients = ref('');
const editDishCalories = ref<number | null>(null);
const editDishSpicyLevel = ref<number>(0);
const editDishIsAvailable = ref<boolean>(true);
const editDishSaving = ref(false);

function openEditDishModal(d: Dish) {
  editingDish.value = d;
  editDishName.value = d.name;
  editDishPrice.value = d.price;
  editDishDesc.value = d.description || '';
  if (d.category_id != null) {
    editDishCategoryId.value = Number(d.category_id);
  } else if (d.category) {
    const found = masterCategories.value.find(c => c.name.toLowerCase() === d.category!.toLowerCase());
    editDishCategoryId.value = found ? found.id : null;
  } else {
    editDishCategoryId.value = null;
  }
  editDishMealType.value = ((d.meal_types && d.meal_types.length > 0) ? (d.meal_types[0] as MealType) : d.meal_type) || 'all_day';
  editDishIngredients.value = (d.ingredients && d.ingredients.length > 0) ? d.ingredients.join(', ') : '';
  editDishCalories.value = d.calories ?? null;
  editDishSpicyLevel.value = d.spicy_level ?? 0;
  editDishIsAvailable.value = d.is_available ?? true;
  showEditDishModal.value = true;
}

async function handleSaveEditDish() {
  if (!editingDish.value) return;
  if (!editDishName.value.trim()) {
    showError('Tên món ăn không được để trống');
    return;
  }
  if (editDishPrice.value < 0) {
    showError('Đơn giá món ăn không được âm');
    return;
  }
  editDishSaving.value = true;
  try {
    const ingList = editDishIngredients.value
      ? editDishIngredients.value.split(',').map(s => s.trim()).filter(Boolean)
      : [];

    const catId = (editDishCategoryId.value != null)
      ? Number(editDishCategoryId.value)
      : null;

    const payload: Partial<Dish> = {
      name: editDishName.value.trim(),
      price: Number(editDishPrice.value),
      calories: editDishCalories.value != null ? Number(editDishCalories.value) : undefined,
      description: editDishDesc.value.trim() || undefined,
      category_id: catId,
      meal_types: [editDishMealType.value],
      ingredients: ingList,
      spicy_level: editDishSpicyLevel.value,
      is_available: editDishIsAvailable.value,
    };

    const updated = await api.updateDish(editingDish.value.id, payload);
    const idx = menuDishes.value.findIndex(item => item.id === editingDish.value!.id);
    if (idx !== -1) {
      menuDishes.value[idx] = { ...menuDishes.value[idx], ...updated };
    }
    if (selectedMenuRestaurantId.value) {
      try {
        const cats = await api.getRestaurantCategories(selectedMenuRestaurantId.value);
        menuCategories.value = cats;
      } catch (_) {}
    }
    showEditDishModal.value = false;
    showNotice(`Đã cập nhật món "${updated.name}" thành công!`);
  } catch (err: any) {
    showError(err?.message || 'Không thể cập nhật món ăn');
  } finally {
    editDishSaving.value = false;
  }
}

// Create Category Modal State
const showCreateCategoryModal = ref(false);
const newCatName = ref('');
const newCatDesc = ref('');
const newCatSaving = ref(false);

// Weather Rules State
const weathers = ref<Weather[]>([]);
const globalCategories = ref<Category[]>([]);
const weatherRulesLoading = ref(false);
const selectedWeather = ref<Weather | null>(null);
const weatherCategoryIds = ref<Set<number>>(new Set());
const weatherLinkingMap = ref<Record<number, boolean>>({});
const weatherSearchQuery = ref('');
const categorySearchQuery = ref('');

// Create Weather State
const showCreateWeatherModal = ref(false);
const newWeatherName = ref('');
const newWeatherCode = ref('');
const newWeatherSeason = ref('');
const newWeatherMinTemp = ref<number | null>(null);
const newWeatherMaxTemp = ref<number | null>(null);
const newWeatherDesc = ref('');
const newWeatherSaving = ref(false);

function openCreateWeatherModal() {
  newWeatherName.value = '';
  newWeatherCode.value = '';
  newWeatherSeason.value = '';
  newWeatherMinTemp.value = null;
  newWeatherMaxTemp.value = null;
  newWeatherDesc.value = '';
  showCreateWeatherModal.value = true;
}

async function handleCreateWeather() {
  if (!newWeatherName.value.trim() || !newWeatherCode.value.trim()) {
    showError('Tên và mã định danh thời tiết không được để trống');
    return;
  }
  newWeatherSaving.value = true;
  try {
    const payload: any = {
      name: newWeatherName.value.trim(),
      code: newWeatherCode.value.trim().toLowerCase(),
      season: newWeatherSeason.value || null,
      min_temp: newWeatherMinTemp.value != null ? Number(newWeatherMinTemp.value) : null,
      max_temp: newWeatherMaxTemp.value != null ? Number(newWeatherMaxTemp.value) : null,
      description: newWeatherDesc.value.trim() || null,
      sort_order: weathers.value.length,
      is_active: true,
    };
    const created = await api.createWeather(payload);
    weathers.value.push(created);
    selectWeather(created);
    showCreateWeatherModal.value = false;
    showNotice(`Đã thêm kiểu thời tiết "${created.name}" thành công!`);
  } catch (err: any) {
    showError(err?.message || 'Không thể tạo kiểu thời tiết mới');
  } finally {
    newWeatherSaving.value = false;
  }
}

// Global Category Create State
const showCreateGlobalCatModal = ref(false);
const newGlobalCatName = ref('');
const newGlobalCatDesc = ref('');
const newGlobalCatSaving = ref(false);

const filteredWeathers = computed(() => {
  const q = weatherSearchQuery.value.trim().toLowerCase();
  if (!q) return weathers.value;
  return weathers.value.filter(
    w => w.name.toLowerCase().includes(q) || w.code.toLowerCase().includes(q) || (w.description && w.description.toLowerCase().includes(q))
  );
});

const filteredGlobalCategories = computed(() => {
  const q = categorySearchQuery.value.trim().toLowerCase();
  if (!q) return globalCategories.value;
  return globalCategories.value.filter(
    cat => cat.name.toLowerCase().includes(q) || (cat.description && cat.description.toLowerCase().includes(q))
  );
});

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

function openCreateGlobalCatModal() {
  newGlobalCatName.value = '';
  newGlobalCatDesc.value = '';
  showCreateGlobalCatModal.value = true;
}

async function handleCreateGlobalCategory() {
  if (!newGlobalCatName.value.trim()) {
    showError('Tên danh mục không được để trống');
    return;
  }
  newGlobalCatSaving.value = true;
  try {
    const created = await api.createGlobalCategory({
      name: newGlobalCatName.value.trim(),
      description: newGlobalCatDesc.value.trim() || undefined,
      is_active: true,
      display_order: globalCategories.value.length,
    });
    globalCategories.value.push(created);
    showCreateGlobalCatModal.value = false;
    showNotice(`Đã tạo danh mục "${created.name}" thành công!`);
  } catch (err: any) {
    showError(err?.message || 'Không thể tạo danh mục mới');
  } finally {
    newGlobalCatSaving.value = false;
  }
}

// Accounts State
const users = ref<AdminUser[]>([]);
const accountsLoading = ref(false);
const userSearchQuery = ref('');

// User Detail Modal State
const showUserDetailModal = ref(false);
const selectedUser = ref<AdminUser | null>(null);
const selectedUserProfile = ref<UserProfile | null>(null);
const selectedUserFavourites = ref<FavouriteDish[]>([]);
const userDetailLoading = ref(false);
const userDetailError = ref<string | null>(null);

// Edit User State
const isEditingUser = ref(false);
const userSaving = ref(false);

const editFullName = ref('');
const editHeightCm = ref<number | null>(null);
const editWeightKg = ref<number | null>(null);
const editBirthYear = ref<number | null>(null);
const editGender = ref<string>('');
const editActivityLevel = ref<string>('');
const editTargetGoal = ref<string>('');
const editSpicyTolerance = ref<string>('');
const editBudgetRange = ref<string>('');
const editDietaryPreferences = ref<string[]>([]);
const editAllergies = ref<string[]>([]);

const AVAILABLE_DIETS = [
  { key: 'clean_eating', label: 'Ăn sạch' },
  { key: 'light', label: 'Ăn thanh đạm' },
  { key: 'less_oil', label: 'Ít dầu mỡ' },
  { key: 'low_carb', label: 'Ít tinh bột' },
  { key: 'keto', label: 'Chế độ Keto' },
  { key: 'vegetarian', label: 'Ăn chay' },
  { key: 'vegan', label: 'Thuần chay' },
  { key: 'high_protein', label: 'Nhiều đạm' },
];

const AVAILABLE_ALLERGIES = [
  { key: 'seafood', label: 'Hải sản' },
  { key: 'peanut', label: 'Đậu phộng' },
  { key: 'egg', label: 'Trứng' },
  { key: 'milk', label: 'Sữa bò' },
  { key: 'gluten', label: 'Gluten / Lúa mì' },
  { key: 'soy', label: 'Đậu nành' },
];

function startEditUser() {
  if (!selectedUser.value) return;
  editFullName.value = selectedUser.value.full_name || '';
  const p = selectedUserProfile.value;
  editHeightCm.value = p?.height_cm ?? null;
  editWeightKg.value = p?.weight_kg ?? null;
  editBirthYear.value = p?.birth_year ?? null;
  editGender.value = p?.gender || '';
  editActivityLevel.value = p?.activity_level || '';
  editTargetGoal.value = p?.target_goal || '';
  editSpicyTolerance.value = p?.spicy_tolerance || '';
  editBudgetRange.value = p?.budget_range || '';
  editDietaryPreferences.value = p?.dietary_preferences ? [...p.dietary_preferences] : [];
  editAllergies.value = p?.allergies ? [...p.allergies] : [];
  isEditingUser.value = true;
}

function cancelEditUser() {
  isEditingUser.value = false;
}

function toggleDietaryPreference(key: string) {
  const idx = editDietaryPreferences.value.indexOf(key);
  if (idx >= 0) {
    editDietaryPreferences.value.splice(idx, 1);
  } else {
    editDietaryPreferences.value.push(key);
  }
}

function toggleAllergy(key: string) {
  const idx = editAllergies.value.indexOf(key);
  if (idx >= 0) {
    editAllergies.value.splice(idx, 1);
  } else {
    editAllergies.value.push(key);
  }
}

async function saveUserChanges() {
  if (!selectedUser.value) return;
  userSaving.value = true;
  try {
    const payload: any = {
      full_name: editFullName.value.trim() || null,
      height_cm: editHeightCm.value ? Number(editHeightCm.value) : null,
      weight_kg: editWeightKg.value ? Number(editWeightKg.value) : null,
      birth_year: editBirthYear.value ? Number(editBirthYear.value) : null,
      gender: editGender.value || null,
      activity_level: editActivityLevel.value || null,
      target_goal: editTargetGoal.value || null,
      spicy_tolerance: editSpicyTolerance.value || null,
      budget_range: editBudgetRange.value || null,
      dietary_preferences: editDietaryPreferences.value,
      allergies: editAllergies.value,
    };

    const updatedProfile = await api.updateUserProfile(selectedUser.value.id, payload);
    selectedUserProfile.value = updatedProfile;
    selectedUser.value.full_name = editFullName.value.trim() || null;

    const uInList = users.value.find(u => u.id === selectedUser.value!.id);
    if (uInList) {
      uInList.full_name = editFullName.value.trim() || null;
    }

    isEditingUser.value = false;
    showNotice('Cập nhật thông tin người dùng thành công!');
  } catch (err: any) {
    showError(err?.message || 'Không thể cập nhật thông tin người dùng');
  } finally {
    userSaving.value = false;
  }
}

async function openUserDetail(u: AdminUser) {
  selectedUser.value = u;
  showUserDetailModal.value = true;
  userDetailLoading.value = true;
  userDetailError.value = null;
  selectedUserProfile.value = null;
  selectedUserFavourites.value = [];
  isEditingUser.value = false;

  try {
    const [profRes, favRes] = await Promise.allSettled([
      api.getUserProfile(u.id),
      api.getUserFavourites(u.id),
    ]);
    if (profRes.status === 'fulfilled') {
      selectedUserProfile.value = profRes.value;
    }
    if (favRes.status === 'fulfilled') {
      selectedUserFavourites.value = favRes.value;
    }
  } catch (err: any) {
    userDetailError.value = err?.message || 'Không thể nạp hồ sơ người dùng';
  } finally {
    userDetailLoading.value = false;
  }
}


function getGoalLabel(goal?: string | null) {
  if (!goal) return 'Chưa thiết lập';
  const map: Record<string, string> = {
    maintain: 'Duy trì vóc dáng',
    lose_weight: 'Giảm cân & Đốt mỡ',
    gain_muscle: 'Tăng cơ & Bổ sung đạm',
    eat_healthy: 'Ăn lành mạnh',
  };
  return map[goal] || goal;
}

function getActivityLabel(lvl?: string | null) {
  if (!lvl) return 'Chưa thiết lập';
  const map: Record<string, string> = {
    sedentary: 'Ít vận động',
    light: 'Vận động nhẹ',
    moderate: 'Vận động vừa',
    active: 'Năng động',
    very_active: 'Cường độ cao',
  };
  return map[lvl] || lvl;
}

function getGenderLabel(gender?: string | null) {
  if (!gender) return 'Chưa cập nhật';
  const map: Record<string, string> = {
    male: 'Nam',
    female: 'Nữ',
    other: 'Khác',
  };
  return map[gender] || gender;
}

function getSpicyLabel(spicy?: string | null) {
  if (!spicy) return 'Chưa thiết lập';
  const map: Record<string, string> = {
    none: 'Không ăn cay',
    mild: 'Cay nhẹ',
    medium: 'Cay vừa',
    hot: 'Rất cay',
  };
  return map[spicy] || spicy;
}

function getBudgetLabel(budget?: string | null) {
  if (!budget) return 'Chưa thiết lập';
  const map: Record<string, string> = {
    budget: 'Tiết kiệm, dưới 50.000đ',
    moderate: 'Vừa phải, 50.000đ - 100.000đ',
    premium: 'Cao cấp, trên 100.000đ',
  };
  return map[budget] || budget;
}

function getBmiLabel(cat?: string | null) {
  if (!cat) return '';
  const map: Record<string, string> = {
    underweight: 'Hơi gầy',
    normal: 'Chuẩn dáng',
    overweight: 'Thừa cân',
    obese: 'Béo phì',
  };
  return map[cat] || cat;
}

function getBmiClass(cat?: string | null) {
  if (!cat) return '';
  const map: Record<string, string> = {
    underweight: 'bmi-underweight',
    normal: 'bmi-normal',
    overweight: 'bmi-overweight',
    obese: 'bmi-obese',
  };
  return map[cat] || '';
}

function getSeasonLabel(season?: string | null): string {
  if (!season) return 'Quanh năm';
  const key = season.trim().toLowerCase();
  const map: Record<string, string> = {
    spring: 'Mùa xuân',
    summer: 'Mùa hè',
    autumn: 'Mùa thu',
    winter: 'Mùa đông',
    rainy: 'Mùa mưa',
    dry: 'Mùa khô',
    all: 'Quanh năm',
  };
  return map[key] || season;
}

function getDietaryLabel(tag?: string | null): string {
  if (!tag) return '';
  const key = tag.trim().toLowerCase();
  const map: Record<string, string> = {
    clean_eating: 'Ăn sạch',
    eat_clean: 'Ăn sạch',
    'eat clean': 'Ăn sạch',
    healthy: 'Ăn lành mạnh',
    eat_healthy: 'Ăn lành mạnh',
    low_carb: 'Ít tinh bột',
    'low-carb': 'Ít tinh bột',
    keto: 'Chế độ Keto',
    vegetarian: 'Ăn chay',
    vegan: 'Thuần chay',
    high_protein: 'Nhiều đạm',
    less_oil: 'Ít dầu mỡ',
    low_fat: 'Ít chất béo',
    light: 'Ăn thanh đạm',
    gluten_free: 'Không chứa Gluten',
    dairy_free: 'Không chứa sữa',
    organic: 'Thực phẩm hữu cơ',
    halal: 'Chuẩn Halal',
    kosher: 'Chuẩn Kosher',
  };
  if (map[key]) return map[key];
  return tag.replace(/_/g, ' ');
}

function getAllergyLabel(alg?: string | null): string {
  if (!alg) return '';
  const key = alg.trim().toLowerCase();
  const map: Record<string, string> = {
    seafood: 'Hải sản',
    peanut: 'Đậu phộng',
    peanuts: 'Đậu phộng',
    egg: 'Trứng',
    eggs: 'Trứng',
    milk: 'Sữa bò',
    dairy: 'Chế phẩm từ sữa',
    gluten: 'Gluten / Lúa mì',
    wheat: 'Lúa mì',
    soy: 'Đậu nành',
    soybean: 'Đậu nành',
    fish: 'Cá',
    shellfish: 'Hải sản có vỏ',
    crustacean: 'Hải sản giáp xác',
    nut: 'Các loại hạt',
    nuts: 'Các loại hạt',
    tree_nuts: 'Hạt cây',
    sesame: 'Mè / Vừng',
    mushroom: 'Nấm',
  };
  if (map[key]) return map[key];
  return alg.replace(/_/g, ' ');
}

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
    if (masterCategories.value.length === 0) {
      loadMasterCategories();
    }
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
  newDishCategoryId.value = availableDishCategories.value.length > 0 ? availableDishCategories.value[0].id : null;
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

    const catId = (newDishCategoryId.value != null)
      ? Number(newDishCategoryId.value)
      : null;

    const created = await api.createDish(selectedMenuRestaurantId.value, {
      name: newDishName.value.trim(),
      price: Number(newDishPrice.value),
      calories: newDishCalories.value != null ? Number(newDishCalories.value) : undefined,
      description: newDishDesc.value.trim() || undefined,
      category_id: catId,
      meal_types: [newDishMealType.value],
      ingredients: ingList,
      is_available: true,
    });
    menuDishes.value.unshift(created);
    if (selectedMenuRestaurantId.value) {
      try {
        const cats = await api.getRestaurantCategories(selectedMenuRestaurantId.value);
        menuCategories.value = cats;
      } catch (_) {}
    }
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
    masterCategories.value.push(created);
    if (!menuCategories.value.some(c => c.id === created.id)) {
      menuCategories.value.push(created);
    }
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
  loadMasterCategories();
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
          <button
            type="button"
            class="nav-tab"
            :class="{ active: currentTab === 'weather_rules' }"
            @click="currentTab = 'weather_rules'; loadWeatherRulesData()"
          >
            Luật thời tiết & Danh mục
            <span class="tab-badge">{{ weathers.length }}</span>
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
                    <div class="dish-actions">
                      <button
                        type="button"
                        class="btn-dish-edit"
                        title="Chỉnh sửa chi tiết món ăn"
                        @click="openEditDishModal(d)"
                      >
                        Sửa
                      </button>
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
                <th style="text-align: right;">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="u in filteredUsers"
                :key="u.id"
                class="clickable-row"
                @click="openUserDetail(u)"
              >
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
                <td style="text-align: right;" @click.stop>
                  <div class="actions-cell">
                    <button
                      type="button"
                      class="btn-tbl-action"
                      title="Xem chi tiết thông tin và hồ sơ"
                      @click="openUserDetail(u)"
                    >
                      Xem chi tiết
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- ============================================== -->
      <!-- TAB 5: LUẬT THỜI TIẾT & DANH MỤC MÓN ĂN        -->
      <!-- ============================================== -->
      <section v-else-if="currentTab === 'weather_rules'" class="view-panel">
        <div class="view-header">
          <div>
            <h1 class="view-title">Luật thời tiết & Danh mục món ăn</h1>
            <p class="view-desc">Cấu hình các danh mục ẩm thực tự động ưu tiên gợi ý cho khách hàng theo điều kiện thời tiết</p>
          </div>
          <div class="header-actions">
            <button
              type="button"
              class="btn-refresh"
              :disabled="weatherRulesLoading"
              @click="loadWeatherRulesData"
            >
              {{ weatherRulesLoading ? 'Đang nạp...' : '↻ Làm mới' }}
            </button>
            <button
              type="button"
              class="btn-secondary-action"
              @click="openCreateWeatherModal"
            >
              + Kiểu thời tiết
            </button>
            <button
              type="button"
              class="btn-primary-action"
              @click="openCreateGlobalCatModal"
            >
              + Danh mục mới
            </button>
          </div>
        </div>

        <div v-if="weatherRulesLoading && weathers.length === 0" class="panel-loading">
          <div class="spinner-small"></div> Đang tải dữ liệu thời tiết và danh mục...
        </div>

        <div v-else class="master-detail-layout">
          <!-- Cột Master (Trái): Chọn trạng thái thời tiết -->
          <aside class="master-pane">
            <div class="master-pane-header">
              <span class="master-pane-title">Trạng thái thời tiết</span>
              <span class="tab-badge">{{ weathers.length }}</span>
            </div>
            <div class="master-search-box">
              <input
                v-model="weatherSearchQuery"
                type="text"
                placeholder="Tìm thời tiết..."
                class="master-input"
              />
            </div>

            <div class="master-list">
              <div
                v-for="w in filteredWeathers"
                :key="w.id"
                class="master-item weather-master-item"
                :class="{ active: selectedWeather?.id === w.id }"
                @click="selectWeather(w)"
              >
                <div class="weather-item-main">
                  <div class="master-title">{{ w.name }}</div>
                  <div class="weather-meta-row">
                    <span class="weather-code-pill">{{ w.code }}</span>
                    <span class="weather-season-pill">{{ getSeasonLabel(w.season) }}</span>
                    <span v-if="w.min_temp != null || w.max_temp != null" class="weather-temp-range">
                      {{ w.min_temp ?? '—' }}°C - {{ w.max_temp ?? '—' }}°C
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </aside>

          <!-- Cột Detail (Phải): Các danh mục được gán theo thời tiết đang chọn -->
          <main class="detail-pane">
            <div v-if="!selectedWeather" class="panel-empty">
              Vui lòng chọn một trạng thái thời tiết ở cột bên trái để cấu hình danh mục.
            </div>
            <div v-else class="weather-rules-detail-content">
              <!-- Banner thông tin thời tiết đang chọn -->
              <div class="weather-selected-card">
                <div class="weather-selected-info">
                  <h3 class="weather-selected-title">{{ selectedWeather.name }}</h3>
                  <p class="weather-selected-desc">
                    {{ selectedWeather.description || 'Chưa có mô tả chi tiết cho trạng thái này.' }}
                  </p>
                  <div class="weather-selected-meta">
                    <span>Mã thời tiết: <strong>{{ selectedWeather.code }}</strong></span>
                    <span>Mùa áp dụng: <strong>{{ getSeasonLabel(selectedWeather.season) }}</strong></span>
                    <span v-if="selectedWeather.min_temp != null || selectedWeather.max_temp != null">
                      Nhiệt độ: <strong>{{ selectedWeather.min_temp ?? '—' }}°C - {{ selectedWeather.max_temp ?? '—' }}°C</strong>
                    </span>
                    <span>Số danh mục đang gợi ý: <strong>{{ weatherCategoryIds.size }}</strong></span>
                  </div>
                </div>
              </div>

              <!-- Thanh tìm kiếm danh mục & tiêu đề danh mục -->
              <div class="weather-category-toolbar">
                <div class="section-title-wrap">
                  <h4 class="rule-section-title">Danh mục món ăn gợi ý</h4>
                  <span class="rule-section-desc">Gạt công tắc để tự động gợi ý danh mục này khi thời tiết đạt điều kiện trên</span>
                </div>
                <div class="search-box">
                  <input
                    v-model="categorySearchQuery"
                    type="text"
                    placeholder="Lọc danh mục món ăn..."
                    class="toolbar-input"
                  />
                </div>
              </div>

              <!-- Danh sách danh mục món ăn dạng lưới thẻ kèm Switch gạt bật/tắt -->
              <div v-if="filteredGlobalCategories.length === 0" class="panel-empty">
                Không tìm thấy danh mục món ăn nào.
              </div>
              <div v-else class="weather-category-grid">
                <div
                  v-for="cat in filteredGlobalCategories"
                  :key="cat.id"
                  class="weather-cat-card"
                  :class="{ 'is-linked': weatherCategoryIds.has(cat.id) }"
                  @click="handleToggleWeatherCategory(cat)"
                >
                  <div class="weather-cat-card-body">
                    <div class="weather-cat-title-row">
                      <span class="weather-cat-name">{{ cat.name }}</span>
                      <span
                        class="weather-cat-status"
                        :class="weatherCategoryIds.has(cat.id) ? 'status-linked' : 'status-unlinked'"
                      >
                        {{ weatherCategoryIds.has(cat.id) ? 'Đang gợi ý' : 'Không áp dụng' }}
                      </span>
                    </div>
                    <p class="weather-cat-desc">{{ cat.description || 'Danh mục hệ thống' }}</p>
                  </div>

                  <div class="weather-cat-toggle-zone" @click.stop>
                    <label class="switch-toggle" :title="weatherCategoryIds.has(cat.id) ? 'Click để bỏ gợi ý danh mục này' : 'Click để bật gợi ý danh mục này'">
                      <input
                        type="checkbox"
                        :checked="weatherCategoryIds.has(cat.id)"
                        :disabled="weatherLinkingMap[cat.id]"
                        @change="handleToggleWeatherCategory(cat)"
                      />
                      <span class="switch-slider"></span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          </main>
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
                <option v-for="c in availableDishCategories" :key="c.id" :value="c.id">
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

    <!-- ============================================== -->
    <!-- MODAL: CHI TIẾT HỒ SƠ NGƯỜI DÙNG              -->
    <!-- ============================================== -->
    <div v-if="showUserDetailModal" class="modal-backdrop" @click.self="showUserDetailModal = false">
      <div class="modal-sheet modal-sheet-user-detail">
        <div class="modal-sheet-header">
          <div class="user-detail-header-left">
            <div class="user-avatar-circle modal-avatar">
              {{ (selectedUser?.full_name || selectedUser?.email || '?').charAt(0).toUpperCase() }}
            </div>
            <div>
              <h3 style="margin: 0; font-size: 17px; font-weight: 700; color: #0f172a;">
                {{ isEditingUser ? 'Chỉnh sửa hồ sơ' : (selectedUser?.full_name || 'Khách hàng') }}
              </h3>
              <div class="modal-subtitle">{{ selectedUser?.email }}</div>
            </div>
          </div>
          <div class="user-modal-header-actions">
            <button
              v-if="!isEditingUser"
              type="button"
              class="btn-edit-header"
              :disabled="userDetailLoading"
              @click="startEditUser"
            >
              Chỉnh sửa
            </button>
            <button
              v-else
              type="button"
              class="btn-cancel-header"
              :disabled="userSaving"
              @click="cancelEditUser"
            >
              Hủy
            </button>
            <button
              v-if="isEditingUser"
              type="button"
              class="btn-save-header"
              :disabled="userSaving"
              @click="saveUserChanges"
            >
              {{ userSaving ? 'Đang lưu...' : 'Lưu' }}
            </button>
            <button type="button" class="btn-close" @click="showUserDetailModal = false">✕</button>
          </div>
        </div>

        <div class="modal-sheet-body user-detail-body">
          <div v-if="userDetailLoading" class="panel-loading">
            <div class="spinner-small"></div> Đang nạp hồ sơ người dùng...
          </div>
          <div v-else-if="userDetailError" class="panel-error">
            {{ userDetailError }}
          </div>

          <!-- CHẾ ĐỘ 1: XEM CHI TIẾT (READ-ONLY) -->
          <div v-else-if="!isEditingUser" class="user-detail-content">
            <!-- 1. THÔNG TIN TÀI KHOẢN -->
            <div class="detail-section">
              <h4 class="section-title">Thông tin tài khoản</h4>
              <div class="grid-info-cards">
                <div class="info-cell">
                  <span class="info-label">Email tài khoản</span>
                  <span class="info-val font-mono">{{ selectedUser?.email }}</span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Họ và tên</span>
                  <span class="info-val font-bold">{{ selectedUser?.full_name || 'Chưa cung cấp' }}</span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Ngày tham gia hệ thống</span>
                  <span class="info-val">{{ selectedUser?.created_at ? new Date(selectedUser.created_at).toLocaleString('vi-VN') : '—' }}</span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Trạng thái khảo sát</span>
                  <span class="info-val">
                    <span v-if="selectedUserProfile?.is_onboarded" class="badge-tag-success">Đã khảo sát</span>
                    <span v-else class="badge-tag-warn">Chưa hoàn thành</span>
                  </span>
                </div>
              </div>
            </div>

            <!-- 2. HỒ SƠ THỂ CHẤT & SỨC KHỎE (BMI) -->
            <div class="detail-section">
              <h4 class="section-title">Thể chất & Chỉ số BMI</h4>
              <div class="bmi-dashboard-row">
                <div class="stat-box">
                  <span class="stat-label">Chiều cao</span>
                  <span class="stat-number">
                    {{ selectedUserProfile?.height_cm ? `${selectedUserProfile.height_cm} cm` : '—' }}
                  </span>
                </div>
                <div class="stat-box">
                  <span class="stat-label">Cân nặng</span>
                  <span class="stat-number">
                    {{ selectedUserProfile?.weight_kg ? `${selectedUserProfile.weight_kg} kg` : '—' }}
                  </span>
                </div>
                <div class="stat-box highlight-bmi">
                  <span class="stat-label">Chỉ số BMI</span>
                  <span class="stat-number">
                    {{ selectedUserProfile?.bmi ? selectedUserProfile.bmi.toFixed(1) : '—' }}
                  </span>
                  <span v-if="selectedUserProfile?.bmi_category" class="bmi-badge" :class="getBmiClass(selectedUserProfile.bmi_category)">
                    {{ getBmiLabel(selectedUserProfile.bmi_category) }}
                  </span>
                </div>
              </div>

              <div class="grid-info-cards mt-3">
                <div class="info-cell">
                  <span class="info-label">Mục tiêu dinh dưỡng</span>
                  <span class="info-val font-bold text-accent">
                    {{ getGoalLabel(selectedUserProfile?.target_goal) }}
                  </span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Mức độ vận động</span>
                  <span class="info-val">
                    {{ getActivityLabel(selectedUserProfile?.activity_level) }}
                  </span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Giới tính</span>
                  <span class="info-val">
                    {{ getGenderLabel(selectedUserProfile?.gender) }}
                  </span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Năm sinh</span>
                  <span class="info-val">
                    {{ selectedUserProfile?.birth_year || '—' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- 3. SỞ THÍCH ẨM THỰC & KHẨU VỊ -->
            <div class="detail-section">
              <h4 class="section-title">Sở thích ẩm thực & Khẩu vị</h4>
              <div class="grid-info-cards">
                <div class="info-cell">
                  <span class="info-label">Khẩu vị ăn cay</span>
                  <span class="info-val">{{ getSpicyLabel(selectedUserProfile?.spicy_tolerance) }}</span>
                </div>
                <div class="info-cell">
                  <span class="info-label">Ngân sách mỗi bữa</span>
                  <span class="info-val">{{ getBudgetLabel(selectedUserProfile?.budget_range) }}</span>
                </div>
              </div>

              <div class="tags-group mt-3">
                <div class="tag-row">
                  <span class="tag-title">Chế độ ăn kiêng / Sở thích:</span>
                  <div v-if="selectedUserProfile?.dietary_preferences?.length" class="tag-list">
                    <span v-for="tag in selectedUserProfile.dietary_preferences" :key="tag" class="tag-item diet-tag">
                      {{ getDietaryLabel(tag) }}
                    </span>
                  </div>
                  <span v-else class="text-muted-desc">Không thiết lập chế độ đặc biệt</span>
                </div>

                <div class="tag-row mt-2">
                  <span class="tag-title">Dị ứng thực phẩm:</span>
                  <div v-if="selectedUserProfile?.allergies?.length" class="tag-list">
                    <span v-for="alg in selectedUserProfile.allergies" :key="alg" class="tag-item allergy-tag">
                      {{ getAllergyLabel(alg) }}
                    </span>
                  </div>
                  <span v-else class="text-muted-desc">Không có dị ứng</span>
                </div>
              </div>
            </div>

            <!-- 4. MÓN ĂN YÊU THÍCH -->
            <div class="detail-section">
              <div class="section-header-flex">
                <h4 class="section-title">Món ăn yêu thích đã lưu</h4>
                <span class="tag-count-pill">{{ selectedUserFavourites.length }} món</span>
              </div>
              <div v-if="selectedUserFavourites.length === 0" class="empty-fav-card">
                Thực khách chưa lưu món ăn nào vào danh sách yêu thích.
              </div>
              <div v-else class="fav-dishes-grid">
                <div v-for="fav in selectedUserFavourites" :key="fav.id" class="fav-dish-card">
                  <div class="fav-dish-title">{{ fav.dish?.name || `Món ăn` }}</div>
                  <div class="fav-dish-meta">
                    <span v-if="fav.dish?.price" class="fav-price">{{ fav.dish.price.toLocaleString('vi-VN') }}đ</span>
                    <span class="fav-date">Lưu: {{ new Date(fav.created_at).toLocaleDateString('vi-VN') }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- CHẾ ĐỘ 2: CHỈNH SỬA (FORM EDIT) -->
          <form v-else class="user-detail-content" @submit.prevent="saveUserChanges">
            <!-- 1. SỬA THÔNG TIN CƠ BẢN -->
            <div class="detail-section">
              <h4 class="section-title">Thông tin cơ bản</h4>
              <div class="edit-form-grid">
                <div class="edit-form-item">
                  <label class="edit-field-label">Email tài khoản</label>
                  <input
                    :value="selectedUser?.email"
                    type="text"
                    class="field-input input-disabled"
                    disabled
                  />
                  <span class="edit-hint">Email đăng nhập không thể thay đổi</span>
                </div>
                <div class="edit-form-item">
                  <label class="edit-field-label">Họ và tên</label>
                  <input
                    v-model="editFullName"
                    type="text"
                    class="field-input"
                    placeholder="Nhập họ và tên..."
                  />
                </div>
              </div>
            </div>

            <!-- 2. SỬA THỂ CHẤT & SỨC KHỎE -->
            <div class="detail-section">
              <h4 class="section-title">Thể chất & Mục tiêu dinh dưỡng</h4>
              <div class="edit-form-grid-3">
                <div class="edit-form-item">
                  <label class="edit-field-label">Chiều cao (cm)</label>
                  <input
                    v-model.number="editHeightCm"
                    type="number"
                    min="50"
                    max="260"
                    class="field-input"
                    placeholder="Ví dụ: 170"
                  />
                </div>
                <div class="edit-form-item">
                  <label class="edit-field-label">Cân nặng (kg)</label>
                  <input
                    v-model.number="editWeightKg"
                    type="number"
                    min="10"
                    max="500"
                    step="0.5"
                    class="field-input"
                    placeholder="Ví dụ: 65"
                  />
                </div>
                <div class="edit-form-item">
                  <label class="edit-field-label">Năm sinh</label>
                  <input
                    v-model.number="editBirthYear"
                    type="number"
                    min="1920"
                    max="2026"
                    class="field-input"
                    placeholder="Ví dụ: 1998"
                  />
                </div>
              </div>

              <div class="edit-form-grid-3 mt-3">
                <div class="edit-form-item">
                  <label class="edit-field-label">Giới tính</label>
                  <select v-model="editGender" class="field-select">
                    <option value="">Chưa chọn</option>
                    <option value="male">Nam</option>
                    <option value="female">Nữ</option>
                    <option value="other">Khác</option>
                  </select>
                </div>
                <div class="edit-form-item">
                  <label class="edit-field-label">Mức độ vận động</label>
                  <select v-model="editActivityLevel" class="field-select">
                    <option value="">Chưa chọn</option>
                    <option value="sedentary">Ít vận động</option>
                    <option value="light">Vận động nhẹ</option>
                    <option value="moderate">Vận động vừa</option>
                    <option value="active">Năng động</option>
                    <option value="very_active">Cường độ cao</option>
                  </select>
                </div>
                <div class="edit-form-item">
                  <label class="edit-field-label">Mục tiêu dinh dưỡng</label>
                  <select v-model="editTargetGoal" class="field-select">
                    <option value="">Chưa chọn</option>
                    <option value="maintain">Duy trì vóc dáng</option>
                    <option value="lose_weight">Giảm cân & Đốt mỡ</option>
                    <option value="gain_muscle">Tăng cơ & Bổ sung đạm</option>
                    <option value="eat_healthy">Ăn lành mạnh</option>
                  </select>
                </div>
              </div>
            </div>

            <!-- 3. SỬA KHẨU VỊ & NGÂN SÁCH -->
            <div class="detail-section">
              <h4 class="section-title">Khẩu vị & Chế độ ăn uống</h4>
              <div class="edit-form-grid">
                <div class="edit-form-item">
                  <label class="edit-field-label">Khẩu vị ăn cay</label>
                  <select v-model="editSpicyTolerance" class="field-select">
                    <option value="">Chưa chọn</option>
                    <option value="none">Không ăn cay</option>
                    <option value="mild">Cay nhẹ</option>
                    <option value="medium">Cay vừa</option>
                    <option value="hot">Rất cay</option>
                  </select>
                </div>
                <div class="edit-form-item">
                  <label class="edit-field-label">Ngân sách mỗi bữa</label>
                  <select v-model="editBudgetRange" class="field-select">
                    <option value="">Chưa chọn</option>
                    <option value="budget">Tiết kiệm, dưới 50.000đ</option>
                    <option value="moderate">Vừa phải, 50.000đ - 100.000đ</option>
                    <option value="premium">Cao cấp, trên 100.000đ</option>
                  </select>
                </div>
              </div>

              <!-- CHỌN CHẾ ĐỘ ĂN -->
              <div class="edit-tag-select-group mt-3">
                <label class="edit-field-label">Chế độ ăn kiêng / Sở thích:</label>
                <div class="edit-tag-list">
                  <button
                    v-for="diet in AVAILABLE_DIETS"
                    :key="diet.key"
                    type="button"
                    class="tag-toggle-btn"
                    :class="{ active: editDietaryPreferences.includes(diet.key) }"
                    @click="toggleDietaryPreference(diet.key)"
                  >
                    {{ diet.label }}
                  </button>
                </div>
              </div>

              <!-- CHỌN DỊ ỨNG -->
              <div class="edit-tag-select-group mt-3">
                <label class="edit-field-label">Dị ứng thực phẩm:</label>
                <div class="edit-tag-list">
                  <button
                    v-for="alg in AVAILABLE_ALLERGIES"
                    :key="alg.key"
                    type="button"
                    class="tag-toggle-btn tag-toggle-allergy"
                    :class="{ active: editAllergies.includes(alg.key) }"
                    @click="toggleAllergy(alg.key)"
                  >
                    {{ alg.label }}
                  </button>
                </div>
              </div>
            </div>

            <!-- NÚT LƯU CHÂN FORM -->
            <div class="edit-footer-row">
              <button
                type="button"
                class="btn-cancel"
                :disabled="userSaving"
                @click="cancelEditUser"
              >
                Hủy thay đổi
              </button>
              <button
                type="submit"
                class="btn-primary-action"
                :disabled="userSaving"
              >
                {{ userSaving ? 'Đang lưu...' : 'Lưu cập nhật' }}
              </button>
            </div>
          </form>
        </div>

      </div>
    </div>


    <!-- ============================================== -->
    <!-- MODAL: TẠO DANH MỤC HỆ THỐNG MỚI               -->
    <!-- ============================================== -->
    <div v-if="showCreateGlobalCatModal" class="modal-backdrop" @click.self="showCreateGlobalCatModal = false">
      <div class="modal-sheet" style="max-width: 460px;">
        <div class="modal-sheet-header">
          <h3>Thêm danh mục món ăn mới</h3>
          <button type="button" class="btn-close" @click="showCreateGlobalCatModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="handleCreateGlobalCategory">
          <div class="form-item">
            <label>Tên danh mục món ăn *</label>
            <input
              v-model="newGlobalCatName"
              type="text"
              class="field-input"
              placeholder="Ví dụ: Lẩu & Nướng, Đồ uống thanh nhiệt, Món cay..."
              required
            />
          </div>

          <div class="form-item">
            <label>Mô tả danh mục</label>
            <textarea
              v-model="newGlobalCatDesc"
              class="field-textarea"
              rows="3"
              placeholder="Mô tả nhóm món ăn hoặc đối tượng phục vụ..."
            ></textarea>
          </div>

          <div class="modal-sheet-footer">
            <button
              type="button"
              class="btn-cancel"
              @click="showCreateGlobalCatModal = false"
            >
              Hủy
            </button>
            <button
              type="submit"
              class="btn-primary-action"
              :disabled="newGlobalCatSaving"
            >
              {{ newGlobalCatSaving ? 'Đang tạo...' : 'Tạo danh mục' }}
            </button>
          </div>
        </form>
      </div>
    </div>


    <!-- ============================================== -->
    <!-- MODAL: TẠO KIỂU THỜI TIẾT MỚI                  -->
    <!-- ============================================== -->
    <div v-if="showCreateWeatherModal" class="modal-backdrop" @click.self="showCreateWeatherModal = false">
      <div class="modal-sheet" style="max-width: 480px;">
        <div class="modal-sheet-header">
          <h3>Thêm kiểu thời tiết mới</h3>
          <button type="button" class="btn-close" @click="showCreateWeatherModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="handleCreateWeather">
          <div class="form-item">
            <label>Tên kiểu thời tiết *</label>
            <input
              v-model="newWeatherName"
              type="text"
              class="field-input"
              placeholder="Ví dụ: Trời nồm ẩm, Gió mùa đông bắc..."
              required
            />
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Mã định danh *</label>
              <input
                v-model="newWeatherCode"
                type="text"
                class="field-input font-mono"
                placeholder="Ví dụ: humid, monsoon..."
                required
              />
            </div>
            <div class="form-item">
              <label>Mùa áp dụng</label>
              <select v-model="newWeatherSeason" class="field-select">
                <option value="">Quanh năm</option>
                <option value="spring">Mùa xuân</option>
                <option value="summer">Mùa hè</option>
                <option value="autumn">Mùa thu</option>
                <option value="winter">Mùa đông</option>
                <option value="rainy">Mùa mưa</option>
                <option value="dry">Mùa khô</option>
              </select>
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Nhiệt độ tối thiểu (°C)</label>
              <input
                v-model.number="newWeatherMinTemp"
                type="number"
                step="0.5"
                class="field-input"
                placeholder="Ví dụ: 15"
              />
            </div>
            <div class="form-item">
              <label>Nhiệt độ tối đa (°C)</label>
              <input
                v-model.number="newWeatherMaxTemp"
                type="number"
                step="0.5"
                class="field-input"
                placeholder="Ví dụ: 25"
              />
            </div>
          </div>

          <div class="form-item">
            <label>Mô tả gợi ý ẩm thực</label>
            <textarea
              v-model="newWeatherDesc"
              class="field-textarea"
              rows="3"
              placeholder="Mô tả điều kiện thời tiết và loại món ăn phù hợp nên gợi ý..."
            ></textarea>
          </div>

          <div class="modal-sheet-footer">
            <button
              type="button"
              class="btn-cancel"
              @click="showCreateWeatherModal = false"
            >
              Hủy
            </button>
            <button
              type="submit"
              class="btn-primary-action"
              :disabled="newWeatherSaving"
            >
              {{ newWeatherSaving ? 'Đang tạo...' : 'Tạo kiểu thời tiết' }}
            </button>
          </div>
        </form>
      </div>
    </div>


    <!-- ============================================== -->
    <!-- MODAL: SỬA CHI TIẾT MÓN ĂN                     -->
    <!-- ============================================== -->
    <div v-if="showEditDishModal" class="modal-backdrop" @click.self="showEditDishModal = false">
      <div class="modal-sheet">
        <div class="modal-sheet-header">
          <h3>Sửa chi tiết món ăn</h3>
          <button type="button" class="btn-close" @click="showEditDishModal = false">✕</button>
        </div>

        <form class="modal-sheet-body" @submit.prevent="handleSaveEditDish">
          <div class="form-grid-2">
            <div class="form-item">
              <label>Tên món ăn *</label>
              <input v-model="editDishName" type="text" class="field-input" placeholder="Ví dụ: Phở bò đặc biệt" required />
            </div>
            <div class="form-item">
              <label>Đơn giá (VNĐ) *</label>
              <input v-model.number="editDishPrice" type="number" min="0" step="1000" class="field-input" required />
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Bữa ăn phù hợp</label>
              <select v-model="editDishMealType" class="field-select">
                <option value="all_day">Cả ngày</option>
                <option value="breakfast">Bữa sáng</option>
                <option value="lunch">Bữa trưa</option>
                <option value="dinner">Bữa tối</option>
                <option value="snack">Ăn vặt / Xế</option>
              </select>
            </div>
            <div class="form-item">
              <label>Nhóm danh mục</label>
              <select v-model="editDishCategoryId" class="field-select">
                <option :value="null">-- Nhóm Chung --</option>
                <option v-for="c in availableDishCategories" :key="c.id" :value="c.id">
                  {{ c.name }}
                </option>
              </select>
            </div>
          </div>

          <div class="form-grid-2">
            <div class="form-item">
              <label>Năng lượng Calo (kcal)</label>
              <input v-model.number="editDishCalories" type="number" min="0" class="field-input" placeholder="Ví dụ: 550" />
            </div>
            <div class="form-item">
              <label>Độ cay</label>
              <select v-model.number="editDishSpicyLevel" class="field-select">
                <option :value="0">Không cay</option>
                <option :value="1">Cay nhẹ</option>
                <option :value="2">Cay vừa</option>
                <option :value="3">Rất cay</option>
              </select>
            </div>
          </div>

          <div class="form-item">
            <label>Trạng thái phục vụ</label>
            <select v-model="editDishIsAvailable" class="field-select">
              <option :value="true">Còn món</option>
              <option :value="false">Tạm hết món</option>
            </select>
          </div>

          <div class="form-item">
            <label>Nguyên liệu (phân tách bằng dấu phẩy)</label>
            <input v-model="editDishIngredients" type="text" class="field-input" placeholder="Thịt bò, bánh phở, hành tây, rau thơm..." />
          </div>

          <div class="form-item">
            <label>Mô tả chi tiết món</label>
            <textarea v-model="editDishDesc" class="field-textarea" rows="2" placeholder="Hương vị, định lượng..."></textarea>
          </div>

          <div class="modal-sheet-footer">
            <button type="button" class="btn-cancel" @click="showEditDishModal = false">
              Hủy
            </button>
            <button type="submit" class="btn-primary-action" :disabled="editDishSaving">
              {{ editDishSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
            </button>
          </div>
        </form>
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
