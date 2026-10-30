<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import type { AdminUser, UserProfile, Category, FavouriteDish } from '../../types';
import { api } from '../../services/api';
import { useToast } from '../../composables/useToast';
import PageHeader from '../common/PageHeader.vue';
import DataTable from '../common/DataTable.vue';
import Chip from '../common/Chip.vue';
import BaseModal from '../common/BaseModal.vue';
import ConfirmDialog from '../common/ConfirmDialog.vue';
import {
  Search,
  RefreshCw,
  Eye,
  User,
  Activity,
  Heart,
  ShieldAlert,
  UtensilsCrossed,
  Edit,
  Trash2,
} from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    users: AdminUser[];
    categories?: Category[];
    loading: boolean;
    error?: string | null;
  }>(),
  {
    categories: () => [],
    error: null,
  }
);

const emit = defineEmits<{
  (e: 'refresh'): void;
  (e: 'retry'): void;
}>();

const { showToast } = useToast();

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

// Format local date: dd/MM/yyyy HH:mm (day first, time after, local browser time, never UTC)
function formatLocalDateTime(dateStr?: string | null): string {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const pad = (n: number) => String(n).padStart(2, '0');
    const day = pad(d.getDate());
    const month = pad(d.getMonth() + 1);
    const year = d.getFullYear();
    const hours = pad(d.getHours());
    const minutes = pad(d.getMinutes());
    return `${day}/${month}/${year} ${hours}:${minutes}`;
  } catch {
    return dateStr;
  }
}

// ====================================================
// LABEL MAPPINGS
// ====================================================
const TARGET_GOAL_MAP: Record<string, string> = {
  maintain: 'Duy trì vóc dáng',
  lose_weight: 'Giảm cân',
  gain_muscle: 'Tăng cơ',
  eat_healthy: 'Ăn lành mạnh',
};

const DIETARY_MAP: Record<string, string> = {
  clean_eating: 'Clean eating',
  vegetarian: 'Ăn chay',
  vegan: 'Thuần chay',
  low_carb: 'Low carb',
  keto: 'Keto',
};

const GENDER_MAP: Record<string, string> = {
  male: 'Nam',
  female: 'Nữ',
  other: 'Khác',
};

const ACTIVITY_LEVEL_MAP: Record<string, string> = {
  sedentary: 'Ít vận động',
  light: 'Vận động nhẹ',
  moderate: 'Vận động vừa',
  active: 'Năng động',
  very_active: 'Rất năng động',
};

const SPICY_MAP: Record<string, string> = {
  none: 'Không ăn cay',
  mild: 'Cay nhẹ',
  medium: 'Cay vừa',
  hot: 'Cay nhiều',
};

const BUDGET_MAP: Record<string, string> = {
  budget: 'Tiết kiệm',
  moderate: 'Vừa phải',
  premium: 'Cao cấp',
};

const BMI_CATEGORY_MAP: Record<string, string> = {
  underweight: 'Thiếu cân / Gầy',
  normal: 'Bình thường',
  overweight: 'Thừa cân',
  obese: 'Béo phì',
};

// Map favorite category IDs to category names
const categoryMap = computed(() => {
  const map = new Map<number, string>();
  for (const c of props.categories) {
    map.set(c.id, c.name);
  }
  return map;
});

// ====================================================
// PROFILE CACHING & FETCHING
// ====================================================
const profileCache = new Map<number, UserProfile | null>();
const profileLoadingMap = ref<Record<number, boolean>>({});
const profileErrorMap = ref<Record<number, boolean>>({});
const isPreloadingProfiles = ref(false);

// Request sequence ID to prevent race conditions when changing pages/filters rapidly
let currentUsersPageReqId = 0;

interface UserChipItem {
  key: string;
  label: string;
  variant: 'ok' | 'default' | 'warn';
  group: 'goal' | 'diet' | 'allergy';
}

// Generate chip list for a user profile
function getUserChips(userId: number): UserChipItem[] {
  const p = profileCache.get(userId);
  if (!p) return [];

  const chips: UserChipItem[] = [];

  // 1. Target Goal (variant ok)
  if (p.target_goal) {
    chips.push({
      key: `goal_${p.target_goal}`,
      label: TARGET_GOAL_MAP[p.target_goal] || p.target_goal,
      variant: 'ok',
      group: 'goal',
    });
  }

  // 2. Dietary Preferences (variant default)
  if (Array.isArray(p.dietary_preferences)) {
    for (const d of p.dietary_preferences) {
      if (d) {
        chips.push({
          key: `diet_${d}`,
          label: DIETARY_MAP[d] || d,
          variant: 'default',
          group: 'diet',
        });
      }
    }
  }

  // 3. Allergies (variant warn)
  if (Array.isArray(p.allergies)) {
    for (const a of p.allergies) {
      if (a) {
        chips.push({
          key: `allergy_${a}`,
          label: a,
          variant: 'warn',
          group: 'allergy',
        });
      }
    }
  }

  return chips;
}

// Fetch single user profile
async function fetchSingleProfile(userId: number): Promise<UserProfile | null> {
  if (profileCache.has(userId)) {
    return profileCache.get(userId) || null;
  }
  try {
    profileLoadingMap.value[userId] = true;
    profileErrorMap.value[userId] = false;
    const p = await api.getUserProfile(userId);
    profileCache.set(userId, p);
    return p;
  } catch (err: any) {
    if (err?.status === 404) {
      profileCache.set(userId, null);
    } else {
      profileErrorMap.value[userId] = true;
    }
    return null;
  } finally {
    profileLoadingMap.value[userId] = false;
  }
}

// Preload all users' profiles in background if total users <= 100
async function preloadProfilesIfNeeded() {
  if (props.users.length > 100 || props.users.length === 0) return;
  const missing = props.users.filter((u) => !profileCache.has(u.id));
  if (missing.length === 0) return;

  isPreloadingProfiles.value = true;
  const concurrency = 6;
  for (let i = 0; i < missing.length; i += concurrency) {
    const chunk = missing.slice(i, i + concurrency);
    await Promise.allSettled(chunk.map((u) => fetchSingleProfile(u.id)));
  }
  isPreloadingProfiles.value = false;
}

// ====================================================
// SEARCH & DYNAMIC FILTER CHIPS
// ====================================================
const searchQuery = ref('');
const selectedFilterChip = ref<string | null>(null);
const currentPage = ref(1);
const pageSize = 10;

// Dynamic chips computed from loaded profile cache (only items with >= 1 user)
const dynamicFilterChips = computed(() => {
  if (props.users.length > 100) return [];
  const map = new Map<string, { label: string; variant: 'ok' | 'default' | 'warn'; count: number }>();

  for (const u of props.users) {
    const chips = getUserChips(u.id);
    for (const c of chips) {
      const existing = map.get(c.label);
      if (existing) {
        existing.count++;
      } else {
        map.set(c.label, { label: c.label, variant: c.variant, count: 1 });
      }
    }
  }

  return Array.from(map.values()).sort((a, b) => b.count - a.count || a.label.localeCompare(b.label));
});

function toggleFilterChip(label: string) {
  if (selectedFilterChip.value === label) {
    selectedFilterChip.value = null;
  } else {
    selectedFilterChip.value = label;
  }
  currentPage.value = 1;
}

function handleResetFilters() {
  searchQuery.value = '';
  selectedFilterChip.value = null;
  currentPage.value = 1;
}

// Reset page to 1 when search query changes
watch(searchQuery, () => {
  currentPage.value = 1;
});

// Filter users list based on unaccented search and single-select filter chip
const filteredUsers = computed(() => {
  const q = normalizeText(searchQuery.value);
  const activeChip = selectedFilterChip.value;

  return props.users.filter((u) => {
    // 1. Text Search (email and full_name, unaccented with đ/Đ handling)
    if (q) {
      const targetText = normalizeText(`${u.email} ${u.full_name || ''}`);
      if (!targetText.includes(q)) return false;
    }

    // 2. Chip Filter (target_goal, dietary_preferences, allergies)
    if (activeChip) {
      const chips = getUserChips(u.id);
      if (!chips.some((c) => c.label === activeChip)) {
        return false;
      }
    }

    return true;
  });
});

// Sliced users for current page
const pagedUsers = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredUsers.value.slice(start, start + pageSize);
});

// Fetch profiles for the current page users
async function fetchProfilesForPage() {
  const currentItems = pagedUsers.value;
  if (currentItems.length === 0) return;

  const missing = currentItems.filter((u) => !profileCache.has(u.id));
  if (missing.length === 0) return;

  const reqId = ++currentUsersPageReqId;

  for (const u of missing) {
    profileLoadingMap.value[u.id] = true;
    profileErrorMap.value[u.id] = false;
  }

  const results = await Promise.allSettled(
    missing.map(async (u) => {
      try {
        const p = await api.getUserProfile(u.id);
        return { userId: u.id, profile: p, error: false };
      } catch (err: any) {
        return { userId: u.id, profile: null, error: err?.status !== 404 };
      }
    })
  );

  if (reqId !== currentUsersPageReqId) return;

  for (const res of results) {
    if (res.status === 'fulfilled') {
      const { userId, profile, error } = res.value;
      profileCache.set(userId, profile);
      profileLoadingMap.value[userId] = false;
      if (error) profileErrorMap.value[userId] = true;
    }
  }
}

// Watch paged users to trigger profile fetching
watch(pagedUsers, () => {
  fetchProfilesForPage();
}, { immediate: true });

// Background preload when users prop changes or tab mounts
watch(() => props.users, () => {
  preloadProfilesIfNeeded();
}, { immediate: true });

onMounted(() => {
  preloadProfilesIfNeeded();
});

// ====================================================
// REFRESH ACTION
// ====================================================
const refreshing = ref(false);

async function handleRefreshClick() {
  refreshing.value = true;
  profileCache.clear();
  favouritesCache.clear();
  profileLoadingMap.value = {};
  profileErrorMap.value = {};
  emit('refresh');
  await preloadProfilesIfNeeded();
  await fetchProfilesForPage();
  refreshing.value = false;
  showToast('Đã làm mới danh sách người dùng và hồ sơ!');
}

// ====================================================

// ====================================================
// FAVOURITES CACHING & FETCHING
// ====================================================
const favouritesCache = new Map<number, FavouriteDish[]>();
const favouritesLoading = ref(false);
const favouritesError = ref<string | null>(null);
const userFavourites = ref<FavouriteDish[]>([]);

async function fetchUserFavourites(userId: number) {
  if (favouritesCache.has(userId)) {
    userFavourites.value = favouritesCache.get(userId) || [];
    return;
  }

  favouritesLoading.value = true;
  favouritesError.value = null;
  try {
    const list = await api.getUserFavourites(userId);
    favouritesCache.set(userId, list || []);
    userFavourites.value = list || [];
  } catch (err: any) {
    favouritesError.value = err?.message || 'Không thể nạp danh sách món yêu thích';
  } finally {
    favouritesLoading.value = false;
  }
}

// ====================================================
// USER PROFILE EDIT STATE & METHODS
// ====================================================
const isEditingUser = ref(false);
const userSaving = ref(false);
const showCancelEditConfirm = ref(false);

const editFullName = ref('');
const editPhone = ref('');
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

let initialEditSnapshot = '';

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
  const p = activeProfile.value;
  editPhone.value = selectedUser.value.phone || p?.phone || '';
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

  initialEditSnapshot = JSON.stringify({
    fullName: editFullName.value,
    phone: editPhone.value,
    height: editHeightCm.value,
    weight: editWeightKg.value,
    year: editBirthYear.value,
    gender: editGender.value,
    act: editActivityLevel.value,
    goal: editTargetGoal.value,
    spicy: editSpicyTolerance.value,
    budget: editBudgetRange.value,
    diet: editDietaryPreferences.value,
    alg: editAllergies.value,
  });

  isEditingUser.value = true;
}

function isFormDirty(): boolean {
  const currentSnapshot = JSON.stringify({
    fullName: editFullName.value,
    phone: editPhone.value,
    height: editHeightCm.value,
    weight: editWeightKg.value,
    year: editBirthYear.value,
    gender: editGender.value,
    act: editActivityLevel.value,
    goal: editTargetGoal.value,
    spicy: editSpicyTolerance.value,
    budget: editBudgetRange.value,
    diet: editDietaryPreferences.value,
    alg: editAllergies.value,
  });
  return currentSnapshot !== initialEditSnapshot;
}

function handleCancelEditClick() {
  if (isFormDirty()) {
    showCancelEditConfirm.value = true;
  } else {
    isEditingUser.value = false;
  }
}

function confirmCancelEdit() {
  isEditingUser.value = false;
  showCancelEditConfirm.value = false;
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

  // Validation: numbers cannot be negative or NaN
  if (editHeightCm.value != null && (isNaN(Number(editHeightCm.value)) || Number(editHeightCm.value) < 0)) {
    showToast('Chiều cao không hợp lệ');
    return;
  }
  if (editWeightKg.value != null && (isNaN(Number(editWeightKg.value)) || Number(editWeightKg.value) < 0)) {
    showToast('Cân nặng không hợp lệ');
    return;
  }
  if (editBirthYear.value != null && (isNaN(Number(editBirthYear.value)) || Number(editBirthYear.value) < 1900)) {
    showToast('Năm sinh không hợp lệ');
    return;
  }

  userSaving.value = true;
  try {
    const payload: any = {
      full_name: editFullName.value.trim() || undefined,
      phone: editPhone.value.trim() || undefined,
      height_cm: editHeightCm.value != null && !isNaN(Number(editHeightCm.value)) && Number(editHeightCm.value) > 0
        ? Number(editHeightCm.value)
        : undefined,
      weight_kg: editWeightKg.value != null && !isNaN(Number(editWeightKg.value)) && Number(editWeightKg.value) > 0
        ? Number(editWeightKg.value)
        : undefined,
      birth_year: editBirthYear.value != null && !isNaN(Number(editBirthYear.value)) && Number(editBirthYear.value) > 0
        ? Number(editBirthYear.value)
        : undefined,
      gender: editGender.value || undefined,
      activity_level: editActivityLevel.value || undefined,
      target_goal: editTargetGoal.value || undefined,
      spicy_tolerance: editSpicyTolerance.value || undefined,
      budget_range: editBudgetRange.value || undefined,
      dietary_preferences: editDietaryPreferences.value,
      allergies: editAllergies.value,
    };

    const updatedProfile = await api.updateUserProfile(selectedUser.value.id, payload);
    profileCache.set(selectedUser.value.id, updatedProfile);

    // Update in-place in selected user and users list
    selectedUser.value.full_name = payload.full_name || null;
    selectedUser.value.phone = payload.phone || null;
    const uInList = props.users.find((u) => u.id === selectedUser.value!.id);
    if (uInList) {
      uInList.full_name = payload.full_name || null;
      uInList.phone = payload.phone || null;
    }

    isEditingUser.value = false;
    showToast('Cập nhật hồ sơ người dùng thành công!');
  } catch (err: any) {
    showToast(err?.message || 'Không thể cập nhật hồ sơ người dùng');
  } finally {
    userSaving.value = false;
  }
}

// USER DETAIL MODAL
// ====================================================
const showDetailModal = ref(false);
const selectedUser = ref<AdminUser | null>(null);

function openUserDetail(u: AdminUser) {
  selectedUser.value = u;
  isEditingUser.value = false;
  showDetailModal.value = true;
  fetchSingleProfile(u.id);
  fetchUserFavourites(u.id);
}

const activeProfile = computed(() => {
  if (!selectedUser.value) return null;
  return profileCache.get(selectedUser.value.id) || null;
});

const isModalProfileLoading = computed(() => {
  if (!selectedUser.value) return false;
  return !!profileLoadingMap.value[selectedUser.value.id];
});

// ====================================================
// DELETE USER
// ====================================================
const showDeleteUserConfirm = ref(false);
const deletingUser = ref<AdminUser | null>(null);
const deleteUserLoading = ref(false);

function confirmDeleteUser(u: AdminUser | null) {
  if (!u) return;
  deletingUser.value = u;
  showDeleteUserConfirm.value = true;
}

async function handleDeleteUserSubmit() {
  if (!deletingUser.value) return;
  deleteUserLoading.value = true;
  const target = deletingUser.value;
  try {
    await api.deleteUserAsAdmin(target.id);
    showToast(`Đã xóa tài khoản "${target.email}" thành công!`);
    showDeleteUserConfirm.value = false;
    if (selectedUser.value?.id === target.id) {
      showDetailModal.value = false;
    }
    const idx = props.users.findIndex((u) => u.id === target.id);
    if (idx !== -1) {
      props.users.splice(idx, 1);
    }
    emit('refresh');
  } catch (err: any) {
    showToast(err?.message || 'Không thể xóa tài khoản người dùng');
  } finally {
    deleteUserLoading.value = false;
  }
}

function getInitialLetter(name?: string | null, email?: string): string {
  if (name && name.trim()) return name.trim().charAt(0).toUpperCase();
  if (email && email.trim()) return email.trim().charAt(0).toUpperCase();
  return '?';
}
</script>

<template>
  <div class="users-tab">
    <PageHeader
      title="Người dùng &amp; Hồ sơ dinh dưỡng"
      subtitle="Quản lý danh sách thực khách, thể trạng và mục tiêu ăn uống cá nhân hóa"
    >
      <template #actions>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="loading || refreshing"
          aria-label="Làm mới danh sách người dùng"
          @click="handleRefreshClick"
        >
          <RefreshCw class="btn-icon" :class="{ 'spin-icon': loading || refreshing }" />
          <span>{{ loading || refreshing ? 'Đang nạp...' : 'Làm mới' }}</span>
        </button>
      </template>
    </PageHeader>

    <DataTable
      v-model:current-page="currentPage"
      :total-items="filteredUsers.length"
      :page-size="pageSize"
      item-name="người dùng"
      :loading="loading"
      :error="error"
      :empty="filteredUsers.length === 0"
      empty-message="Không tìm thấy người dùng nào phù hợp với bộ lọc."
      empty-action="Đặt lại bộ lọc"
      @empty-action-click="handleResetFilters"
      @retry="emit('retry')"
    >
      <!-- Toolbar slot: Search box & dynamic filter chips -->
      <template #toolbar>
        <div class="users-toolbar">
          <!-- Unaccented search box -->
          <label class="srch" aria-label="Tìm kiếm người dùng">
            <Search class="srch-icon" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Tìm theo email, họ tên (không dấu)..."
            />
          </label>

          <!-- Dynamic filter chips (Single-select) -->
          <div v-if="users.length <= 100 && dynamicFilterChips.length > 0" class="filter-chips-bar">
            <span class="filter-label">Lọc theo tag:</span>
            <div class="chips-scroll">
              <button
                type="button"
                class="filter-chip-btn"
                :class="{ on: selectedFilterChip === null }"
                @click="selectedFilterChip = null; currentPage = 1"
              >
                Tất cả
              </button>

              <button
                v-for="chip in dynamicFilterChips"
                :key="chip.label"
                type="button"
                class="filter-chip-btn"
                :class="[chip.variant, { on: selectedFilterChip === chip.label }]"
                @click="toggleFilterChip(chip.label)"
              >
                <span>{{ chip.label }}</span>
                <span class="chip-count">{{ chip.count }}</span>
              </button>
            </div>
          </div>

          <!-- Note if users > 100 -->
          <div v-else-if="users.length > 100" class="filter-notice">
            <small>Bộ lọc tag nâng cao tạm ẩn do số lượng người dùng vượt quá 100.</small>
          </div>
        </div>
      </template>

      <!-- Table headers in default slot -->
      <thead>
        <tr>
          <th style="width: 320px;">Người dùng</th>
          <th>Hồ sơ sức khỏe &amp; Chế độ ăn</th>
          <th style="width: 170px;">Ngày tạo</th>
          <th style="width: 120px; text-align: right;">Thao tác</th>
        </tr>
      </thead>

      <!-- Table body rows in default slot -->
      <tbody>
        <tr v-for="u in pagedUsers" :key="u.id">
          <!-- Cột 1: Người dùng (Avatar chữ cái, full_name đậm, email nhỏ) -->
          <td>
            <div class="user-cell">
              <div class="user-avatar">
                {{ getInitialLetter(u.full_name, u.email) }}
              </div>
              <div class="user-meta">
                <span class="user-name">{{ u.full_name || 'Chưa đặt họ tên' }}</span>
                <span class="user-email">{{ u.email }}</span>
                <span v-if="u.phone" class="user-phone">{{ u.phone }}</span>
              </div>
            </div>
          </td>

          <!-- Cột 2: Hồ sơ sức khỏe & ăn uống -->
          <td>
            <!-- Skeleton while profile is loading -->
            <div v-if="profileLoadingMap[u.id]" class="profile-chips-skeleton">
              <div class="mini-skeleton-chip"></div>
              <div class="mini-skeleton-chip" style="width: 72px;"></div>
            </div>

            <!-- Error chip if network error occurred -->
            <div v-else-if="profileErrorMap[u.id]" class="profile-chips-wrap">
              <span class="error-chip">Không tải được</span>
            </div>

            <!-- Chips or Chưa khai báo -->
            <div v-else class="profile-chips-wrap">
              <template v-if="getUserChips(u.id).length > 0">
                <Chip
                  v-for="c in getUserChips(u.id)"
                  :key="c.key"
                  :variant="c.variant"
                >
                  {{ c.label }}
                </Chip>
              </template>
              <span v-else class="unonboarded-hint">
                Chưa khai báo
              </span>
            </div>
          </td>

          <!-- Cột 3: Ngày tạo (Local time dd/MM/yyyy HH:mm) -->
          <td>
            <span class="date-cell">
              {{ formatLocalDateTime(u.created_at) }}
            </span>
          </td>

          <!-- Cột 4: Thao tác (Nút Xem chi tiết & Xóa) -->
          <td style="text-align: right;">
            <div class="user-actions-row">
              <button
                type="button"
                class="btn-detail"
                aria-label="Xem chi tiết hồ sơ người dùng"
                @click="openUserDetail(u)"
              >
                <Eye class="detail-icon" />
                <span>Xem chi tiết</span>
              </button>
              <button
                type="button"
                class="btn-delete-user"
                title="Xóa người dùng"
                aria-label="Xóa người dùng"
                @click="confirmDeleteUser(u)"
              >
                <Trash2 class="trash-icon" />
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </DataTable>

    <!-- BaseModal: Chi tiết & Chỉnh sửa hồ sơ người dùng -->
    <BaseModal
      v-model="showDetailModal"
      :title="isEditingUser ? 'Chỉnh sửa hồ sơ người dùng' : 'Chi tiết hồ sơ người dùng'"
      :subtitle="selectedUser ? `ID: #${selectedUser.id} · ${selectedUser.email}` : ''"
      max-width="640px"
      :close-on-backdrop="!isEditingUser"
      :close-on-esc="!isEditingUser"
      :prevent-close="userSaving"
    >
      <div v-if="isModalProfileLoading && !isEditingUser" class="modal-loading-state">
        <RefreshCw class="spin-icon modal-spin" />
        <span>Đang nạp thông tin hồ sơ...</span>
      </div>

      <!-- CHẾ ĐỘ 1: XEM CHI TIẾT (READ-ONLY) -->
      <div v-else-if="selectedUser && !isEditingUser" class="modal-detail-content">
        <!-- 1. Thông tin cơ bản -->
        <section class="detail-section">
          <div class="section-heading">
            <User class="section-icon" />
            <h4>Thông tin tài khoản</h4>
          </div>
          <div class="field-grid">
            <div class="field-item">
              <span class="field-lbl">Email</span>
              <b class="field-val">{{ selectedUser.email }}</b>
            </div>
            <div class="field-item">
              <span class="field-lbl">Họ và tên</span>
              <b class="field-val">{{ selectedUser.full_name || '—' }}</b>
            </div>
            <div class="field-item">
              <span class="field-lbl">Số điện thoại</span>
              <b class="field-val">{{ selectedUser.phone || activeProfile?.phone || '—' }}</b>
            </div>
            <div class="field-item">
              <span class="field-lbl">Ngày tạo tài khoản</span>
              <span class="field-val">{{ formatLocalDateTime(selectedUser.created_at) }}</span>
            </div>
          </div>
        </section>

        <!-- 2. Thể trạng & Chỉ số BMI -->
        <section class="detail-section">
          <div class="section-heading">
            <Activity class="section-icon" />
            <h4>Thể trạng &amp; Chỉ số thể chất</h4>
          </div>
          <div class="field-grid">
            <div class="field-item">
              <span class="field-lbl">Chiều cao</span>
              <span class="field-val">
                {{ activeProfile?.height_cm ? `${activeProfile.height_cm} cm` : '—' }}
              </span>
            </div>
            <div class="field-item">
              <span class="field-lbl">Cân nặng</span>
              <span class="field-val">
                {{ activeProfile?.weight_kg ? `${activeProfile.weight_kg} kg` : '—' }}
              </span>
            </div>
            <div class="field-item">
              <span class="field-lbl">Chỉ số BMI</span>
              <span class="field-val bmi-val">
                <b>{{ activeProfile?.bmi != null ? activeProfile.bmi : '—' }}</b>
                <Chip v-if="activeProfile?.bmi_category" variant="default">
                  {{ BMI_CATEGORY_MAP[activeProfile.bmi_category] || activeProfile.bmi_category }}
                </Chip>
              </span>
            </div>
            <div class="field-item">
              <span class="field-lbl">Giới tính</span>
              <span class="field-val">
                {{ activeProfile?.gender ? (GENDER_MAP[activeProfile.gender] || activeProfile.gender) : '—' }}
              </span>
            </div>
            <div class="field-item">
              <span class="field-lbl">Năm sinh</span>
              <span class="field-val">{{ activeProfile?.birth_year || '—' }}</span>
            </div>
            <div class="field-item">
              <span class="field-lbl">Mức độ vận động</span>
              <span class="field-val">
                {{ activeProfile?.activity_level ? (ACTIVITY_LEVEL_MAP[activeProfile.activity_level] || activeProfile.activity_level) : '—' }}
              </span>
            </div>
          </div>
        </section>

        <!-- 2.5 Món ăn yêu thích (Tách biệt lỗi, có Thử lại riêng) -->
        <section class="detail-section">
          <div class="section-heading">
            <Heart class="section-icon text-warn" />
            <h4>Món ăn yêu thích ({{ userFavourites.length }})</h4>
          </div>

          <div v-if="favouritesLoading" class="fav-loading">
            <div class="mini-skeleton-chip" style="width: 140px;"></div>
            <div class="mini-skeleton-chip" style="width: 180px;"></div>
          </div>

          <div v-else-if="favouritesError" class="fav-error-box">
            <span>{{ favouritesError }}</span>
            <button
              type="button"
              class="btn btn-secondary btn-sm"
              @click="fetchUserFavourites(selectedUser.id)"
            >
              Thử lại
            </button>
          </div>

          <div v-else-if="userFavourites.length === 0" class="text-mut">
            Chưa có món yêu thích
          </div>

          <div v-else class="fav-dishes-grid">
            <div v-for="fav in userFavourites" :key="fav.id" class="fav-dish-card">
              <b class="fav-dish-name">{{ fav.dish?.name || `Món ăn #${fav.dish_id}` }}</b>
              <div class="fav-dish-meta">
                <span v-if="fav.dish?.price" class="fav-dish-price">
                  {{ fav.dish.price.toLocaleString('vi-VN') }} đ
                </span>
                <span class="fav-dish-date">
                  Đã lưu: {{ formatLocalDateTime(fav.created_at) }}
                </span>
              </div>
            </div>
          </div>
        </section>

        <!-- 3. Mục tiêu & Chế độ ăn -->
        <section class="detail-section">
          <div class="section-heading">
            <Heart class="section-icon" />
            <h4>Mục tiêu sức khỏe &amp; Chế độ ăn</h4>
          </div>
          <div class="field-grid">
            <div class="field-item full-width">
              <span class="field-lbl">Mục tiêu dinh dưỡng</span>
              <div class="field-val">
                <Chip v-if="activeProfile?.target_goal" variant="ok">
                  {{ TARGET_GOAL_MAP[activeProfile.target_goal] || activeProfile.target_goal }}
                </Chip>
                <span v-else class="text-mut">—</span>
              </div>
            </div>
            <div class="field-item full-width">
              <span class="field-lbl">Chế độ ăn kiêng / Sở thích</span>
              <div class="field-val chip-list">
                <template v-if="activeProfile?.dietary_preferences && activeProfile.dietary_preferences.length > 0">
                  <Chip
                    v-for="d in activeProfile.dietary_preferences"
                    :key="d"
                    variant="default"
                  >
                    {{ DIETARY_MAP[d] || d }}
                  </Chip>
                </template>
                <span v-else class="text-mut">—</span>
              </div>
            </div>
          </div>
        </section>

        <!-- 4. Dị ứng -->
        <section class="detail-section">
          <div class="section-heading">
            <ShieldAlert class="section-icon text-warn" />
            <h4>Thành phần dị ứng</h4>
          </div>
          <div class="chip-list">
            <template v-if="activeProfile?.allergies && activeProfile.allergies.length > 0">
              <Chip
                v-for="a in activeProfile.allergies"
                :key="a"
                variant="warn"
              >
                {{ a }}
              </Chip>
            </template>
            <span v-else class="text-mut">Không có ghi nhận thành phần dị ứng</span>
          </div>
        </section>

        <!-- 5. Khẩu vị & Ngân sách -->
        <section class="detail-section">
          <div class="section-heading">
            <UtensilsCrossed class="section-icon" />
            <h4>Khẩu vị &amp; Ngân sách</h4>
          </div>
          <div class="field-grid">
            <div class="field-item">
              <span class="field-lbl">Độ cay thích hợp</span>
              <span class="field-val">
                {{ activeProfile?.spicy_tolerance ? (SPICY_MAP[activeProfile.spicy_tolerance] || activeProfile.spicy_tolerance) : '—' }}
              </span>
            </div>
            <div class="field-item">
              <span class="field-lbl">Khung chi tiêu</span>
              <span class="field-val">
                {{ activeProfile?.budget_range ? (BUDGET_MAP[activeProfile.budget_range] || activeProfile.budget_range) : '—' }}
              </span>
            </div>
            <!-- Favorite categories if matched -->
            <div
              v-if="activeProfile?.favorite_category_ids && activeProfile.favorite_category_ids.length > 0"
              class="field-item full-width"
            >
              <span class="field-lbl">Nhóm món yêu thích</span>
              <div class="field-val chip-list">
                <Chip
                  v-for="cid in activeProfile.favorite_category_ids"
                  :key="cid"
                  variant="default"
                >
                  {{ categoryMap.get(cid) || `Nhóm #${cid}` }}
                </Chip>
              </div>
            </div>
          </div>
        </section>
      </div>

      <!-- CHẾ ĐỘ 2: CHỈNH SỬA HỒ SƠ (FORM EDIT) -->
      <form v-else id="editUserForm" class="modal-detail-content" @submit.prevent="saveUserChanges">
        <!-- 1. Thông tin cơ bản -->
        <section class="detail-section">
          <div class="section-heading">
            <User class="section-icon" />
            <h4>Thông tin cơ bản</h4>
          </div>
          <div class="field-grid">
            <div class="field-item">
              <label class="field-lbl">Email tài khoản</label>
              <input
                :value="selectedUser?.email"
                type="text"
                class="form-input"
                disabled
              />
              <small class="field-hint">Email đăng nhập không thể thay đổi</small>
            </div>
            <div class="field-item">
              <label class="field-lbl">Họ và tên</label>
              <input
                v-model="editFullName"
                type="text"
                class="form-input"
                placeholder="Nhập họ và tên..."
              />
            </div>
            <div class="field-item">
              <label class="field-lbl">Số điện thoại</label>
              <input
                v-model="editPhone"
                type="tel"
                class="form-input"
                placeholder="Ví dụ: 0912345678"
              />
            </div>
          </div>
        </section>

        <!-- 2. Thể chất & Mục tiêu dinh dưỡng -->
        <section class="detail-section">
          <div class="section-heading">
            <Activity class="section-icon" />
            <h4>Thể chất &amp; Mục tiêu dinh dưỡng</h4>
          </div>
          <div class="field-grid-3">
            <div class="field-item">
              <label class="field-lbl">Chiều cao (cm)</label>
              <input
                v-model.number="editHeightCm"
                type="number"
                min="50"
                max="260"
                class="form-input"
                placeholder="Ví dụ: 170"
              />
            </div>
            <div class="field-item">
              <label class="field-lbl">Cân nặng (kg)</label>
              <input
                v-model.number="editWeightKg"
                type="number"
                min="10"
                max="500"
                step="0.5"
                class="form-input"
                placeholder="Ví dụ: 65"
              />
            </div>
            <div class="field-item">
              <label class="field-lbl">Năm sinh</label>
              <input
                v-model.number="editBirthYear"
                type="number"
                min="1920"
                max="2026"
                class="form-input"
                placeholder="Ví dụ: 1998"
              />
            </div>
          </div>

          <div class="field-grid-3" style="margin-top: 10px;">
            <div class="field-item">
              <label class="field-lbl">Giới tính</label>
              <select v-model="editGender" class="form-input">
                <option value="">Chưa chọn</option>
                <option value="male">Nam</option>
                <option value="female">Nữ</option>
                <option value="other">Khác</option>
              </select>
            </div>
            <div class="field-item">
              <label class="field-lbl">Mức độ vận động</label>
              <select v-model="editActivityLevel" class="form-input">
                <option value="">Chưa chọn</option>
                <option value="sedentary">Ít vận động</option>
                <option value="light">Vận động nhẹ</option>
                <option value="moderate">Vận động vừa</option>
                <option value="active">Năng động</option>
                <option value="very_active">Cường độ cao</option>
              </select>
            </div>
            <div class="field-item">
              <label class="field-lbl">Mục tiêu dinh dưỡng</label>
              <select v-model="editTargetGoal" class="form-input">
                <option value="">Chưa chọn</option>
                <option value="maintain">Duy trì vóc dáng</option>
                <option value="lose_weight">Giảm cân &amp; Đốt mỡ</option>
                <option value="gain_muscle">Tăng cơ &amp; Bổ sung đạm</option>
                <option value="eat_healthy">Ăn lành mạnh</option>
              </select>
            </div>
          </div>
        </section>

        <!-- 3. Khẩu vị & Ngân sách -->
        <section class="detail-section">
          <div class="section-heading">
            <UtensilsCrossed class="section-icon" />
            <h4>Khẩu vị &amp; Chế độ ăn uống</h4>
          </div>
          <div class="field-grid">
            <div class="field-item">
              <label class="field-lbl">Khẩu vị ăn cay</label>
              <select v-model="editSpicyTolerance" class="form-input">
                <option value="">Chưa chọn</option>
                <option value="none">Không ăn cay</option>
                <option value="mild">Cay nhẹ</option>
                <option value="medium">Cay vừa</option>
                <option value="hot">Rất cay</option>
              </select>
            </div>
            <div class="field-item">
              <label class="field-lbl">Ngân sách mỗi bữa</label>
              <select v-model="editBudgetRange" class="form-input">
                <option value="">Chưa chọn</option>
                <option value="budget">Tiết kiệm, dưới 50.000đ</option>
                <option value="moderate">Vừa phải, 50.000đ - 100.000đ</option>
                <option value="premium">Cao cấp, trên 100.000đ</option>
              </select>
            </div>
          </div>

          <!-- Chế độ ăn kiêng / Sở thích -->
          <div class="tag-selector-group" style="margin-top: 12px;">
            <label class="field-lbl">Chế độ ăn kiêng / Sở thích:</label>
            <div class="tag-selector-list">
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

          <!-- Dị ứng thực phẩm -->
          <div class="tag-selector-group" style="margin-top: 12px;">
            <label class="field-lbl">Dị ứng thực phẩm:</label>
            <div class="tag-selector-list">
              <button
                v-for="alg in AVAILABLE_ALLERGIES"
                :key="alg.key"
                type="button"
                class="tag-toggle-btn tag-allergy-btn"
                :class="{ active: editAllergies.includes(alg.key) }"
                @click="toggleAllergy(alg.key)"
              >
                {{ alg.label }}
              </button>
            </div>
          </div>
        </section>
      </form>

      <template #footer>
        <!-- Footer chế độ Xem chi tiết -->
        <template v-if="!isEditingUser">
          <button
            type="button"
            class="btn btn-danger"
            style="margin-right: auto;"
            title="Xóa vĩnh viễn tài khoản người dùng này"
            @click="confirmDeleteUser(selectedUser)"
          >
            <Trash2 class="btn-icon" />
            <span>Xóa tài khoản</span>
          </button>
          <button
            type="button"
            class="btn btn-secondary"
            @click="showDetailModal = false"
          >
            Đóng
          </button>
          <button
            type="button"
            class="btn btn-primary"
            :disabled="isModalProfileLoading"
            @click="startEditUser"
          >
            <Edit class="btn-icon" />
            <span>Chỉnh sửa</span>
          </button>
        </template>

        <!-- Footer chế độ Chỉnh sửa -->
        <template v-else>
          <button
            type="button"
            class="btn btn-secondary"
            :disabled="userSaving"
            @click="handleCancelEditClick"
          >
            Hủy
          </button>
          <button
            type="submit"
            form="editUserForm"
            class="btn btn-primary"
            :disabled="userSaving"
          >
            {{ userSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
          </button>
        </template>
      </template>
    </BaseModal>

    <!-- ConfirmDialog: Xác nhận hủy thay đổi khi đang sửa -->
    <ConfirmDialog
      v-model="showCancelEditConfirm"
      title="Hủy các thay đổi?"
      message="Bạn đang có các thông tin đã chỉnh sửa nhưng chưa lưu. Bạn có chắc chắn muốn hủy và quay về chế độ xem không?"
      confirm-text="Hủy thay đổi"
      cancel-text="Tiếp tục sửa"
      :danger="true"
      @confirm="confirmCancelEdit"
    />

    <!-- ConfirmDialog: Xác nhận xóa người dùng -->
    <ConfirmDialog
      v-model="showDeleteUserConfirm"
      title="Xác nhận xóa tài khoản người dùng"
      :message="`Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản '${deletingUser?.email}' (${deletingUser?.full_name || 'Chưa đặt tên'})? Toàn bộ hồ sơ sức khỏe, danh mục yêu thích và tùy chọn của người dùng này sẽ bị xóa khỏi hệ thống.`"
      confirm-text="Xóa vĩnh viễn"
      cancel-text="Hủy"
      :danger="true"
      :loading="deleteUserLoading"
      @confirm="handleDeleteUserSubmit"
    />
  </div>
</template>

<style scoped>
.user-actions-row {
  display: inline-flex;
  gap: 8px;
  align-items: center;
  justify-content: flex-end;
}

.btn-delete-user {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: var(--card);
  color: var(--mut);
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-delete-user:hover {
  border-color: var(--bad, #ef4444);
  color: var(--bad, #ef4444);
  background: var(--bad-s, #fee2e2);
}

.trash-icon {
  width: 15px;
  height: 15px;
}

.users-tab {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.btn-icon {
  width: 15px;
  height: 15px;
}

.spin-icon {
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

/* Toolbar */
.users-toolbar {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
}

.srch {
  max-width: 380px;
}

.srch-icon {
  width: 15px;
  height: 15px;
  color: var(--mut);
  flex: none;
}

/* Dynamic filter chips bar */
.filter-chips-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 2px;
}

.filter-label {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--mut);
  white-space: nowrap;
}

.chips-scroll {
  display: flex;
  gap: 6px;
  align-items: center;
  flex-wrap: wrap;
}

.filter-chip-btn {
  border: 1px solid var(--line);
  background: var(--card);
  padding: 4px 10px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 500;
  color: var(--mut);
  white-space: nowrap;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.filter-chip-btn:hover {
  border-color: var(--pri);
  color: var(--ink);
}

.filter-chip-btn.on {
  background: var(--pri);
  border-color: var(--pri);
  color: #fff;
  font-weight: 600;
}

.filter-chip-btn.ok.on {
  background: var(--ok);
  border-color: var(--ok);
  color: #fff;
}

.filter-chip-btn.warn.on {
  background: var(--warn);
  border-color: var(--warn);
  color: #2b1800;
}

.chip-count {
  font-size: 10.5px;
  background: color-mix(in srgb, currentColor 18%, transparent);
  padding: 1px 5px;
  border-radius: 99px;
}

.filter-notice {
  color: var(--mut);
  font-style: italic;
}

/* User cell */
.user-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: var(--pri-s);
  color: var(--pri);
  font-weight: 700;
  font-size: 14px;
  display: grid;
  place-items: center;
  flex: none;
  border: 1px solid color-mix(in srgb, var(--pri) 20%, transparent);
}

.user-meta {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.user-name {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--ink);
  line-height: 1.3;
}

.user-email {
  font-size: 12px;
  color: var(--mut);
  line-height: 1.3;
}

.user-phone {
  font-size: 11.5px;
  color: var(--mut);
  line-height: 1.3;
}

/* Profile chips */
.profile-chips-wrap {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  align-items: center;
}

.unonboarded-hint {
  font-size: 12px;
  color: var(--mut);
  font-style: italic;
  opacity: 0.8;
}

.error-chip {
  font-size: 11.5px;
  color: var(--bad);
  background: var(--bad-s);
  padding: 2px 8px;
  border-radius: 99px;
  border: 1px solid color-mix(in srgb, var(--bad) 30%, transparent);
}

/* Mini skeleton for chips */
.profile-chips-skeleton {
  display: flex;
  gap: 6px;
}

.mini-skeleton-chip {
  width: 60px;
  height: 22px;
  border-radius: 99px;
  background: var(--bg);
  animation: pulse 1.2s infinite ease-in-out;
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
  .mini-skeleton-chip {
    animation: none;
    opacity: 0.4;
  }
}

.date-cell {
  font-size: 12.5px;
  color: var(--mut);
  font-variant-numeric: tabular-nums;
}

/* Detail button */
.btn-detail {
  border: 1px solid var(--line);
  background: var(--card);
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: var(--mut);
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-detail:hover {
  background: var(--bg);
  color: var(--pri);
  border-color: var(--pri);
}

.detail-icon {
  width: 13px;
  height: 13px;
}

/* Modal detail styling */
.modal-loading-state {
  padding: 40px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: var(--mut);
}

.modal-spin {
  width: 24px;
  height: 24px;
  color: var(--pri);
}

.modal-detail-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--line);
}

.detail-section:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.section-heading {
  display: flex;
  align-items: center;
  gap: 8px;
}

.section-icon {
  width: 16px;
  height: 16px;
  color: var(--pri);
}

.section-icon.text-warn {
  color: var(--warn);
}

.section-heading h4 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink);
}

.field-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.field-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.field-item.full-width {
  grid-column: 1 / -1;
}

.field-lbl {
  font-size: 11.5px;
  color: var(--mut);
  text-transform: uppercase;
  letter-spacing: 0.03em;
  font-weight: 600;
}

.field-val {
  font-size: 13.5px;
  color: var(--ink);
}

.field-val.bmi-val {
  display: flex;
  align-items: center;
  gap: 8px;
}

.chip-list {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.text-mut {
  color: var(--mut);
  font-size: 13px;
}

.field-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

@media (max-width: 600px) {
  .field-grid-3 {
    grid-template-columns: 1fr;
  }
}

.field-hint {
  font-size: 11px;
  color: var(--mut);
  margin-top: 2px;
}

.fav-loading {
  display: flex;
  gap: 8px;
}

.fav-error-box {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--bad);
  font-size: 12.5px;
}

.fav-dishes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 8px;
}

.fav-dish-card {
  padding: 8px 10px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--bg);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.fav-dish-name {
  font-size: 13px;
  color: var(--ink);
  line-height: 1.3;
}

.fav-dish-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11.5px;
}

.fav-dish-price {
  font-weight: 600;
  color: var(--pri);
}

.fav-dish-date {
  color: var(--mut);
}

/* Tag toggle buttons in edit form */
.tag-selector-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.tag-selector-list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.tag-toggle-btn {
  border: 1px solid var(--line);
  background: var(--card);
  padding: 5px 10px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 500;
  color: var(--mut);
  cursor: pointer;
  transition: all 0.15s ease;
}

.tag-toggle-btn:hover {
  border-color: var(--pri);
  color: var(--ink);
}

.tag-toggle-btn.active {
  background: var(--pri);
  border-color: var(--pri);
  color: #ffffff;
  font-weight: 600;
}

.tag-toggle-btn.tag-allergy-btn.active {
  background: var(--warn);
  border-color: var(--warn);
  color: #2b1800;
}

</style>
