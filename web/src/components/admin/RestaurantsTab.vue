<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import type { Restaurant } from '../../types';
import { api } from '../../services/api';
import { useToast } from '../../composables/useToast';
import PageHeader from '../common/PageHeader.vue';
import DataTable from '../common/DataTable.vue';
import StatusPill from '../common/StatusPill.vue';
import Chip from '../common/Chip.vue';
import RowActionMenu from '../common/RowActionMenu.vue';
import BaseModal from '../common/BaseModal.vue';
import ConfirmDialog from '../common/ConfirmDialog.vue';
import SwitchToggle from '../common/SwitchToggle.vue';
import {
  Plus,
  Search,
  UtensilsCrossed,
  Edit,
  Power,
  Trash2,
  Clock,
  Phone,
} from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    restaurants: Restaurant[];
    loading: boolean;
    error?: string | null;
  }>(),
  {
    error: null,
  }
);

const emit = defineEmits<{
  (e: 'selectRestaurantMenu', restaurantId: number): void;
  (e: 'restaurantCreated', restaurant: Restaurant): void;
  (e: 'restaurantUpdated', restaurant: Restaurant): void;
  (e: 'restaurantDeleted', restaurantId: number): void;
  (e: 'refresh'): void;
}>();

const { showToast } = useToast();

// Toolbar state
const searchQuery = ref('');
const statusFilter = ref<'all' | 'on' | 'off'>('all');
const currentPage = ref(1);
const pageSize = 10;

// Reset page to 1 when search or filter changes
watch([searchQuery, statusFilter], () => {
  currentPage.value = 1;
});

// Vietnamese normalization function: toLowerCase() FIRST, then normalize('NFD'), then remove accents and đ
function normalizeText(str: string): string {
  if (!str) return '';
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .trim();
}

// Filtered restaurants
const filteredRestaurants = computed(() => {
  const q = normalizeText(searchQuery.value);
  return props.restaurants.filter((r) => {
    // Status filter
    if (statusFilter.value === 'on' && !r.is_active) return false;
    if (statusFilter.value === 'off' && r.is_active) return false;

    // Search query: test by name, phone, address
    if (!q) return true;
    const textTarget = normalizeText(
      `${r.name} ${r.phone || ''} ${r.address || ''}`
    );
    return textTarget.includes(q);
  });
});

// If current page is beyond total pages after items removed/filtered, shift back to last page
watch(filteredRestaurants, (list) => {
  const maxPage = Math.max(1, Math.ceil(list.length / pageSize));
  if (currentPage.value > maxPage) {
    currentPage.value = maxPage;
  }
});

// Paginated slice
const paginatedRestaurants = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredRestaurants.value.slice(start, start + pageSize);
});

function resetFilters() {
  searchQuery.value = '';
  statusFilter.value = 'all';
  currentPage.value = 1;
}

// --- TOGGLE STATUS (Guaranteed rollback if API fails) ---
async function handleToggleStatus(r: Restaurant) {
  const previousStatus = r.is_active;
  const nextStatus = !previousStatus;
  try {
    const updated = await api.updateRestaurantAsAdmin(r.id, {
      is_active: nextStatus,
    });
    emit('restaurantUpdated', updated);
    showToast(
      nextStatus
        ? `Đã kích hoạt hoạt động quán "${r.name}"`
        : `Đã tạm dừng hoạt động quán "${r.name}"`
    );
  } catch (err: any) {
    // If API error, keep UI at previousStatus
    emit('restaurantUpdated', { ...r, is_active: previousStatus });
    showToast(err.message || 'Không thể đổi trạng thái quán. Đã khôi phục lại.');
  }
}

// --- CREATE MODAL STATE & LOGIC ---
const showCreateModal = ref(false);
const newName = ref('');
const newAddress = ref('');
const newPhone = ref('');
const newDesc = ref('');
const newOpenTime = ref('08:00');
const newCloseTime = ref('22:00');
const newLat = ref(21.0055);
const newLon = ref(105.9325);
const newIsSponsor = ref(false);
const newRating = ref<number | undefined>(undefined);
const newAdminRating = ref<number | undefined>(undefined);
const newLicenses = ref('');
const createSaving = ref(false);
const isGeocodingCreate = ref(false);

function openCreateModal() {
  newName.value = '';
  newAddress.value = '';
  newPhone.value = '';
  newDesc.value = '';
  newOpenTime.value = '08:00';
  newCloseTime.value = '22:00';
  newLat.value = 21.0055;
  newLon.value = 105.9325;
  newIsSponsor.value = false;
  newRating.value = undefined;
  newAdminRating.value = undefined;
  newLicenses.value = '';
  showCreateModal.value = true;
}

function applyHvnnPreset() {
  newAddress.value = 'Thị trấn Trâu Quỳ, Huyện Gia Lâm, Hà Nội';
  newLat.value = 21.0055;
  newLon.value = 105.9325;
}

async function handleGeocodeCreate() {
  if (!newAddress.value.trim()) {
    showToast('Vui lòng nhập địa chỉ trước khi tìm tọa độ');
    return;
  }
  isGeocodingCreate.value = true;
  try {
    const places = await api.searchMap(newAddress.value.trim(), 1);
    if (places && places.length > 0) {
      newLat.value = Number(places[0].latitude.toFixed(6));
      newLon.value = Number(places[0].longitude.toFixed(6));
      showToast(`Đã tìm thấy tọa độ: (${newLat.value}, ${newLon.value})`);
    } else {
      showToast('Không tìm thấy tọa độ cho địa chỉ này, vui lòng nhập thủ công');
    }
  } catch (err: any) {
    showToast(err.message || 'Lỗi khi tra cứu tọa độ từ bản đồ');
  } finally {
    isGeocodingCreate.value = false;
  }
}

async function handleCreateSubmit() {
  if (!newName.value.trim() || !newAddress.value.trim()) {
    showToast('Vui lòng nhập tên quán và địa chỉ');
    return;
  }
  const cleanPhone = newPhone.value.trim();
  if (cleanPhone) {
    const rawDigits = cleanPhone.replace(/[-. ]/g, '');
    const phoneRegex = /^(0|\+84)[0-9]{9,10}$/;
    if (!phoneRegex.test(rawDigits)) {
      showToast('Số điện thoại không hợp lệ (phải từ 10-11 chữ số)');
      return;
    }
  }
  const latNum = Number(newLat.value);
  const lonNum = Number(newLon.value);
  if (isNaN(latNum) || latNum < -90 || latNum > 90 || isNaN(lonNum) || lonNum < -180 || lonNum > 180) {
    showToast('Toạ độ (vĩ độ / kinh độ) không hợp lệ');
    return;
  }
  if (newRating.value !== undefined && newRating.value !== null && String(newRating.value).trim() !== '') {
    const rNum = Number(newRating.value);
    if (isNaN(rNum) || rNum < 0 || rNum > 5) {
      showToast('Điểm đánh giá phải từ 0.0 đến 5.0 sao');
      return;
    }
  }
  if (newAdminRating.value !== undefined && newAdminRating.value !== null && String(newAdminRating.value).trim() !== '') {
    const arNum = Number(newAdminRating.value);
    if (isNaN(arNum) || arNum < 0 || arNum > 5) {
      showToast('Điểm Admin thẩm định phải từ 0.0 đến 5.0 sao');
      return;
    }
  }
  createSaving.value = true;
  try {
    const created = await api.createRestaurantAsAdmin({
      name: newName.value.trim(),
      address: newAddress.value.trim(),
      phone: newPhone.value.trim() || undefined,
      description: newDesc.value.trim() || undefined,
      open_time: newOpenTime.value || null,
      close_time: newCloseTime.value || null,
      latitude: Number(newLat.value),
      longitude: Number(newLon.value),
      is_sponsor: newIsSponsor.value,
      rating: newRating.value !== undefined && newRating.value !== null && !isNaN(Number(newRating.value)) ? Number(newRating.value) : undefined,
      admin_rating: newAdminRating.value !== undefined && newAdminRating.value !== null && !isNaN(Number(newAdminRating.value)) ? Number(newAdminRating.value) : undefined,
      service_licenses: newLicenses.value
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0),
    });
    emit('restaurantCreated', created);
    showToast(`Đã thêm quán mới "${created.name}" thành công!`);
    showCreateModal.value = false;
  } catch (err: any) {
    showToast(err.message || 'Không thể tạo cơ sở quán ăn');
  } finally {
    createSaving.value = false;
  }
}

// --- EDIT MODAL STATE & LOGIC ---
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
const editIsSponsor = ref(false);
const editRating = ref<number | undefined>(undefined);
const editAdminRating = ref<number | undefined>(undefined);
const editLicenses = ref('');
const editSaving = ref(false);
const isGeocodingEdit = ref(false);

function openEditModal(r: Restaurant) {
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
  editIsSponsor.value = !!r.is_sponsor;
  editRating.value = r.rating !== null && r.rating !== undefined ? r.rating : undefined;
  editAdminRating.value = r.admin_rating !== null && r.admin_rating !== undefined ? r.admin_rating : undefined;
  editLicenses.value = (r.service_licenses || []).map((l: any) => typeof l === 'string' ? l : (l.name || String(l))).join(', ');
  showEditModal.value = true;
}

async function handleGeocodeEdit() {
  if (!editAddress.value.trim()) {
    showToast('Vui lòng nhập địa chỉ trước khi tìm tọa độ');
    return;
  }
  isGeocodingEdit.value = true;
  try {
    const places = await api.searchMap(editAddress.value.trim(), 1);
    if (places && places.length > 0) {
      editLat.value = Number(places[0].latitude.toFixed(6));
      editLon.value = Number(places[0].longitude.toFixed(6));
      showToast(`Đã tìm thấy tọa độ: (${editLat.value}, ${editLon.value})`);
    } else {
      showToast('Không tìm thấy tọa độ cho địa chỉ này, vui lòng nhập thủ công');
    }
  } catch (err: any) {
    showToast(err.message || 'Lỗi khi tra cứu tọa độ từ bản đồ');
  } finally {
    isGeocodingEdit.value = false;
  }
}

function goToMenuFromEdit() {
  if (!editingRestaurant.value) return;
  const id = editingRestaurant.value.id;
  showEditModal.value = false;
  emit('selectRestaurantMenu', id);
}

async function handleEditSubmit() {
  if (!editingRestaurant.value) return;
  if (!editName.value.trim() || !editAddress.value.trim()) {
    showToast('Vui lòng nhập tên quán và địa chỉ');
    return;
  }
  const cleanPhone = editPhone.value.trim();
  if (cleanPhone) {
    const rawDigits = cleanPhone.replace(/[-. ]/g, '');
    const phoneRegex = /^(0|\+84)[0-9]{9,10}$/;
    if (!phoneRegex.test(rawDigits)) {
      showToast('Số điện thoại không hợp lệ (phải từ 10-11 chữ số)');
      return;
    }
  }
  const latNum = Number(editLat.value);
  const lonNum = Number(editLon.value);
  if (isNaN(latNum) || latNum < -90 || latNum > 90 || isNaN(lonNum) || lonNum < -180 || lonNum > 180) {
    showToast('Toạ độ (vĩ độ / kinh độ) không hợp lệ');
    return;
  }
  if (editRating.value !== undefined && editRating.value !== null && String(editRating.value).trim() !== '') {
    const rNum = Number(editRating.value);
    if (isNaN(rNum) || rNum < 0 || rNum > 5) {
      showToast('Điểm đánh giá phải từ 0.0 đến 5.0 sao');
      return;
    }
  }
  if (editAdminRating.value !== undefined && editAdminRating.value !== null && String(editAdminRating.value).trim() !== '') {
    const arNum = Number(editAdminRating.value);
    if (isNaN(arNum) || arNum < 0 || arNum > 5) {
      showToast('Điểm Admin thẩm định phải từ 0.0 đến 5.0 sao');
      return;
    }
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
      is_sponsor: editIsSponsor.value,
      rating: editRating.value !== undefined && editRating.value !== null && !isNaN(Number(editRating.value)) ? Number(editRating.value) : undefined,
      admin_rating: editAdminRating.value !== undefined && editAdminRating.value !== null && !isNaN(Number(editAdminRating.value)) ? Number(editAdminRating.value) : undefined,
      service_licenses: editLicenses.value
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0),
    });
    emit('restaurantUpdated', updated);
    showToast(`Đã lưu thay đổi cho "${updated.name}"!`);
    showEditModal.value = false;
  } catch (err: any) {
    showToast(err.message || 'Không thể cập nhật thông tin quán');
  } finally {
    editSaving.value = false;
  }
}

// --- DELETE DIALOG STATE & LOGIC ---
const showDeleteConfirm = ref(false);
const deletingRestaurant = ref<Restaurant | null>(null);
const deleteLoading = ref(false);

function confirmDelete(r: Restaurant) {
  deletingRestaurant.value = r;
  showDeleteConfirm.value = true;
}

async function handleDeleteSubmit() {
  if (!deletingRestaurant.value) return;
  deleteLoading.value = true;
  const target = deletingRestaurant.value;
  try {
    await api.deleteRestaurant(target.id);
    emit('restaurantDeleted', target.id);
    showToast(`Đã xóa quán "${target.name}" khỏi hệ thống.`);
    showDeleteConfirm.value = false;
  } catch (err: any) {
    showToast(err.message || 'Không thể xóa cơ sở quán ăn');
  } finally {
    deleteLoading.value = false;
  }
}
</script>

<template>
  <div class="restaurants-tab">
    <PageHeader
      title="Cơ sở quán ăn"
      subtitle="Danh sách, liên hệ và trạng thái hoạt động của các điểm phục vụ ẩm thực"
    >
      <template #actions>
        <button
          type="button"
          class="btn btn-primary"
          aria-label="Thêm quán ăn mới"
          @click="openCreateModal"
        >
          <Plus class="btn-icon" />
          <span>Thêm quán</span>
        </button>
      </template>
    </PageHeader>

    <DataTable
      v-model:current-page="currentPage"
      :total-items="filteredRestaurants.length"
      :page-size="pageSize"
      item-name="quán"
      :loading="loading"
      :error="error"
      :empty="filteredRestaurants.length === 0"
      empty-message="Không có quán nào khớp bộ lọc. Thử bỏ bớt từ khóa tìm kiếm hoặc đổi trạng thái lọc."
      empty-action="Đặt lại bộ lọc"
      @empty-action-click="resetFilters"
      @retry="emit('refresh')"
    >
      <!-- Toolbar slot -->
      <template #toolbar>
        <label class="srch" aria-label="Tìm kiếm quán">
          <Search class="srch-icon" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Tìm theo tên, SĐT, địa chỉ (không dấu: dang xa, de dong)..."
          />
        </label>

        <div class="seg" role="group" aria-label="Lọc theo trạng thái">
          <button
            type="button"
            :class="{ on: statusFilter === 'all' }"
            @click="statusFilter = 'all'"
          >
            Tất cả
          </button>
          <button
            type="button"
            :class="{ on: statusFilter === 'on' }"
            @click="statusFilter = 'on'"
          >
            Đang mở
          </button>
          <button
            type="button"
            :class="{ on: statusFilter === 'off' }"
            @click="statusFilter = 'off'"
          >
            Tạm tắt
          </button>
        </div>
      </template>

      <!-- Table headers -->
      <thead>
        <tr>
          <th>Cơ sở</th>
          <th>Địa chỉ &amp; giờ phục vụ</th>
          <th>Trạng thái</th>
          <th style="text-align: right;">Thao tác</th>
        </tr>
      </thead>

      <!-- Table body -->
      <tbody>
        <tr v-for="r in paginatedRestaurants" :key="r.id">
          <!-- Cột 1: Cơ sở (Avatar chữ cái, Tên, Hotline, Chip chứng nhận) -->
          <td>
            <div class="ent">
              <div class="sq">{{ r.name.charAt(0).toUpperCase() }}</div>
              <div class="rest-details">
                <div class="rest-name-row">
                  <b class="rest-name">{{ r.name }}</b>
                  <Chip v-if="r.rating !== undefined && r.rating !== null" variant="default">⭐ {{ Number(r.rating).toFixed(1) }}</Chip>
                  <Chip v-if="r.admin_rating !== undefined && r.admin_rating !== null" variant="ok">👑 Admin: {{ Number(r.admin_rating).toFixed(1) }}</Chip>
                  <Chip v-if="r.is_sponsor" variant="warn">⭐ Tài trợ</Chip>
                </div>
                <small v-if="r.phone" class="rest-phone">
                  <Phone class="inline-icon" />
                  {{ r.phone }}
                </small>
                <!-- Render certificate chips ONLY if available in API, ensuring string text -->
                <div
                  v-if="r.service_licenses && r.service_licenses.length > 0"
                  class="licenses-row"
                >
                  <Chip
                    v-for="(lic, lIdx) in r.service_licenses"
                    :key="lIdx"
                    variant="ok"
                  >
                    {{ typeof lic === 'string' ? lic : ((lic as any)?.name || String(lic)) }}
                  </Chip>
                </div>
              </div>
            </div>
          </td>

          <!-- Cột 2: Địa chỉ & giờ phục vụ -->
          <td class="addr-cell">
            <div class="addr-text">{{ r.address || '—' }}</div>
            <small class="time-text">
              <Clock class="inline-icon" />
              <span v-if="r.open_time && r.close_time">
                {{ r.open_time }} – {{ r.close_time }}
              </span>
              <span v-else>Chưa cập nhật giờ</span>
            </small>
          </td>

          <!-- Cột 3: Trạng thái -->
          <td>
            <StatusPill :active="r.is_active" />
          </td>

          <!-- Cột 4: Thao tác (Nút Thực đơn hiển thị sẵn + Kebab menu) -->
          <td style="text-align: right;">
            <div class="actions-wrapper">
              <button
                type="button"
                class="btn btn-sm"
                aria-label="Xem thực đơn quán"
                @click="emit('selectRestaurantMenu', r.id)"
              >
                <UtensilsCrossed class="btn-icon" />
                <span>Thực đơn</span>
              </button>

              <RowActionMenu :aria-label="`Thao tác với quán ${r.name}`">
                <button type="button" @click="openEditModal(r)">
                  <Edit class="menu-item-icon" />
                  <span>Sửa thông tin</span>
                </button>
                <button type="button" @click="handleToggleStatus(r)">
                  <Power class="menu-item-icon" />
                  <span>{{ r.is_active ? 'Tắt hoạt động' : 'Bật hoạt động' }}</span>
                </button>
                <hr />
                <button
                  type="button"
                  class="danger-action"
                  @click="confirmDelete(r)"
                >
                  <Trash2 class="menu-item-icon" />
                  <span>Xóa quán</span>
                </button>
              </RowActionMenu>
            </div>
          </td>
        </tr>
      </tbody>
    </DataTable>

    <!-- BaseModal: Thêm quán ăn mới (internal scrollable body, fixed header and footer) -->
    <BaseModal
      v-model="showCreateModal"
      title="Thêm quán ăn mới"
      subtitle="Khởi tạo cơ sở kinh doanh ẩm thực trên hệ thống PTC1"
      max-width="540px"
      :prevent-close="createSaving"
    >
      <form id="createRestaurantForm" @submit.prevent="handleCreateSubmit">
        <div class="form-group">
          <label class="form-label">Tên quán ăn *</label>
          <input
            v-model="newName"
            type="text"
            class="form-input"
            placeholder="Ví dụ: Cơm tấm Sài Gòn 99"
            required
          />
        </div>

        <div class="form-group">
          <div class="label-with-hint">
            <label class="form-label">Địa chỉ cơ sở *</label>
            <div class="hint-actions">
              <button
                type="button"
                class="btn-hint"
                @click="applyHvnnPreset"
              >
                Gợi ý: HVNN
              </button>
              <button
                type="button"
                class="btn-hint"
                :disabled="isGeocodingCreate"
                @click="handleGeocodeCreate"
              >
                {{ isGeocodingCreate ? 'Đang tìm...' : '📍 Tìm tọa độ' }}
              </button>
            </div>
          </div>
          <input
            v-model="newAddress"
            type="text"
            class="form-input"
            placeholder="Số nhà, ngõ/đường, thị trấn..."
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Số điện thoại</label>
            <input
              v-model="newPhone"
              type="tel"
              class="form-input"
              placeholder="0987..."
            />
          </div>
          <div class="form-group">
            <label class="form-label">Điểm đánh giá (0.0 - 5.0)</label>
            <input
              v-model.number="newRating"
              type="number"
              step="0.1"
              min="0"
              max="5"
              class="form-input"
              placeholder="VD: 4.5 (tùy chọn)"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Điểm Admin thẩm định (0.0 - 5.0)</label>
            <input
              v-model.number="newAdminRating"
              type="number"
              step="0.1"
              min="0"
              max="5"
              class="form-input"
              placeholder="VD: 4.8 (tùy chọn)"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Nhà tài trợ</label>
            <div
              class="toggle-box"
              :class="{ active: newIsSponsor }"
              @click="newIsSponsor = !newIsSponsor"
            >
              <SwitchToggle
                :model-value="newIsSponsor"
                aria-label="Bật tắt nhà tài trợ"
                @click.stop
                @change="newIsSponsor = $event"
              />
              <span class="toggle-box-text">
                <span v-if="newIsSponsor" class="sponsor-on">⭐ Đang bật</span>
                <span v-else class="sponsor-off">Tắt</span>
              </span>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Khung giờ mở cửa</label>
          <div class="time-range-row">
            <input v-model="newOpenTime" type="time" class="form-input" />
            <span>–</span>
            <input v-model="newCloseTime" type="time" class="form-input" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Vĩ độ (Latitude) *</label>
            <input
              v-model.number="newLat"
              type="number"
              step="any"
              class="form-input"
              required
            />
          </div>
          <div class="form-group">
            <label class="form-label">Kinh độ (Longitude) *</label>
            <input
              v-model.number="newLon"
              type="number"
              step="any"
              class="form-input"
              required
            />
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả ngắn</label>
          <textarea
            v-model="newDesc"
            class="form-input"
            rows="2"
            placeholder="Đặc sản nổi bật, ghi chú vị trí..."
          ></textarea>
        </div>

        <div class="form-group">
          <label class="form-label">Giấy phép dịch vụ (phân tách bằng dấu phẩy)</label>
          <input
            v-model="newLicenses"
            type="text"
            class="form-input"
            placeholder="Ví dụ: ATTP, HACCP, ISO 22000..."
          />
        </div>
      </form>

      <template #footer>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="createSaving"
          @click="showCreateModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="createRestaurantForm"
          class="btn btn-primary"
          :disabled="createSaving"
        >
          {{ createSaving ? 'Đang tạo...' : 'Tạo cơ sở' }}
        </button>
      </template>
    </BaseModal>

    <!-- BaseModal: Sửa thông tin quán ăn (internal scrollable body, fixed header and footer) -->
    <BaseModal
      v-model="showEditModal"
      :title="`Sửa thông tin: ${editingRestaurant?.name || ''}`"
      :subtitle="`Mã định danh cơ sở #${editingRestaurant?.id}`"
      max-width="540px"
      :prevent-close="editSaving"
    >
      <form id="editRestaurantForm" @submit.prevent="handleEditSubmit">
        <div class="form-group">
          <label class="form-label">Tên quán ăn *</label>
          <input
            v-model="editName"
            type="text"
            class="form-input"
            required
          />
        </div>

        <div class="form-group">
          <div class="label-with-hint">
            <label class="form-label">Địa chỉ cơ sở *</label>
            <button
              type="button"
              class="btn-hint"
              :disabled="isGeocodingEdit"
              @click="handleGeocodeEdit"
            >
              {{ isGeocodingEdit ? 'Đang tìm...' : '📍 Tìm tọa độ từ địa chỉ' }}
            </button>
          </div>
          <input
            v-model="editAddress"
            type="text"
            class="form-input"
            required
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Số điện thoại</label>
            <input
              v-model="editPhone"
              type="tel"
              class="form-input"
              placeholder="0987..."
            />
          </div>
          <div class="form-group">
            <label class="form-label">Trạng thái hoạt động</label>
            <select v-model="editIsActive" class="form-input">
              <option :value="true">Đang hoạt động</option>
              <option :value="false">Tạm dừng phục vụ</option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Điểm đánh giá (0.0 - 5.0)</label>
            <input
              v-model.number="editRating"
              type="number"
              step="0.1"
              min="0"
              max="5"
              class="form-input"
              placeholder="VD: 4.5 (để trống nếu chưa có)"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Điểm Admin thẩm định (0.0 - 5.0)</label>
            <input
              v-model.number="editAdminRating"
              type="number"
              step="0.1"
              min="0"
              max="5"
              class="form-input"
              placeholder="VD: 4.8 (để trống nếu chưa có)"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Nhà tài trợ</label>
            <div
              class="toggle-box"
              :class="{ active: editIsSponsor }"
              @click="editIsSponsor = !editIsSponsor"
            >
              <SwitchToggle
                :model-value="editIsSponsor"
                aria-label="Bật tắt nhà tài trợ"
                @click.stop
                @change="editIsSponsor = $event"
              />
              <span class="toggle-box-text">
                <span v-if="editIsSponsor" class="sponsor-on">⭐ Đang bật</span>
                <span v-else class="sponsor-off">Tắt</span>
              </span>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Giấy phép dịch vụ</label>
            <input
              v-model="editLicenses"
              type="text"
              class="form-input"
              placeholder="Ví dụ: ATTP, HACCP, ISO 22000..."
            />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Giờ mở cửa</label>
            <input v-model="editOpenTime" type="time" class="form-input" />
          </div>
          <div class="form-group">
            <label class="form-label">Giờ đóng cửa</label>
            <input v-model="editCloseTime" type="time" class="form-input" />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Vĩ độ (Latitude) *</label>
            <input
              v-model.number="editLat"
              type="number"
              step="any"
              class="form-input"
              required
            />
          </div>
          <div class="form-group">
            <label class="form-label">Kinh độ (Longitude) *</label>
            <input
              v-model.number="editLon"
              type="number"
              step="any"
              class="form-input"
              required
            />
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả quán</label>
          <textarea
            v-model="editDesc"
            class="form-input"
            rows="2"
          ></textarea>
        </div>
      </form>

      <template #footer>
        <button
          v-if="editingRestaurant"
          type="button"
          class="btn btn-secondary"
          style="margin-right: auto;"
          title="Mở quản lý món ăn và danh mục của quán này"
          @click="goToMenuFromEdit"
        >
          <UtensilsCrossed class="btn-icon" />
          <span>Thực đơn</span>
        </button>
        <button
          type="button"
          class="btn btn-secondary"
          :disabled="editSaving"
          @click="showEditModal = false"
        >
          Hủy
        </button>
        <button
          type="submit"
          form="editRestaurantForm"
          class="btn btn-primary"
          :disabled="editSaving"
        >
          {{ editSaving ? 'Đang lưu...' : 'Lưu thay đổi' }}
        </button>
      </template>
    </BaseModal>

    <!-- ConfirmDialog: Xác nhận xóa quán ăn -->
    <ConfirmDialog
      v-model="showDeleteConfirm"
      title="Xác nhận xóa cơ sở quán ăn"
      :message="`Bạn có chắc muốn xoá vĩnh viễn quán '${deletingRestaurant?.name}'? Toàn bộ danh mục, thực đơn và món ăn thuộc cơ sở này sẽ bị xóa kèm khỏi hệ thống.`"
      confirm-text="Xóa vĩnh viễn"
      cancel-text="Hủy"
      :danger="true"
      :loading="deleteLoading"
      @confirm="handleDeleteSubmit"
    />
  </div>
</template>

<style scoped>
.restaurants-tab {
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

.rest-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.rest-name-row {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.rest-name {
  color: var(--ink);
  font-size: 13.5px;
}

.rest-phone {
  color: var(--mut);
  display: flex;
  align-items: center;
  gap: 4px;
}

.inline-icon {
  width: 12px;
  height: 12px;
  flex: none;
}

.licenses-row {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
  margin-top: 3px;
}

.addr-cell {
  max-width: 300px;
}

.addr-text {
  font-size: 13px;
  color: var(--ink);
  line-height: 1.4;
}

.time-text {
  color: var(--mut);
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 3px;
}

.actions-wrapper {
  display: flex;
  gap: 6px;
  justify-content: flex-end;
  align-items: center;
}

.label-with-hint {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.hint-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.label-with-hint .form-label {
  margin-bottom: 0;
}

.btn-hint {
  background: none;
  border: none;
  color: var(--pri);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  padding: 0;
}

.btn-hint:hover {
  text-decoration: underline;
}

.time-range-row {
  display: flex;
  gap: 6px;
  align-items: center;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.toggle-box {
  display: flex;
  align-items: center;
  gap: 10px;
  height: 38px;
  padding: 0 12px;
  border: 1px solid var(--line);
  border-radius: var(--radius-md, 8px);
  background-color: var(--card, #ffffff);
  cursor: pointer;
  user-select: none;
  transition: all 0.15s ease;
}

.toggle-box:hover {
  border-color: var(--pri);
}

.toggle-box.active {
  background: var(--warn-s, #fffbeb);
  border-color: var(--warn, #f59e0b);
}

.toggle-box-text {
  font-size: 13.5px;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
}

.sponsor-on {
  color: var(--warn, #d97706);
  font-weight: 600;
}

.sponsor-off {
  color: var(--mut, #64748b);
}

@media (max-width: 600px) {
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
