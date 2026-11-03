<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue';
import type { Weather, Category } from '../../types';
import { api } from '../../services/api';
import { useToast } from '../../composables/useToast';
import PageHeader from '../common/PageHeader.vue';
import Chip from '../common/Chip.vue';
import BaseModal from '../common/BaseModal.vue';
import ConfirmDialog from '../common/ConfirmDialog.vue';
import SwitchToggle from '../common/SwitchToggle.vue';
import RowActionMenu from '../common/RowActionMenu.vue';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  RefreshCw,
  CloudSun,
  Thermometer,
  Layers,
  Clock,
} from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    weathers: Weather[];
    globalCategories: Category[];
    selectedWeather: Weather | null;
    weatherCategoryIds: Set<number>;
    weatherLinkingMap?: Record<number, boolean>;
    loading: boolean;
    error?: string | null;
  }>(),
  {
    weatherLinkingMap: () => ({}),
    error: null,
  }
);

const emit = defineEmits<{
  (e: 'selectWeather', weather: Weather): void;
  (e: 'toggleCategory', category: Category): void;
  (e: 'weatherCreated', weather: Weather): void;
  (e: 'weatherUpdated', weather: Weather): void;
  (e: 'weatherDeleted', weatherId: number): void;
  (e: 'categoryCreated', category: Category): void;
  (e: 'categoryUpdated', category: Category): void;
  (e: 'categoryDeleted', categoryId: number): void;
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

function formatHour12h(hour?: number | null): string {
  if (hour == null || isNaN(hour)) return '';
  const suffix = hour < 12 ? 'AM' : 'PM';
  const h12 = hour % 12 || 12;
  return `${h12}:00 ${suffix}`;
}

// Master list search & season filter state (left pane)
const weatherSearchQuery = ref('');
const weatherSeasonFilter = ref('all');
const masterListScrollEl = ref<HTMLElement | null>(null);

const availableSeasons = computed(() => {
  const counts: Record<string, number> = {
    all: props.weathers.length,
  };
  for (const w of props.weathers) {
    const s = (w.season || 'all').toLowerCase();
    counts[s] = (counts[s] || 0) + 1;
  }
  return counts;
});

const filteredWeathers = computed(() => {
  const q = normalizeText(weatherSearchQuery.value);
  const s = weatherSeasonFilter.value;
  return props.weathers.filter((w) => {
    if (s !== 'all' && (w.season || '').toLowerCase() !== s.toLowerCase()) {
      return false;
    }
    if (!q) return true;
    const textTarget = normalizeText(
      `${w.name} ${w.code} ${w.hour_display || formatHour12h(w.hour)} ${getSeasonLabel(w.season)} ${w.description || ''} ${w.temperature ?? ''} ${w.humidity ?? ''} ${w.min_temp ?? ''} ${w.max_temp ?? ''}`
    );
    return textTarget.includes(q);
  });
});

// Master list pagination
const weatherCurrentPage = ref(1);
const weatherPageSize = ref(10);

const weatherTotalPages = computed(() =>
  Math.max(1, Math.ceil(filteredWeathers.value.length / weatherPageSize.value))
);

const pagedWeathers = computed(() => {
  const start = (weatherCurrentPage.value - 1) * weatherPageSize.value;
  return filteredWeathers.value.slice(start, start + weatherPageSize.value);
});

const weatherFromItem = computed(() =>
  filteredWeathers.value.length === 0
    ? 0
    : (weatherCurrentPage.value - 1) * weatherPageSize.value + 1
);

const weatherToItem = computed(() =>
  Math.min(
    weatherCurrentPage.value * weatherPageSize.value,
    filteredWeathers.value.length
  )
);

function setWeatherPage(p: number) {
  if (p >= 1 && p <= weatherTotalPages.value) {
    weatherCurrentPage.value = p;
    if (masterListScrollEl.value) {
      masterListScrollEl.value.scrollTop = 0;
    }
  }
}

watch([weatherSearchQuery, weatherSeasonFilter, weatherPageSize], () => {
  weatherCurrentPage.value = 1;
});

watch(weatherTotalPages, (max) => {
  if (weatherCurrentPage.value > max) {
    weatherCurrentPage.value = max;
  }
});

const isSelectedWeatherOnCurrentPage = computed(() => {
  if (!props.selectedWeather) return false;
  return pagedWeathers.value.some((w) => w.id === props.selectedWeather?.id);
});

function jumpToSelectedWeatherPage() {
  if (!props.selectedWeather) return;
  if (
    weatherSeasonFilter.value !== 'all' &&
    (props.selectedWeather.season || '').toLowerCase() !== weatherSeasonFilter.value.toLowerCase()
  ) {
    weatherSeasonFilter.value = 'all';
  }
  weatherSearchQuery.value = '';
  nextTick(() => {
    const idx = filteredWeathers.value.findIndex((w) => w.id === props.selectedWeather?.id);
    if (idx !== -1) {
      weatherCurrentPage.value = Math.floor(idx / weatherPageSize.value) + 1;
      nextTick(() => {
        const activeEl = masterListScrollEl.value?.querySelector('.li.on') as HTMLElement | null;
        if (activeEl) {
          activeEl.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
      });
    }
  });
}

// Category search & filter (right pane)
const categorySearchQuery = ref('');
type CategoryFilterMode = 'all' | 'linked' | 'unlinked';
const categoryFilterMode = ref<CategoryFilterMode>('all');

const filteredCategories = computed(() => {
  const q = normalizeText(categorySearchQuery.value);
  const mode = categoryFilterMode.value;

  return props.globalCategories.filter((cat) => {
    // 1. Text filter
    if (q) {
      const targetText = normalizeText(`${cat.name} ${cat.description || ''}`);
      if (!targetText.includes(q)) return false;
    }

    // 2. Linked status filter
    const isLinked = props.weatherCategoryIds.has(cat.id);
    if (mode === 'linked' && !isLinked) return false;
    if (mode === 'unlinked' && isLinked) return false;

    return true;
  });
});

// Auto-scroll selected weather into view in left pane
watch(
  () => props.selectedWeather?.id,
  (newId) => {
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

// Number of categories linked to current weather
const linkedCount = computed(() => {
  let count = 0;
  for (const cat of props.globalCategories) {
    if (props.weatherCategoryIds.has(cat.id)) count++;
  }
  return count;
});

// ====================================================
// MODAL: TẠO KIỂU THỜI TIẾT
// ====================================================
const showCreateWeatherModal = ref(false);
const newWeatherName = ref('');
const newWeatherCode = ref('');
const newWeatherSeason = ref('summer');
const newWeatherMinTemp = ref<number | null>(null);
const newWeatherMaxTemp = ref<number | null>(null);
const newWeatherMinHumidity = ref<number | null>(null);
const newWeatherMaxHumidity = ref<number | null>(null);
const newWeatherDesc = ref('');
const newWeatherSaving = ref(false);

function openCreateWeatherModal() {
  newWeatherName.value = '';
  newWeatherCode.value = '';
  newWeatherSeason.value = 'summer';
  newWeatherMinTemp.value = null;
  newWeatherMaxTemp.value = null;
  newWeatherMinHumidity.value = null;
  newWeatherMaxHumidity.value = null;
  newWeatherDesc.value = '';
  showCreateWeatherModal.value = true;
}

async function handleCreateWeatherSubmit() {
  if (!newWeatherName.value.trim() || !newWeatherCode.value.trim()) {
    showToast('Tên và mã định danh thời tiết không được để trống');
    return;
  }

  if (
    newWeatherMinTemp.value != null &&
    newWeatherMaxTemp.value != null &&
    Number(newWeatherMinTemp.value) > Number(newWeatherMaxTemp.value)
  ) {
    showToast('Nhiệt độ tối thiểu không được lớn hơn nhiệt độ tối đa');
    return;
  }

  if (
    newWeatherMinHumidity.value != null &&
    newWeatherMaxHumidity.value != null &&
    Number(newWeatherMinHumidity.value) > Number(newWeatherMaxHumidity.value)
  ) {
    showToast('Độ ẩm tối thiểu không được lớn hơn độ ẩm tối đa');
    return;
  }

  if (
    (newWeatherMinHumidity.value != null && (Number(newWeatherMinHumidity.value) < 0 || Number(newWeatherMinHumidity.value) > 100)) ||
    (newWeatherMaxHumidity.value != null && (Number(newWeatherMaxHumidity.value) < 0 || Number(newWeatherMaxHumidity.value) > 100))
  ) {
    showToast('Độ ẩm phải nằm trong khoảng từ 0% đến 100%');
    return;
  }

  newWeatherSaving.value = true;
  try {
    const payload: Partial<Weather> = {
      name: newWeatherName.value.trim(),
      code: newWeatherCode.value.trim().toLowerCase(),
      season: newWeatherSeason.value || null,
      temperature: newWeatherMinTemp.value != null ? Number(newWeatherMinTemp.value) : null,
      humidity: newWeatherMinHumidity.value != null ? Number(newWeatherMinHumidity.value) : null,
      description: newWeatherDesc.value.trim() || null,
      is_active: true,
      condition: 'clear',
      icon: 'weather-partly-cloudy',
      sort_order: props.weathers.length + 1,
    };

    const created = await api.createWeather(payload);
    emit('weatherCreated', created);
    showToast(`Đã thêm kiểu thời tiết "${created.name}" thành công!`);
    showCreateWeatherModal.value = false;
    weatherSeasonFilter.value = 'all';
    weatherSearchQuery.value = '';
    nextTick(() => {
      jumpToSelectedWeatherPage();
    });
  } catch (err: any) {
    showToast(err?.message || 'Không thể tạo kiểu thời tiết');
  } finally {
    newWeatherSaving.value = false;
  }
}

// ====================================================
// MODAL: SỬA KIỂU THỜI TIẾT
// ====================================================
const showEditWeatherModal = ref(false);
const editingWeather = ref<Weather | null>(null);
const editWeatherName = ref('');
const editWeatherSeason = ref('summer');
const editWeatherMinTemp = ref<number | null>(null);
const editWeatherMaxTemp = ref<number | null>(null);
const editWeatherMinHumidity = ref<number | null>(null);
const editWeatherMaxHumidity = ref<number | null>(null);
const editWeatherDesc = ref('');
const editWeatherIsActive = ref(true);
const editWeatherSaving = ref(false);

function openEditWeatherModal(w: Weather) {
  editingWeather.value = w;
  editWeatherName.value = w.name;
  editWeatherSeason.value = w.season || 'summer';
  editWeatherMinTemp.value = w.temperature ?? w.min_temp ?? null;
  editWeatherMaxTemp.value = w.max_temp ?? null;
  editWeatherMinHumidity.value = w.humidity ?? w.min_humidity ?? null;
  editWeatherMaxHumidity.value = w.max_humidity ?? null;
  editWeatherDesc.value = w.description || '';
  editWeatherIsActive.value = w.is_active ?? true;
  showEditWeatherModal.value = true;
}

async function handleEditWeatherSubmit() {
  if (!editingWeather.value) return;
  if (!editWeatherName.value.trim()) {
    showToast('Tên kiểu thời tiết không được để trống');
    return;
  }

  if (
    editWeatherMinTemp.value != null &&
    editWeatherMaxTemp.value != null &&
    Number(editWeatherMinTemp.value) > Number(editWeatherMaxTemp.value)
  ) {
    showToast('Nhiệt độ tối thiểu không được lớn hơn nhiệt độ tối đa');
    return;
  }

  if (
    editWeatherMinHumidity.value != null &&
    editWeatherMaxHumidity.value != null &&
    Number(editWeatherMinHumidity.value) > Number(editWeatherMaxHumidity.value)
  ) {
    showToast('Độ ẩm tối thiểu không được lớn hơn độ ẩm tối đa');
    return;
  }

  if (
    (editWeatherMinHumidity.value != null && (Number(editWeatherMinHumidity.value) < 0 || Number(editWeatherMinHumidity.value) > 100)) ||
    (editWeatherMaxHumidity.value != null && (Number(editWeatherMaxHumidity.value) < 0 || Number(editWeatherMaxHumidity.value) > 100))
  ) {
    showToast('Độ ẩm phải nằm trong khoảng từ 0% đến 100%');
    return;
  }

  editWeatherSaving.value = true;
  try {
    const payload: Partial<Weather> = {
      name: editWeatherName.value.trim(),
      season: editWeatherSeason.value || null,
      temperature: editWeatherMinTemp.value != null ? Number(editWeatherMinTemp.value) : null,
      humidity: editWeatherMinHumidity.value != null ? Number(editWeatherMinHumidity.value) : null,
      description: editWeatherDesc.value.trim() || null,
      is_active: editWeatherIsActive.value,
    };

    const updated = await api.updateWeather(editingWeather.value.id, payload);
    emit('weatherUpdated', updated);
    showToast(`Đã cập nhật kiểu thời tiết "${updated.name}"!`);
    showEditWeatherModal.value = false;
  } catch (err: any) {
    showToast(err?.message || 'Không thể cập nhật kiểu thời tiết');
  } finally {
    editWeatherSaving.value = false;
  }
}

// ====================================================
// CONFIRM: XÓA KIỂU THỜI TIẾT
// ====================================================
const showDeleteWeatherConfirm = ref(false);
const deletingWeather = ref<Weather | null>(null);
const deleteWeatherLoading = ref(false);

function confirmDeleteWeather(w: Weather) {
  deletingWeather.value = w;
  showDeleteWeatherConfirm.value = true;
}

async function handleDeleteWeatherSubmit() {
  if (!deletingWeather.value) return;
  deleteWeatherLoading.value = true;
  const target = deletingWeather.value;
  try {
    await api.deleteWeather(target.id);
    emit('weatherDeleted', target.id);
    showToast(`Đã xóa kiểu thời tiết "${target.name}".`);
    showDeleteWeatherConfirm.value = false;
  } catch (err: any) {
    showToast(err?.message || 'Không thể xóa kiểu thời tiết');
  } finally {
    deleteWeatherLoading.value = false;
  }
}

// ====================================================
// MODAL: TẠO DANH MỤC MỚI (GLOBAL CATEGORY)
// ====================================================
const showCreateCatModal = ref(false);
const newCatName = ref('');
const newCatDesc = ref('');
const newCatSaving = ref(false);


// ====================================================
// MODAL: SỬA DANH MỤC (GLOBAL CATEGORY)
// ====================================================
const showEditCatModal = ref(false);
const editingCat = ref<Category | null>(null);
const editCatName = ref('');
const editCatDesc = ref('');
const editCatDisplayOrder = ref(0);
const editCatIsActive = ref(true);
const editCatSaving = ref(false);

function openEditCategoryModal(cat: Category) {
  editingCat.value = cat;
  editCatName.value = cat.name;
  editCatDesc.value = cat.description || '';
  editCatDisplayOrder.value = cat.display_order ?? 0;
  editCatIsActive.value = cat.is_active ?? true;
  showEditCatModal.value = true;
}

async function handleEditCatSubmit() {
  if (!editingCat.value) return;
  if (!editCatName.value.trim()) {
    showToast('Tên danh mục không được để trống');
    return;
  }

  editCatSaving.value = true;
  try {
    const payload = {
      name: editCatName.value.trim(),
      description: editCatDesc.value.trim() || undefined,
      display_order: Number(editCatDisplayOrder.value) || 0,
      is_active: editCatIsActive.value,
    };
    const updated = await api.updateCategory(editingCat.value.id, payload);
    emit('categoryUpdated', updated);
    showToast(`Đã cập nhật danh mục "${updated.name}" thành công!`);
    showEditCatModal.value = false;
  } catch (err: any) {
    showToast(err?.message || 'Không thể cập nhật danh mục');
  } finally {
    editCatSaving.value = false;
  }
}

// ====================================================
// CONFIRM: XÓA DANH MỤC (GLOBAL CATEGORY)
// ====================================================
const showDeleteCatConfirm = ref(false);
const deletingCat = ref<Category | null>(null);
const deleteCatLoading = ref(false);

function confirmDeleteCategory(cat: Category) {
  deletingCat.value = cat;
  showDeleteCatConfirm.value = true;
}

async function handleDeleteCatSubmit() {
  if (!deletingCat.value) return;
  deleteCatLoading.value = true;
  const target = deletingCat.value;
  try {
    await api.deleteCategory(target.id);
    emit('categoryDeleted', target.id);
    showToast(`Đã xóa danh mục "${target.name}".`);
    showDeleteCatConfirm.value = false;
  } catch (err: any) {
    showToast(err?.message || 'Không thể xóa danh mục');
  } finally {
    deleteCatLoading.value = false;
  }
}

function openCreateCatModal() {
  newCatName.value = '';
  newCatDesc.value = '';
  showCreateCatModal.value = true;
}

async function handleCreateCatSubmit() {
  if (!newCatName.value.trim()) {
    showToast('Tên danh mục không được để trống');
    return;
  }

  newCatSaving.value = true;
  try {
    const created = await api.createGlobalCategory({
      name: newCatName.value.trim(),
      description: newCatDesc.value.trim() || undefined,
      is_active: true,
      display_order: props.globalCategories.length,
    });
    emit('categoryCreated', created);
    showToast(`Đã tạo danh mục "${created.name}" thành công!`);
    showCreateCatModal.value = false;
  } catch (err: any) {
    showToast(err?.message || 'Không thể tạo danh mục mới');
  } finally {
    newCatSaving.value = false;
  }
}
</script>

<template>
  <div class="weather-rules-tab">
    <PageHeader
      title="Luật thời tiết &amp; Gợi ý món"
      subtitle="Thiết lập liên kết phân nhóm ẩm thực ưu tiên hiển thị theo từng điều kiện thời tiết"
    >
      <template #actions>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="loading"
          aria-label="Làm mới dữ liệu thời tiết"
          @click="emit('refresh')"
        >
          <RefreshCw class="btn-icon" :class="{ 'spin-icon': loading }" />
          <span>Làm mới</span>
        </button>
        <button
          type="button"
          class="btn btn-secondary"
          aria-label="Thêm kiểu thời tiết mới"
          @click="openCreateWeatherModal"
        >
          <Plus class="btn-icon" />
          <span>Kiểu thời tiết</span>
        </button>
        <button
          type="button"
          class="btn btn-primary"
          aria-label="Thêm danh mục món mới"
          @click="openCreateCatModal"
        >
          <Plus class="btn-icon" />
          <span>Danh mục mới</span>
        </button>
      </template>
    </PageHeader>

    <!-- Master-Detail 2 Column Split Layout -->
    <div class="split">
      <!-- Cột Trái: Danh sách các kiểu thời tiết -->
      <div class="card master-pane">
        <label class="srch master-srch" aria-label="Tìm kiểu thời tiết">
          <Search class="srch-icon" />
          <input
            v-model="weatherSearchQuery"
            type="text"
            placeholder="Tìm theo tên, mã, mô tả..."
          />
        </label>

        <!-- Lọc theo mùa -->
        <div class="master-season-filter">
          <select
            v-model="weatherSeasonFilter"
            class="master-season-select"
            aria-label="Lọc theo mùa"
          >
            <option value="all">Tất cả mùa ({{ props.weathers.length }})</option>
            <option value="spring">Mùa xuân ({{ availableSeasons['spring'] || 0 }})</option>
            <option value="summer">Mùa hè ({{ availableSeasons['summer'] || 0 }})</option>
            <option value="autumn">Mùa thu ({{ availableSeasons['autumn'] || 0 }})</option>
            <option value="winter">Mùa đông ({{ availableSeasons['winter'] || 0 }})</option>
            <option v-if="availableSeasons['rainy']" value="rainy">Mùa mưa ({{ availableSeasons['rainy'] }})</option>
            <option v-if="availableSeasons['dry']" value="dry">Mùa khô ({{ availableSeasons['dry'] }})</option>
          </select>
        </div>

        <!-- Chỉ dẫn chuyển trang nếu mục đang chọn ở trang khác -->
        <div
          v-if="selectedWeather && !isSelectedWeatherOnCurrentPage"
          class="master-selected-hint"
          title="Bấm để chuyển đến trang chứa kiểu thời tiết đang chọn"
          @click="jumpToSelectedWeatherPage"
        >
          <div class="hint-text">
            <span>Đang chọn:</span>
            <b>{{ selectedWeather.name }}</b>
          </div>
          <span class="hint-jump">Đến trang ›</span>
        </div>

        <div ref="masterListScrollEl" class="master-list-scroll">
          <button
            v-for="w in pagedWeathers"
            :key="w.id"
            type="button"
            class="li"
            :class="{ on: w.id === selectedWeather?.id }"
            @click="emit('selectWeather', w)"
          >
            <div class="weather-icon-sq">
              <CloudSun class="w-sq-icon" />
            </div>
            <div class="master-li-info">
              <div class="w-title-row">
                <b>{{ w.name }}</b>
                <span v-if="w.hour_display || w.hour != null" class="hour-badge">
                  {{ w.hour_display || formatHour12h(w.hour) }}
                </span>
                <span v-if="!w.is_active" class="inactive-badge">Tạm ẩn</span>
              </div>
              <small>
                {{ getSeasonLabel(w.season) }}
                <span v-if="w.temperature != null">
                  · {{ w.temperature }}°C
                </span>
                <span v-else-if="w.min_temp != null && w.max_temp != null">
                  · {{ w.min_temp }}–{{ w.max_temp }}°C
                </span>
                <span v-if="w.humidity != null">
                  · {{ w.humidity }}%
                </span>
                <span v-else-if="w.min_humidity != null && w.max_humidity != null">
                  · {{ w.min_humidity }}–{{ w.max_humidity }}%
                </span>
                <span v-else-if="w.min_humidity != null">
                  · ≥{{ w.min_humidity }}%
                </span>
                <span v-else-if="w.max_humidity != null">
                  · ≤{{ w.max_humidity }}%
                </span>
              </small>
            </div>
          </button>

          <div v-if="filteredWeathers.length === 0" class="master-empty">
            Không tìm thấy kiểu thời tiết phù hợp
          </div>
        </div>

        <!-- Phân trang danh sách thời tiết -->
        <div v-if="filteredWeathers.length > 0" class="master-pg">
          <div class="master-pg-top">
            <span class="master-pg-info">
              {{ weatherFromItem }}–{{ weatherToItem }} / {{ filteredWeathers.length }}
            </span>
            <select
              v-model.number="weatherPageSize"
              class="master-pg-size"
              aria-label="Số bản ghi mỗi trang"
            >
              <option :value="10">10 / trang</option>
              <option :value="20">20 / trang</option>
              <option :value="50">50 / trang</option>
            </select>
          </div>

          <div v-if="weatherTotalPages > 1" class="master-pg-controls">
            <button
              type="button"
              class="master-pg-btn"
              :disabled="weatherCurrentPage <= 1"
              aria-label="Trang trước"
              @click="setWeatherPage(weatherCurrentPage - 1)"
            >
              ‹
            </button>

            <select
              v-model.number="weatherCurrentPage"
              class="master-pg-select"
              aria-label="Chọn trang"
            >
              <option v-for="p in weatherTotalPages" :key="p" :value="p">
                Trang {{ p }} / {{ weatherTotalPages }}
              </option>
            </select>

            <button
              type="button"
              class="master-pg-btn"
              :disabled="weatherCurrentPage >= weatherTotalPages"
              aria-label="Trang sau"
              @click="setWeatherPage(weatherCurrentPage + 1)"
            >
              ›
            </button>
          </div>
        </div>
      </div>

      <!-- Cột Phải: Thông tin chi tiết & danh mục liên kết -->
      <div class="card detail-pane">
        <!-- Error State -->
        <div v-if="error" class="error-detail-state">
          <p>{{ error }}</p>
          <button type="button" class="btn btn-secondary btn-sm" @click="emit('retry')">
            <RefreshCw class="btn-icon" /> Thử lại
          </button>
        </div>

        <!-- Empty Guide if no weather is selected -->
        <div v-else-if="!selectedWeather" class="empty-detail-guide">
          <CloudSun class="guide-icon" />
          <h4>Chưa chọn kiểu thời tiết</h4>
          <p>Vui lòng chọn một kiểu thời tiết ở cột bên trái để quản lý các danh mục gợi ý.</p>
        </div>

        <!-- Weather detail content -->
        <div v-else class="detail-container">
          <!-- Header thời tiết đang chọn -->
          <div class="pad detail-header">
            <div class="header-top-row">
              <div class="detail-titles">
                <h3>{{ selectedWeather.name }}</h3>
                <p class="weather-desc">
                  {{ selectedWeather.description || 'Chưa có ghi chú mô tả cho kiểu thời tiết này.' }}
                </p>
              </div>

              <!-- Action buttons -->
              <div class="weather-header-actions">
                <button
                  type="button"
                  class="btn btn-secondary btn-sm"
                  aria-label="Chỉnh sửa kiểu thời tiết"
                  @click="openEditWeatherModal(selectedWeather)"
                >
                  <Edit class="btn-icon" />
                  <span>Sửa</span>
                </button>
                <button
                  type="button"
                  class="btn btn-secondary btn-sm danger-btn"
                  aria-label="Xóa kiểu thời tiết"
                  @click="confirmDeleteWeather(selectedWeather)"
                >
                  <Trash2 class="btn-icon" />
                  <span>Xóa</span>
                </button>
              </div>
            </div>

            <!-- Meta details row -->
            <div class="meta-row">
              <span class="meta-item">
                Mã: <b>{{ selectedWeather.code }}</b>
              </span>
              <span v-if="selectedWeather.hour_display || selectedWeather.hour != null" class="meta-item">
                <Clock class="inline-icon" />
                Khung giờ: <b>{{ selectedWeather.hour_display || formatHour12h(selectedWeather.hour) }}</b>
              </span>
              <span class="meta-item">
                Mùa: <b>{{ getSeasonLabel(selectedWeather.season) }}</b>
              </span>
              <span v-if="selectedWeather.temperature != null" class="meta-item">
                <Thermometer class="inline-icon" />
                Nhiệt độ: <b>{{ selectedWeather.temperature }}°C</b>
              </span>
              <span v-else-if="selectedWeather.min_temp != null && selectedWeather.max_temp != null" class="meta-item">
                <Thermometer class="inline-icon" />
                Nhiệt độ: <b>{{ selectedWeather.min_temp }}°C – {{ selectedWeather.max_temp }}°C</b>
              </span>
              <span v-if="selectedWeather.humidity != null" class="meta-item">
                Độ ẩm: <b>{{ selectedWeather.humidity }}%</b>
              </span>
              <span v-else-if="selectedWeather.min_humidity != null && selectedWeather.max_humidity != null" class="meta-item">
                Độ ẩm: <b>{{ selectedWeather.min_humidity }}% – {{ selectedWeather.max_humidity }}%</b>
              </span>
              <span v-else-if="selectedWeather.min_humidity != null" class="meta-item">
                Độ ẩm: <b>≥{{ selectedWeather.min_humidity }}%</b>
              </span>
              <span v-else-if="selectedWeather.max_humidity != null" class="meta-item">
                Độ ẩm: <b>≤{{ selectedWeather.max_humidity }}%</b>
              </span>
              <span class="meta-item">
                <Layers class="inline-icon" />
                Đang gợi ý: <b>{{ linkedCount }}/{{ globalCategories.length }}</b> danh mục
              </span>
            </div>
          </div>

          <!-- Category filter & search toolbar -->
          <div class="category-toolbar">
            <label class="srch cat-srch" aria-label="Tìm danh mục món">
              <Search class="srch-icon" />
              <input
                v-model="categorySearchQuery"
                type="text"
                placeholder="Lọc danh mục món ăn..."
              />
            </label>

            <!-- Segmented filter: Tất cả / Đang gợi ý / Chưa gợi ý -->
            <div class="seg" role="group" aria-label="Lọc trạng thái gợi ý danh mục">
              <button
                type="button"
                :class="{ on: categoryFilterMode === 'all' }"
                @click="categoryFilterMode = 'all'"
              >
                Tất cả ({{ globalCategories.length }})
              </button>
              <button
                type="button"
                :class="{ on: categoryFilterMode === 'linked' }"
                @click="categoryFilterMode = 'linked'"
              >
                Đang gợi ý ({{ linkedCount }})
              </button>
              <button
                type="button"
                :class="{ on: categoryFilterMode === 'unlinked' }"
                @click="categoryFilterMode = 'unlinked'"
              >
                Chưa gợi ý ({{ globalCategories.length - linkedCount }})
              </button>
            </div>
          </div>

          <!-- Category rules list -->
          <div class="rules-list">
            <div
              v-for="cat in filteredCategories"
              :key="cat.id"
              class="rule-row"
              :class="{ 'is-active-rule': weatherCategoryIds.has(cat.id) }"
            >
              <div class="rule-content">
                <div class="rule-title-row">
                  <b class="rule-name">{{ cat.name }}</b>
                  <Chip v-if="weatherCategoryIds.has(cat.id)" variant="ok">
                    Ưu tiên gợi ý
                  </Chip>
                </div>
                <small class="rule-desc">
                  {{ cat.description || 'Chưa cập nhật mô tả danh mục món' }}
                </small>
              </div>

              <!-- Action controls: SwitchToggle & RowActionMenu -->
              <div class="rule-actions">
                <SwitchToggle
                  :model-value="weatherCategoryIds.has(cat.id)"
                  :loading="!!weatherLinkingMap[cat.id]"
                  :aria-label="`Gợi ý danh mục ${cat.name}`"
                  @change="emit('toggleCategory', cat)"
                />
                <RowActionMenu :aria-label="`Tùy chọn danh mục ${cat.name}`">
                  <button type="button" @click="openEditCategoryModal(cat)">
                    <Edit class="menu-item-icon" />
                    <span>Sửa danh mục</span>
                  </button>
                  <hr />
                  <button type="button" class="danger-action" @click="confirmDeleteCategory(cat)">
                    <Trash2 class="menu-item-icon" />
                    <span>Xóa danh mục</span>
                  </button>
                </RowActionMenu>
              </div>
            </div>

            <div v-if="filteredCategories.length === 0" class="empty-rules">
              <p>Không có danh mục nào khớp với bộ lọc.</p>
              <button
                type="button"
                class="btn btn-secondary btn-sm"
                @click="categorySearchQuery = ''; categoryFilterMode = 'all'"
              >
                Đặt lại bộ lọc
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- BaseModal: Thêm kiểu thời tiết -->
    <BaseModal
      v-model="showCreateWeatherModal"
      title="Thêm kiểu thời tiết mới"
      subtitle="Thiết lập điều kiện khí hậu và ngưỡng nhiệt độ phục vụ gợi ý món"
      max-width="500px"
      :prevent-close="newWeatherSaving"
    >
      <form id="createWeatherForm" @submit.prevent="handleCreateWeatherSubmit">
        <div class="form-group">
          <label class="form-label">Tên kiểu thời tiết *</label>
          <input
            v-model="newWeatherName"
            type="text"
            class="form-input"
            placeholder="Ví dụ: Nắng nóng gay gắt"
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Mã định danh (code) *</label>
            <input
              v-model="newWeatherCode"
              type="text"
              class="form-input"
              placeholder="Ví dụ: hot, rainy, stormy..."
              required
            />
          </div>

          <div class="form-group">
            <label class="form-label">Mùa áp dụng</label>
            <select v-model="newWeatherSeason" class="form-input">
              <option value="summer">Mùa hè</option>
              <option value="winter">Mùa đông</option>
              <option value="autumn">Mùa thu</option>
              <option value="spring">Mùa xuân</option>
              <option value="rainy">Mùa mưa</option>
              <option value="dry">Mùa khô</option>
              <option value="all">Quanh năm</option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Nhiệt độ tối thiểu (°C)</label>
            <input
              v-model.number="newWeatherMinTemp"
              type="number"
              step="1"
              class="form-input"
              placeholder="VD: 25"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Nhiệt độ tối đa (°C)</label>
            <input
              v-model.number="newWeatherMaxTemp"
              type="number"
              step="1"
              class="form-input"
              placeholder="VD: 38"
            />
          </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Độ ẩm tối thiểu (%)</label>
            <input
              v-model.number="newWeatherMinHumidity"
              type="number"
              min="0"
              max="100"
              step="1"
              class="form-input"
              placeholder="VD: 60"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Độ ẩm tối đa (%)</label>
            <input
              v-model.number="newWeatherMaxHumidity"
              type="number"
              min="0"
              max="100"
              step="1"
              class="form-input"
              placeholder="VD: 85"
            />
          </div>
        </div>
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả điều kiện &amp; Gợi ý khẩu vị</label>
          <textarea
            v-model="newWeatherDesc"
            class="form-input"
            rows="2"
            placeholder="Nhiệt độ cao, oi bức, thích hợp món mát, giải nhiệt..."
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="newWeatherSaving"
          @click="showCreateWeatherModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="createWeatherForm"
          class="btn btn-primary"
          :disabled="newWeatherSaving"
        >
          {{ newWeatherSaving ? 'Đang tạo...' : 'Tạo kiểu thời tiết' }}
        </button>
      </template>
    </BaseModal>

    <!-- BaseModal: Sửa kiểu thời tiết -->
    <BaseModal
      v-model="showEditWeatherModal"
      :title="`Sửa thời tiết: ${editingWeather?.name || ''}`"
      subtitle="Cập nhật thông số nhiệt độ và mô tả điều kiện thời tiết"
      max-width="500px"
      :prevent-close="editWeatherSaving"
    >
      <form id="editWeatherForm" @submit.prevent="handleEditWeatherSubmit">
        <div class="form-group">
          <label class="form-label">Tên kiểu thời tiết *</label>
          <input
            v-model="editWeatherName"
            type="text"
            class="form-input"
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Mùa áp dụng</label>
            <select v-model="editWeatherSeason" class="form-input">
              <option value="summer">Mùa hè</option>
              <option value="winter">Mùa đông</option>
              <option value="autumn">Mùa thu</option>
              <option value="spring">Mùa xuân</option>
              <option value="rainy">Mùa mưa</option>
              <option value="dry">Mùa khô</option>
              <option value="all">Quanh năm</option>
            </select>
          </div>

          <div class="form-group">
            <label class="form-label">Trạng thái hoạt động</label>
            <select v-model="editWeatherIsActive" class="form-input">
              <option :value="true">Hoạt động</option>
              <option :value="false">Tạm ẩn</option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Nhiệt độ tối thiểu (°C)</label>
            <input
              v-model.number="editWeatherMinTemp"
              type="number"
              step="1"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Nhiệt độ tối đa (°C)</label>
            <input
              v-model.number="editWeatherMaxTemp"
              type="number"
              step="1"
              class="form-input"
            />
          </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Độ ẩm tối thiểu (%)</label>
            <input
              v-model.number="editWeatherMinHumidity"
              type="number"
              min="0"
              max="100"
              step="1"
              class="form-input"
              placeholder="VD: 60"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Độ ẩm tối đa (%)</label>
            <input
              v-model.number="editWeatherMaxHumidity"
              type="number"
              min="0"
              max="100"
              step="1"
              class="form-input"
              placeholder="VD: 85"
            />
          </div>
        </div>
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả điều kiện &amp; Gợi ý khẩu vị</label>
          <textarea
            v-model="editWeatherDesc"
            class="form-input"
            rows="2"
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="editWeatherSaving"
          @click="showEditWeatherModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="editWeatherForm"
          class="btn btn-primary"
          :disabled="editWeatherSaving"
        >
          {{ editWeatherSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
        </button>
      </template>
    </BaseModal>

    <!-- ConfirmDialog: Xóa kiểu thời tiết -->
    <ConfirmDialog
      v-model="showDeleteWeatherConfirm"
      title="Xác nhận xóa kiểu thời tiết"
      :message="`Bạn có chắc chắn muốn xóa kiểu thời tiết '${deletingWeather?.name}'? Toàn bộ các liên kết danh mục với kiểu thời tiết này cũng sẽ bị xóa khỏi hệ thống.`"
      confirm-text="Xóa thời tiết"
      cancel-text="Hủy"
      :danger="true"
      :loading="deleteWeatherLoading"
      @confirm="handleDeleteWeatherSubmit"
    />

    <!-- BaseModal: Thêm danh mục hệ thống mới -->
    <BaseModal
      v-model="showCreateCatModal"
      title="Thêm danh mục món mới"
      subtitle="Tạo danh mục món ăn chung cho toàn hệ thống PTC1"
      max-width="440px"
      :prevent-close="newCatSaving"
    >
      <form id="createCatForm" @submit.prevent="handleCreateCatSubmit">
        <div class="form-group">
          <label class="form-label">Tên danh mục món *</label>
          <input
            v-model="newCatName"
            type="text"
            class="form-input"
            placeholder="Ví dụ: Đồ uống giải nhiệt, Lẩu & Nướng..."
            required
          />
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả danh mục</label>
          <textarea
            v-model="newCatDesc"
            class="form-input"
            rows="2"
            placeholder="Ghi chú về phân loại món..."
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="newCatSaving"
          @click="showCreateCatModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="createCatForm"
          class="btn btn-primary"
          :disabled="newCatSaving"
        >
          {{ newCatSaving ? 'Đang tạo...' : 'Tạo danh mục' }}
        </button>
      </template>
    </BaseModal>

    <!-- BaseModal: Sửa danh mục món -->
    <BaseModal
      v-model="showEditCatModal"
      :title="`Sửa danh mục: ${editingCat?.name || ''}`"
      subtitle="Chỉnh sửa thông tin phân loại món dùng chung toàn hệ thống"
      max-width="460px"
      :close-on-backdrop="false"
      :prevent-close="editCatSaving"
    >
      <form id="editCatForm" @submit.prevent="handleEditCatSubmit">
        <div class="form-group">
          <label class="form-label">Tên danh mục món ăn *</label>
          <input
            v-model="editCatName"
            type="text"
            class="form-input"
            placeholder="Ví dụ: Lẩu & Nướng, Đồ uống thanh nhiệt..."
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Thứ tự hiển thị</label>
            <input
              v-model.number="editCatDisplayOrder"
              type="number"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Trạng thái hoạt động</label>
            <select v-model="editCatIsActive" class="form-input">
              <option :value="true">Hoạt động</option>
              <option :value="false">Tạm ẩn</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả danh mục</label>
          <textarea
            v-model="editCatDesc"
            class="form-input"
            rows="3"
            placeholder="Mô tả nhóm món ăn hoặc đối tượng phục vụ..."
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="editCatSaving"
          @click="showEditCatModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="editCatForm"
          class="btn btn-primary"
          :disabled="editCatSaving"
        >
          {{ editCatSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
        </button>
      </template>
    </BaseModal>

    <!-- ConfirmDialog: Xóa danh mục hệ thống -->
    <ConfirmDialog
      v-model="showDeleteCatConfirm"
      title="Xác nhận xóa danh mục hệ thống"
      :message="`Xác nhận xóa danh mục '${deletingCat?.name}'? Danh mục này đang gắn với ${deletingCat?.dish_count ?? 0} món ăn (các món ăn sẽ KHÔNG bị xóa mà chuyển về Chưa phân loại) và sẽ bị gỡ bỏ khỏi toàn bộ các kiểu thời tiết liên kết.`"
      confirm-text="Xóa danh mục"
      cancel-text="Hủy"
      :danger="true"
      :loading="deleteCatLoading"
      @confirm="handleDeleteCatSubmit"
    />
  </div>
</template>

<style scoped>
.weather-rules-tab {
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
  to {
    transform: rotate(360deg);
  }
}

.danger-btn {
  color: var(--bad);
}

.danger-btn:hover {
  background: var(--bad-s);
  border-color: var(--bad);
  color: var(--bad);
}

/* Master-detail 2 column split */
.split {
  display: grid;
  grid-template-columns: 285px 1fr;
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

.srch-icon {
  width: 15px;
  height: 15px;
  color: var(--mut);
  flex: none;
}

/* Season filter dropdown */
.master-season-filter {
  width: 100%;
}

.master-season-select {
  width: 100%;
  padding: 6px 10px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: var(--bg);
  color: var(--ink);
  font-size: 12.5px;
  outline: none;
  cursor: pointer;
  transition: var(--transition);
}

.master-season-select:focus {
  border-color: var(--pri);
}

/* Selected weather hint when on another page */
.master-selected-hint {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  padding: 6px 10px;
  border-radius: 8px;
  background: var(--pri-s);
  border: 1px dashed color-mix(in srgb, var(--pri) 40%, transparent);
  font-size: 11.5px;
  cursor: pointer;
  transition: var(--transition);
}

.master-selected-hint:hover {
  background: color-mix(in srgb, var(--pri-s) 80%, var(--pri) 20%);
}

.hint-text {
  min-width: 0;
  display: flex;
  gap: 4px;
  align-items: center;
  color: var(--ink);
}

.hint-text span {
  color: var(--mut);
  white-space: nowrap;
}

.hint-text b {
  color: var(--pri);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 120px;
}

.hint-jump {
  color: var(--pri);
  font-weight: 600;
  white-space: nowrap;
  font-size: 11px;
}

.master-list-scroll {
  display: flex;
  flex-direction: column;
  gap: 3px;
  max-height: 520px;
  min-height: 200px;
  overflow-y: auto;
  padding-right: 2px;
}

/* Master pagination */
.master-pg {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-top: 8px;
  border-top: 1px solid var(--line);
  margin-top: 4px;
}

.master-pg-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11.5px;
  color: var(--mut);
}

.master-pg-info {
  font-variant-numeric: tabular-nums;
  font-size: 11.5px;
}

.master-pg-size {
  border: 1px solid var(--line);
  background: var(--bg);
  color: var(--ink);
  border-radius: 6px;
  padding: 2px 6px;
  font-size: 11px;
  cursor: pointer;
  outline: none;
}

.master-pg-size:focus {
  border-color: var(--pri);
}

.master-pg-controls {
  display: flex;
  gap: 4px;
  align-items: center;
  justify-content: space-between;
}

.master-pg-btn {
  border: 1px solid var(--line);
  background: var(--card);
  border-radius: 6px;
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: bold;
  color: var(--ink);
  cursor: pointer;
  transition: var(--transition);
  flex: none;
}

.master-pg-btn:hover:not(:disabled) {
  border-color: var(--pri);
  color: var(--pri);
}

.master-pg-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.master-pg-select {
  flex: 1;
  min-width: 0;
  height: 28px;
  border: 1px solid var(--line);
  background: var(--bg);
  color: var(--ink);
  border-radius: 6px;
  padding: 2px 6px;
  font-size: 11.5px;
  cursor: pointer;
  outline: none;
  text-align: center;
}

.master-pg-select:focus {
  border-color: var(--pri);
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

.weather-icon-sq {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: var(--bg);
  display: grid;
  place-items: center;
  flex: none;
  border: 1px solid var(--line);
}

.li.on .weather-icon-sq {
  background: #ffffff;
  border-color: color-mix(in srgb, var(--pri) 30%, transparent);
}

.w-sq-icon {
  width: 16px;
  height: 16px;
  color: var(--pri);
}

.master-li-info {
  min-width: 0;
  flex: 1;
}

.w-title-row {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-content: space-between;
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

.hour-badge {
  font-size: 11px;
  font-weight: 600;
  color: #0284c7;
  background: #f0f9ff;
  padding: 1.5px 7px;
  border-radius: 999px;
  border: 1px solid #bae6fd;
  white-space: nowrap;
  letter-spacing: 0.2px;
}

.inactive-badge {
  font-size: 10.5px;
  color: var(--mut);
  background: var(--bg);
  padding: 1px 6px;
  border-radius: 4px;
  border: 1px solid var(--line);
  white-space: nowrap;
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
  font-size: 16px;
  color: var(--ink);
}

.empty-detail-guide p {
  margin: 0;
  font-size: 13.5px;
  max-width: 420px;
}

/* Header inside detail */
.detail-header {
  border-bottom: 1px solid var(--line);
  padding-bottom: 14px;
}

.header-top-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  flex-wrap: wrap;
}

.detail-titles h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--ink);
}

.weather-desc {
  margin: 4px 0 0;
  font-size: 13px;
  color: var(--mut);
  line-height: 1.4;
}

.weather-header-actions {
  display: flex;
  gap: 6px;
}

.meta-row {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
  align-items: center;
  margin-top: 10px;
  font-size: 12.5px;
  color: var(--mut);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.meta-item b {
  color: var(--ink);
}

.inline-icon {
  width: 14px;
  height: 14px;
  color: var(--mut);
}

/* Category filter toolbar */
.category-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  padding: 12px 16px;
  border-bottom: 1px solid var(--line);
  background: color-mix(in srgb, var(--bg) 60%, transparent);
}

.cat-srch {
  max-width: 280px;
}

/* Rules list (prototype: .rule) */
.rules-list {
  display: flex;
  flex-direction: column;
}

.rule-row {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 12px 16px;
  border-top: 1px solid var(--line);
  transition: background 0.15s ease;
}

.rule-row:first-child {
  border-top: none;
}

.rule-row:hover {
  background: color-mix(in srgb, var(--bg) 50%, transparent);
}

.rule-row.is-active-rule {
  background: color-mix(in srgb, var(--pri-s) 40%, transparent);
}

.rule-content {
  flex: 1;
  min-width: 0;
}

.rule-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rule-name {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--ink);
}

.rule-desc {
  color: var(--mut);
  font-size: 12px;
  display: block;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-top: 2px;
}

.empty-rules {
  padding: 36px 16px;
  text-align: center;
  color: var(--mut);
  font-size: 13px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.error-detail-state {
  padding: 32px 16px;
  text-align: center;
  color: var(--bad);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
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
  .category-toolbar {
    flex-direction: column;
    align-items: stretch;
  }
  .cat-srch {
    max-width: 100%;
  }
}

.rule-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: none;
}

.menu-item-icon {
  width: 14px;
  height: 14px;
}

</style>
