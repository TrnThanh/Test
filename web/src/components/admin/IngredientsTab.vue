<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import type { Ingredient, IngredientDetail, IngredientGroup } from '../../types';
import { api } from '../../services/api';
import { useToast } from '../../composables/useToast';
import PageHeader from '../common/PageHeader.vue';
import DataTable from '../common/DataTable.vue';
import StatusPill from '../common/StatusPill.vue';
import BaseModal from '../common/BaseModal.vue';
import ConfirmDialog from '../common/ConfirmDialog.vue';
import SwitchToggle from '../common/SwitchToggle.vue';
import {
  Plus,
  Search,
  Salad,
  Edit,
  Trash2,
  RefreshCw,
  Utensils,
  ExternalLink,
  AlertTriangle,
  Layers,
  Check,
  X,
} from 'lucide-vue-next';

const emit = defineEmits<{
  (e: 'ingredientCountChanged', count: number): void;
}>();

const { showToast } = useToast();

// Dữ liệu nguyên liệu & nhóm
const ingredients = ref<Ingredient[]>([]);
const groups = ref<IngredientGroup[]>([]);
const loading = ref(false);
const loadingGroups = ref(false);
const error = ref<string | null>(null);

// Bộ lọc
const searchQuery = ref('');
const statusFilter = ref<'all' | 'on' | 'off'>('all');
const selectedGroupId = ref<number | null>(null);
const currentPage = ref(1);
const pageSize = 10;

// Modal Thêm / Sửa nguyên liệu
const showModal = ref(false);
const isEditing = ref(false);
const editId = ref<number | null>(null);
const formName = ref('');
const formDescription = ref('');
const formGroupId = ref<number | null>(null);
const formIsActive = ref(true);
const formSaving = ref(false);

// Modal Xem danh sách món ăn đang sử dụng
const showDishesModal = ref(false);
const viewingIngredient = ref<IngredientDetail | null>(null);
const loadingDishes = ref(false);

// Hộp thoại Xác nhận Xóa nguyên liệu
const showDeleteConfirm = ref(false);
const ingredientToDelete = ref<Ingredient | null>(null);
const forceDelete = ref(false);
const deleteLoading = ref(false);

// Modal Quản lý Nhóm nguyên liệu
const showGroupsModal = ref(false);
const newGroupName = ref('');
const newGroupDesc = ref('');
const savingNewGroup = ref(false);

// Sửa nhanh nhóm trong modal quản lý nhóm
const editingGroupId = ref<number | null>(null);
const editGroupName = ref('');
const editGroupDesc = ref('');
const savingEditGroup = ref(false);

// Xác nhận xóa nhóm nguyên liệu
const showDeleteGroupConfirm = ref(false);
const groupToDelete = ref<IngredientGroup | null>(null);
const forceDeleteGroup = ref(false);
const deletingGroup = ref(false);

// Hàm chuẩn hóa tiếng Việt hỗ trợ tìm kiếm không dấu
function normalizeText(str: string): string {
  if (!str) return '';
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'd');
}

// Lọc dữ liệu nguyên liệu
const filteredIngredients = computed(() => {
  let list = ingredients.value;

  // Lọc theo nhóm nguyên liệu
  if (selectedGroupId.value !== null) {
    list = list.filter((i) => i.group_id === selectedGroupId.value);
  }

  // Lọc theo trạng thái
  if (statusFilter.value === 'on') {
    list = list.filter((i) => i.is_active);
  } else if (statusFilter.value === 'off') {
    list = list.filter((i) => !i.is_active);
  }

  // Lọc theo từ khóa tìm kiếm (tên, mô tả hoặc tên nhóm)
  const q = normalizeText(searchQuery.value.trim());
  if (q) {
    list = list.filter((i) => {
      const nameMatch = normalizeText(i.name).includes(q);
      const descMatch = i.description ? normalizeText(i.description).includes(q) : false;
      const groupMatch = i.group_name ? normalizeText(i.group_name).includes(q) : false;
      return nameMatch || descMatch || groupMatch;
    });
  }

  return list;
});

// Phân trang
const paginatedIngredients = computed(() => {
  const start = (currentPage.value - 1) * pageSize;
  return filteredIngredients.value.slice(start, start + pageSize);
});

// Thống kê nhanh
const totalCount = computed(() => ingredients.value.length);
const activeCount = computed(() => ingredients.value.filter((i) => i.is_active).length);
const usedCount = computed(() => ingredients.value.filter((i) => (i.dish_count || 0) > 0).length);
const groupCount = computed(() => groups.value.length);

// Reset trang khi thay đổi tìm kiếm hoặc bộ lọc
watch([searchQuery, statusFilter, selectedGroupId], () => {
  currentPage.value = 1;
});

// Tải danh sách nhóm nguyên liệu
async function fetchGroups() {
  loadingGroups.value = true;
  try {
    const res = await api.getIngredientGroups();
    groups.value = res || [];
  } catch (err: any) {
    // im lặng bỏ qua nếu lỗi
  } finally {
    loadingGroups.value = false;
  }
}

// Tải danh sách nguyên liệu từ API
async function fetchIngredients() {
  loading.value = true;
  error.value = null;
  try {
    const res = await api.getIngredients({ limit: 500 });
    ingredients.value = res.items || [];
    emit('ingredientCountChanged', res.total);
  } catch (err: any) {
    error.value = err.message || 'Không thể tải danh sách nguyên liệu';
    showToast(error.value!);
  } finally {
    loading.value = false;
  }
}

function resetFilters() {
  searchQuery.value = '';
  statusFilter.value = 'all';
  selectedGroupId.value = null;
  currentPage.value = 1;
}

// Mở modal tạo mới nguyên liệu
function openCreateModal() {
  isEditing.value = false;
  editId.value = null;
  formName.value = '';
  formDescription.value = '';
  // Nếu đang chọn một nhóm cụ thể thì mặc định gán vào nhóm đó
  formGroupId.value = selectedGroupId.value;
  formIsActive.value = true;
  showModal.value = true;
}

// Mở modal chỉnh sửa nguyên liệu
function openEditModal(ing: Ingredient) {
  isEditing.value = true;
  editId.value = ing.id;
  formName.value = ing.name;
  formDescription.value = ing.description || '';
  formGroupId.value = ing.group_id ?? null;
  formIsActive.value = ing.is_active;
  showModal.value = true;
}

// Lưu nguyên liệu (Thêm mới hoặc Cập nhật)
async function saveIngredient() {
  const cleanName = formName.value.trim();
  if (!cleanName) {
    showToast('Tên nguyên liệu không được để trống.');
    return;
  }

  formSaving.value = true;
  try {
    if (isEditing.value && editId.value != null) {
      const updated = await api.updateIngredient(editId.value, {
        name: cleanName,
        description: formDescription.value.trim() || undefined,
        group_id: formGroupId.value,
        is_active: formIsActive.value,
      });
      const idx = ingredients.value.findIndex((i) => i.id === editId.value);
      if (idx !== -1) {
        ingredients.value[idx] = { ...ingredients.value[idx], ...updated };
      }
      showToast(`Cập nhật nguyên liệu "${cleanName}" thành công!`);
    } else {
      const created = await api.createIngredient({
        name: cleanName,
        description: formDescription.value.trim() || undefined,
        group_id: formGroupId.value,
        is_active: formIsActive.value,
      });
      ingredients.value.unshift(created);
      emit('ingredientCountChanged', ingredients.value.length);
      showToast(`Thêm mới nguyên liệu "${cleanName}" thành công!`);
    }
    showModal.value = false;
    fetchGroups(); // cập nhật lại số lượng nguyên liệu trong nhóm
  } catch (err: any) {
    showToast(err.message || 'Lỗi lưu nguyên liệu');
  } finally {
    formSaving.value = false;
  }
}

// Bật / Tắt trạng thái hoạt động nhanh
async function toggleActive(ing: Ingredient) {
  const nextStatus = !ing.is_active;
  try {
    const updated = await api.updateIngredient(ing.id, {
      is_active: nextStatus,
    });
    ing.is_active = updated.is_active;
    showToast(`Đã ${nextStatus ? 'kích hoạt' : 'tạm ẩn'} nguyên liệu "${ing.name}".`);
  } catch (err: any) {
    showToast(err.message || 'Lỗi cập nhật trạng thái');
  }
}

// Mở modal xem danh sách món ăn đang dùng nguyên liệu
async function viewIngredientDishes(ing: Ingredient) {
  showDishesModal.value = true;
  loadingDishes.value = true;
  viewingIngredient.value = null;
  try {
    const detail = await api.getIngredientDetail(ing.id);
    viewingIngredient.value = detail;
  } catch (err: any) {
    showToast(err.message || 'Lỗi tải danh sách món ăn');
    showDishesModal.value = false;
  } finally {
    loadingDishes.value = false;
  }
}

// Mở dialog xác nhận xóa nguyên liệu
function promptDelete(ing: Ingredient) {
  ingredientToDelete.value = ing;
  forceDelete.value = false;
  showDeleteConfirm.value = true;
}

// Thực hiện xóa nguyên liệu
async function confirmDelete() {
  if (!ingredientToDelete.value) return;
  const ing = ingredientToDelete.value;
  deleteLoading.value = true;
  try {
    await api.deleteIngredient(ing.id, forceDelete.value);
    ingredients.value = ingredients.value.filter((i) => i.id !== ing.id);
    emit('ingredientCountChanged', ingredients.value.length);
    showToast(`Đã xóa nguyên liệu "${ing.name}" thành công!`);
    showDeleteConfirm.value = false;
    fetchGroups();
  } catch (err: any) {
    showToast(err.message || 'Lỗi xóa nguyên liệu');
  } finally {
    deleteLoading.value = false;
  }
}

// ==========================================
// CÁC HÀM QUẢN LÝ NHÓM NGUYÊN LIỆU (GROUPS)
// ==========================================
function openGroupsModal() {
  newGroupName.value = '';
  newGroupDesc.value = '';
  editingGroupId.value = null;
  showGroupsModal.value = true;
}

// Tạo nhóm nguyên liệu mới
async function createGroup() {
  const cleanName = newGroupName.value.trim();
  if (!cleanName) {
    showToast('Tên nhóm nguyên liệu không được để trống.');
    return;
  }

  savingNewGroup.value = true;
  try {
    const created = await api.createIngredientGroup({
      name: cleanName,
      description: newGroupDesc.value.trim() || undefined,
    });
    groups.value.push(created);
    newGroupName.value = '';
    newGroupDesc.value = '';
    showToast(`Tạo nhóm "${cleanName}" thành công!`);
  } catch (err: any) {
    showToast(err.message || 'Lỗi tạo nhóm nguyên liệu');
  } finally {
    savingNewGroup.value = false;
  }
}

// Bắt đầu sửa nhóm
function startEditGroup(grp: IngredientGroup) {
  editingGroupId.value = grp.id;
  editGroupName.value = grp.name;
  editGroupDesc.value = grp.description || '';
}

// Lưu sửa nhóm
async function saveEditGroup(grp: IngredientGroup) {
  const cleanName = editGroupName.value.trim();
  if (!cleanName) {
    showToast('Tên nhóm không được để trống.');
    return;
  }

  savingEditGroup.value = true;
  try {
    const updated = await api.updateIngredientGroup(grp.id, {
      name: cleanName,
      description: editGroupDesc.value.trim() || undefined,
    });
    const idx = groups.value.findIndex((g) => g.id === grp.id);
    if (idx !== -1) {
      groups.value[idx] = { ...groups.value[idx], ...updated };
    }
    // Cập nhật group_name trong danh sách nguyên liệu
    ingredients.value.forEach((ing) => {
      if (ing.group_id === grp.id) {
        ing.group_name = updated.name;
      }
    });
    editingGroupId.value = null;
    showToast(`Cập nhật nhóm "${cleanName}" thành công!`);
  } catch (err: any) {
    showToast(err.message || 'Lỗi cập nhật nhóm');
  } finally {
    savingEditGroup.value = false;
  }
}

// Hủy sửa nhóm
function cancelEditGroup() {
  editingGroupId.value = null;
}

// Prompt xóa nhóm
function promptDeleteGroup(grp: IngredientGroup) {
  groupToDelete.value = grp;
  forceDeleteGroup.value = false;
  showDeleteGroupConfirm.value = true;
}

// Xác nhận xóa nhóm
async function confirmDeleteGroup() {
  if (!groupToDelete.value) return;
  const grp = groupToDelete.value;
  deletingGroup.value = true;
  try {
    await api.deleteIngredientGroup(grp.id, forceDeleteGroup.value);
    groups.value = groups.value.filter((g) => g.id !== grp.id);
    if (selectedGroupId.value === grp.id) {
      selectedGroupId.value = null;
    }
    // Gỡ group_id của nguyên liệu về null
    ingredients.value.forEach((ing) => {
      if (ing.group_id === grp.id) {
        ing.group_id = null;
        ing.group_name = null;
      }
    });
    showToast(`Đã xóa nhóm "${grp.name}" thành công!`);
    showDeleteGroupConfirm.value = false;
  } catch (err: any) {
    showToast(err.message || 'Lỗi xóa nhóm nguyên liệu');
  } finally {
    deletingGroup.value = false;
  }
}

onMounted(() => {
  fetchGroups();
  fetchIngredients();
});
</script>

<template>
  <div class="ingredients-tab">
    <PageHeader
      title="Quản lý Nguyên liệu & Nhóm"
      subtitle="Quản lý danh mục nguyên liệu thực phẩm, phân loại theo nhóm (Hải sản, Thịt gia súc, Rau củ...) và kiểm soát món ăn sử dụng."
    >
      <template #actions>
        <button
          type="button"
          class="btn btn-sec"
          @click="openGroupsModal"
        >
          <Layers class="btn-icon" />
          <span>Quản lý nhóm ({{ groupCount }})</span>
        </button>
        <button
          type="button"
          class="btn btn-pri"
          @click="openCreateModal"
        >
          <Plus class="btn-icon" />
          <span>Thêm nguyên liệu</span>
        </button>
      </template>
    </PageHeader>

    <!-- Thống kê nhanh -->
    <div class="stats-pills">
      <div class="stat-pill">
        <span class="stat-pill-label">Tổng nguyên liệu:</span>
        <b class="stat-pill-val">{{ totalCount }}</b>
      </div>
      <div class="stat-pill">
        <span class="stat-pill-label">Nhóm nguyên liệu:</span>
        <b class="stat-pill-val stat-pri">{{ groupCount }} nhóm</b>
      </div>
      <div class="stat-pill">
        <span class="stat-pill-label">Đang hoạt động:</span>
        <b class="stat-pill-val stat-ok">{{ activeCount }}</b>
      </div>
      <div class="stat-pill">
        <span class="stat-pill-label">Đang dùng trong món ăn:</span>
        <b class="stat-pill-val stat-info">{{ usedCount }}</b>
      </div>
    </div>

    <!-- Thanh lọc Nhóm nguyên liệu dạng Tabs cuộn ngang -->
    <div class="group-tabs-wrap">
      <div class="group-tabs-scroll" role="tablist" aria-label="Nhóm nguyên liệu">
        <button
          type="button"
          class="group-tab-btn"
          :class="{ active: selectedGroupId === null }"
          @click="selectedGroupId = null"
        >
          <span>Tất cả</span>
          <span class="tab-count">{{ totalCount }}</span>
        </button>
        <button
          v-for="grp in groups"
          :key="grp.id"
          type="button"
          class="group-tab-btn"
          :class="{ active: selectedGroupId === grp.id }"
          @click="selectedGroupId = grp.id"
        >
          <span>{{ grp.name }}</span>
          <span class="tab-count">{{ grp.ingredient_count || 0 }}</span>
        </button>
      </div>
    </div>

    <!-- Bảng dữ liệu chính -->
    <DataTable
      v-model:current-page="currentPage"
      :total-items="filteredIngredients.length"
      :page-size="pageSize"
      item-name="nguyên liệu"
      :loading="loading"
      :error="error"
      :empty="filteredIngredients.length === 0"
      empty-message="Không tìm thấy nguyên liệu nào phù hợp với bộ lọc."
      empty-action="Đặt lại bộ lọc"
      @empty-action-click="resetFilters"
      @retry="fetchIngredients"
    >
      <!-- Toolbar slot -->
      <template #toolbar>
        <label class="srch" aria-label="Tìm kiếm nguyên liệu">
          <Search class="srch-icon" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Tìm theo tên nguyên liệu, nhóm, mô tả (thit bo, hai san, nam)..."
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
            Đang dùng
          </button>
          <button
            type="button"
            :class="{ on: statusFilter === 'off' }"
            @click="statusFilter = 'off'"
          >
            Tạm ẩn
          </button>
        </div>

        <button
          type="button"
          class="btn-icon-sq"
          title="Tải lại danh sách"
          aria-label="Tải lại"
          @click="fetchIngredients"
        >
          <RefreshCw class="btn-icon" :class="{ spinning: loading }" />
        </button>
      </template>

      <!-- Table headers -->
      <thead>
        <tr>
          <th style="width: 60px;">ID</th>
          <th>Tên nguyên liệu</th>
          <th style="width: 170px;">Nhóm nguyên liệu</th>
          <th>Mô tả / Ghi chú</th>
          <th style="width: 140px; text-align: center;">Món ăn sử dụng</th>
          <th style="width: 130px; text-align: center;">Trạng thái</th>
          <th style="width: 100px; text-align: right;">Thao tác</th>
        </tr>
      </thead>

      <!-- Table body -->
      <tbody>
        <tr v-for="ing in paginatedIngredients" :key="ing.id">
          <!-- ID -->
          <td class="text-mut font-mono">#{{ ing.id }}</td>

          <!-- Tên nguyên liệu -->
          <td>
            <div class="ing-name-cell">
              <div class="ing-icon-wrap">
                <Salad class="ing-icon" />
              </div>
              <div>
                <b class="ing-title">{{ ing.name }}</b>
                <div v-if="ing.created_at" class="ing-date">
                  Ngày tạo: {{ new Date(ing.created_at).toLocaleDateString('vi-VN') }}
                </div>
              </div>
            </div>
          </td>

          <!-- Nhóm nguyên liệu -->
          <td>
            <span v-if="ing.group_name" class="group-pill">
              <Layers class="group-pill-icon" />
              <span>{{ ing.group_name }}</span>
            </span>
            <span v-else class="text-mut text-italic text-sm">Chưa phân nhóm</span>
          </td>

          <!-- Mô tả -->
          <td>
            <span v-if="ing.description" class="ing-desc">{{ ing.description }}</span>
            <span v-else class="text-mut text-italic">— Chưa có mô tả —</span>
          </td>

          <!-- Món ăn sử dụng -->
          <td style="text-align: center;">
            <button
              v-if="(ing.dish_count || 0) > 0"
              type="button"
              class="badge-link"
              title="Bấm để xem danh sách món ăn"
              @click="viewIngredientDishes(ing)"
            >
              <Utensils class="badge-icon" />
              <span>{{ ing.dish_count }} món</span>
              <ExternalLink class="badge-ext-icon" />
            </button>
            <span v-else class="badge-zero">0 món</span>
          </td>

          <!-- Trạng thái -->
          <td style="text-align: center;">
            <button
              type="button"
              class="status-toggle-btn"
              :title="ing.is_active ? 'Bấm để tạm ẩn' : 'Bấm để kích hoạt'"
              @click="toggleActive(ing)"
            >
              <StatusPill :status="ing.is_active ? 'active' : 'inactive'">
                {{ ing.is_active ? 'Hoạt động' : 'Tạm ẩn' }}
              </StatusPill>
            </button>
          </td>

          <!-- Thao tác -->
          <td style="text-align: right;">
            <div class="row-actions">
              <button
                type="button"
                class="tb-btn"
                title="Chỉnh sửa nguyên liệu"
                @click="openEditModal(ing)"
              >
                <Edit class="tb-icon" />
              </button>
              <button
                type="button"
                class="tb-btn tb-danger"
                title="Xóa nguyên liệu"
                @click="promptDelete(ing)"
              >
                <Trash2 class="tb-icon" />
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </DataTable>

    <!-- MODAL: THÊM / SỬA NGUYÊN LIỆU -->
    <BaseModal
      v-model="showModal"
      :title="isEditing ? 'Chỉnh sửa nguyên liệu' : 'Thêm nguyên liệu mới'"
      @close="showModal = false"
    >
      <form class="modal-form" @submit.prevent="saveIngredient">
        <div class="form-group">
          <label class="form-label">Tên nguyên liệu <span class="req">*</span></label>
          <input
            v-model="formName"
            type="text"
            class="form-input"
            placeholder="Ví dụ: Tôm sú, Cua đồng, Sữa đặc, Bò Wagyu..."
            required
            autofocus
          />
        </div>

        <div class="form-group">
          <label class="form-label">Nhóm nguyên liệu</label>
          <select v-model="formGroupId" class="form-input">
            <option :value="null">-- Chưa phân nhóm --</option>
            <option v-for="g in groups" :key="g.id" :value="g.id">
              {{ g.name }}
            </option>
          </select>
        </div>

        <div class="form-group">
          <label class="form-label">Mô tả hoặc ghi chú</label>
          <textarea
            v-model="formDescription"
            class="form-input"
            rows="3"
            placeholder="Nguồn gốc, cách sơ chế, lưu ý (nếu có)..."
          ></textarea>
        </div>

        <div class="form-group">
          <label class="form-label">Trạng thái hoạt động</label>
          <label class="toggle-wrap">
            <SwitchToggle v-model="formIsActive" />
            <span class="toggle-label-text">
              {{ formIsActive ? 'Kích hoạt (cho phép chọn khi tạo món ăn)' : 'Tạm ẩn' }}
            </span>
          </label>
        </div>

        <div class="modal-actions">
          <button
            type="button"
            class="btn btn-sec"
            :disabled="formSaving"
            @click="showModal = false"
          >
            Hủy
          </button>
          <button
            type="submit"
            class="btn btn-pri"
            :disabled="formSaving"
          >
            <RefreshCw v-if="formSaving" class="btn-icon spinning" />
            <span>{{ isEditing ? 'Lưu thay đổi' : 'Tạo nguyên liệu' }}</span>
          </button>
        </div>
      </form>
    </BaseModal>

    <!-- MODAL: QUẢN LÝ NHÓM NGUYÊN LIỆU (GROUPS) -->
    <BaseModal
      v-model="showGroupsModal"
      title="Quản lý Nhóm nguyên liệu"
      @close="showGroupsModal = false"
    >
      <div class="groups-manager">
        <!-- Form thêm nhóm mới -->
        <form class="add-group-box" @submit.prevent="createGroup">
          <div class="add-group-row">
            <input
              v-model="newGroupName"
              type="text"
              class="form-input"
              placeholder="Tên nhóm mới (vd: Hải sản, Thịt đỏ, Đồ khô...)"
              required
            />
            <button
              type="submit"
              class="btn btn-pri"
              :disabled="savingNewGroup"
            >
              <Plus class="btn-icon" />
              <span>Thêm nhóm</span>
            </button>
          </div>
          <input
            v-model="newGroupDesc"
            type="text"
            class="form-input form-input-sub"
            placeholder="Mô tả ngắn nhóm nguyên liệu (tuỳ chọn)..."
          />
        </form>

        <!-- Danh sách nhóm hiện có -->
        <div class="groups-list">
          <div
            v-for="grp in groups"
            :key="grp.id"
            class="group-row-item"
          >
            <!-- Nếu đang sửa nhóm này -->
            <div v-if="editingGroupId === grp.id" class="group-edit-row">
              <input
                v-model="editGroupName"
                type="text"
                class="form-input form-input-sm"
                required
              />
              <input
                v-model="editGroupDesc"
                type="text"
                class="form-input form-input-sm"
                placeholder="Mô tả..."
              />
              <div class="group-edit-btns">
                <button
                  type="button"
                  class="btn-icon-sq btn-icon-ok"
                  title="Lưu"
                  :disabled="savingEditGroup"
                  @click="saveEditGroup(grp)"
                >
                  <Check class="btn-icon" />
                </button>
                <button
                  type="button"
                  class="btn-icon-sq"
                  title="Hủy"
                  @click="cancelEditGroup"
                >
                  <X class="btn-icon" />
                </button>
              </div>
            </div>

            <!-- Nếu đang xem bình thường -->
            <div v-else class="group-view-row">
              <div class="group-view-info">
                <div class="group-title-row">
                  <b class="group-name-text">{{ grp.name }}</b>
                  <span class="group-count-badge">{{ grp.ingredient_count || 0 }} nguyên liệu</span>
                </div>
                <small v-if="grp.description" class="group-desc-text">{{ grp.description }}</small>
              </div>
              <div class="group-actions">
                <button
                  type="button"
                  class="tb-btn"
                  title="Sửa tên nhóm"
                  @click="startEditGroup(grp)"
                >
                  <Edit class="tb-icon" />
                </button>
                <button
                  type="button"
                  class="tb-btn tb-danger"
                  title="Xóa nhóm"
                  @click="promptDeleteGroup(grp)"
                >
                  <Trash2 class="tb-icon" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-actions">
          <button
            type="button"
            class="btn btn-sec"
            @click="showGroupsModal = false"
          >
            Đóng
          </button>
        </div>
      </div>
    </BaseModal>

    <!-- CONFIRM DIALOG: XÓA NHÓM NGUYÊN LIỆU -->
    <ConfirmDialog
      v-model="showDeleteGroupConfirm"
      title="Xác nhận xóa nhóm nguyên liệu"
      :message="`Bạn có chắc chắn muốn xóa nhóm '${groupToDelete?.name || ''}'?`"
      confirm-text="Xóa nhóm"
      cancel-text="Hủy"
      :danger="true"
      :loading="deletingGroup"
      @confirm="confirmDeleteGroup"
      @cancel="showDeleteGroupConfirm = false"
    >
      <div
        v-if="(groupToDelete?.ingredient_count || 0) > 0"
        class="delete-warning-box"
      >
        <div class="warning-header">
          <AlertTriangle class="warn-icon" />
          <b>Chú ý:</b>
        </div>
        <p class="warn-text">
          Nhóm này đang có <b>{{ groupToDelete?.ingredient_count }}</b> nguyên liệu.
          Nếu xóa nhóm, các nguyên liệu này sẽ chuyển về trạng thái <i>Chưa phân nhóm</i>.
        </p>
        <label class="force-delete-checkbox">
          <input
            v-model="forceDeleteGroup"
            type="checkbox"
          />
          <span>Xác nhận xóa nhóm và gỡ phân loại các nguyên liệu</span>
        </label>
      </div>
    </ConfirmDialog>

    <!-- MODAL: XEM DANH SÁCH MÓN ĂN DÙNG NGUYÊN LIỆU -->
    <BaseModal
      v-model="showDishesModal"
      :title="`Các món ăn chứa: ${viewingIngredient?.name || ''}`"
      @close="showDishesModal = false"
    >
      <div v-if="loadingDishes" class="loading-state">
        <RefreshCw class="btn-icon spinning" />
        <span>Đang tải danh sách món ăn...</span>
      </div>

      <div v-else-if="viewingIngredient">
        <div class="modal-desc-banner">
          Nguyên liệu <b>{{ viewingIngredient.name }}</b>
          <span v-if="viewingIngredient.group_name">
            (thuộc nhóm: <b>{{ viewingIngredient.group_name }}</b>)
          </span>
          đang có mặt trong <b>{{ viewingIngredient.dishes.length }}</b> món ăn của hệ thống:
        </div>

        <div v-if="viewingIngredient.dishes.length === 0" class="empty-dishes">
          Chưa có món ăn nào liên kết với nguyên liệu này.
        </div>

        <div v-else class="linked-dishes-list">
          <div
            v-for="dish in viewingIngredient.dishes"
            :key="dish.id"
            class="linked-dish-item"
          >
            <div class="dish-item-info">
              <span class="dish-name">{{ dish.name }}</span>
              <span class="dish-sub">Mã món: #{{ dish.id }} • Quán ăn ID: {{ dish.restaurant_id }}</span>
            </div>
            <StatusPill :status="dish.is_available ? 'active' : 'inactive'">
              {{ dish.is_available ? 'Đang phục vụ' : 'Hết món' }}
            </StatusPill>
          </div>
        </div>
      </div>

      <div class="modal-actions">
        <button
          type="button"
          class="btn btn-sec"
          @click="showDishesModal = false"
        >
          Đóng
        </button>
      </div>
    </BaseModal>

    <!-- CONFIRM DIALOG: XÓA NGUYÊN LIỆU -->
    <ConfirmDialog
      v-model="showDeleteConfirm"
      title="Xác nhận xóa nguyên liệu"
      :message="`Bạn có chắc chắn muốn xóa nguyên liệu '${ingredientToDelete?.name || ''}' khỏi hệ thống?`"
      confirm-text="Xóa nguyên liệu"
      cancel-text="Hủy"
      :danger="true"
      :loading="deleteLoading"
      @confirm="confirmDelete"
      @cancel="showDeleteConfirm = false"
    >
      <div
        v-if="(ingredientToDelete?.dish_count || 0) > 0"
        class="delete-warning-box"
      >
        <div class="warning-header">
          <AlertTriangle class="warn-icon" />
          <b>Cảnh báo an toàn dữ liệu:</b>
        </div>
        <p class="warn-text">
          Nguyên liệu này hiện đang được liên kết trong <b>{{ ingredientToDelete?.dish_count }}</b> món ăn.
          Nếu bạn xóa, nguyên liệu sẽ bị gỡ bỏ khỏi toàn bộ các món ăn này.
        </p>
        <label class="force-delete-checkbox">
          <input
            v-model="forceDelete"
            type="checkbox"
          />
          <span>Tôi hiểu rủi ro và xác nhận bắt buộc xóa (Force delete)</span>
        </label>
      </div>
    </ConfirmDialog>
  </div>
</template>

<style scoped>
.ingredients-tab {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Thống kê nhanh */
.stats-pills {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.stat-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: var(--card, #ffffff);
  border: 1px solid var(--line, #e2e8f0);
  border-radius: 20px;
  font-size: 13px;
  color: var(--mut, #64748b);
}

.stat-pill-val {
  font-weight: 700;
  color: var(--fg, #0f172a);
}

.stat-ok {
  color: #16a34a;
}

.stat-pri {
  color: #2563eb;
}

.stat-info {
  color: #0284c7;
}

/* Thanh Tabs Nhóm nguyên liệu cuộn ngang */
.group-tabs-wrap {
  width: 100%;
  border-bottom: 1px solid var(--line, #e2e8f0);
  padding-bottom: 2px;
}

.group-tabs-scroll {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 6px;
  scrollbar-width: thin;
}

.group-tab-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 20px;
  border: 1px solid var(--line, #e2e8f0);
  background: var(--card, #ffffff);
  color: var(--fg, #334155);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease;
}

.group-tab-btn:hover {
  border-color: #93c5fd;
  color: #2563eb;
  background: #f8fafc;
}

.group-tab-btn.active {
  background: #2563eb;
  border-color: #2563eb;
  color: #ffffff;
  font-weight: 600;
}

.tab-count {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 10px;
  background: rgba(0, 0, 0, 0.06);
}

.group-tab-btn.active .tab-count {
  background: rgba(255, 255, 255, 0.25);
  color: #ffffff;
}

/* Pill nhóm nguyên liệu trong bảng */
.group-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #334155;
}

.group-pill-icon {
  width: 12px;
  height: 12px;
  color: #64748b;
}

/* Cell Tên nguyên liệu */
.ing-name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.ing-icon-wrap {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  background: #f0fdf4;
  border: 1px solid #dcfce7;
  color: #16a34a;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.ing-icon {
  width: 18px;
  height: 18px;
}

.ing-title {
  font-size: 14px;
  color: var(--fg, #0f172a);
}

.ing-date {
  font-size: 11.5px;
  color: var(--mut, #64748b);
  margin-top: 2px;
}

.ing-desc {
  font-size: 13px;
  color: var(--fg, #334155);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Badge món ăn sử dụng */
.badge-link {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  color: #2563eb;
  border-radius: 14px;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
}

.badge-link:hover {
  background: #dbeafe;
  border-color: #93c5fd;
}

.badge-icon {
  width: 13px;
  height: 13px;
}

.badge-ext-icon {
  width: 11px;
  height: 11px;
  opacity: 0.7;
}

.badge-zero {
  display: inline-block;
  padding: 4px 8px;
  background: #f1f5f9;
  color: #94a3b8;
  border-radius: 12px;
  font-size: 12px;
}

/* Nút toggle trạng thái */
.status-toggle-btn {
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
}

/* Nút thao tác hàng */
.row-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
}

.tb-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  border: 1px solid transparent;
  background: transparent;
  color: var(--mut, #64748b);
  cursor: pointer;
  transition: all 0.15s;
}

.tb-btn:hover {
  background: #f1f5f9;
  color: var(--fg, #0f172a);
}

.tb-danger:hover {
  background: #fee2e2;
  color: #dc2626;
}

.tb-icon {
  width: 16px;
  height: 16px;
}

/* Modal Form */
.modal-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.req {
  color: #dc2626;
}

.toggle-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  user-select: none;
}

.toggle-label-text {
  font-size: 13.5px;
  color: var(--fg, #334155);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 8px;
  padding-top: 14px;
  border-top: 1px solid var(--line, #e2e8f0);
}

/* Modal xem danh sách món ăn */
.modal-desc-banner {
  font-size: 13.5px;
  color: var(--fg, #334155);
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #f8fafc;
  border-radius: 6px;
}

.linked-dishes-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 280px;
  overflow-y: auto;
  padding-right: 4px;
}

.linked-dish-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border: 1px solid var(--line, #e2e8f0);
  border-radius: 8px;
  background: var(--card, #ffffff);
}

.dish-item-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.dish-name {
  font-weight: 600;
  font-size: 14px;
  color: var(--fg, #0f172a);
}

.dish-sub {
  font-size: 12px;
  color: var(--mut, #64748b);
}

.empty-dishes {
  text-align: center;
  padding: 24px;
  color: var(--mut, #64748b);
  font-size: 13.5px;
}

/* Quản lý nhóm trong Modal */
.groups-manager {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.add-group-box {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  background: #f8fafc;
  border: 1px solid var(--line, #e2e8f0);
  border-radius: 8px;
}

.add-group-row {
  display: flex;
  gap: 8px;
}

.form-input-sub {
  font-size: 12.5px;
}

.groups-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 320px;
  overflow-y: auto;
  padding-right: 4px;
}

.group-row-item {
  padding: 10px 12px;
  background: var(--card, #ffffff);
  border: 1px solid var(--line, #e2e8f0);
  border-radius: 8px;
}

.group-view-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.group-view-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.group-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.group-name-text {
  font-size: 14px;
  color: var(--fg, #0f172a);
}

.group-count-badge {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 10px;
  background: #eff6ff;
  color: #2563eb;
  font-weight: 500;
}

.group-desc-text {
  font-size: 12px;
  color: var(--mut, #64748b);
}

.group-actions {
  display: flex;
  align-items: center;
  gap: 4px;
}

.group-edit-row {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.form-input-sm {
  height: 34px;
  font-size: 13px;
  padding: 0 8px;
}

.group-edit-btns {
  display: flex;
  gap: 4px;
}

.btn-icon-ok {
  background: #f0fdf4;
  color: #16a34a;
  border-color: #bbf7d0;
}

.btn-icon-ok:hover {
  background: #dcfce7;
}

/* Cảnh báo xóa dữ liệu */
.delete-warning-box {
  margin-top: 12px;
  padding: 12px;
  background: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.warning-header {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #b45309;
  font-size: 13.5px;
}

.warn-icon {
  width: 18px;
  height: 18px;
  color: #d97706;
}

.warn-text {
  font-size: 13px;
  color: #92400e;
  margin: 0;
  line-height: 1.45;
}

.force-delete-checkbox {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  color: #b45309;
}

/* Tiện ích */
.spinning {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.text-mut {
  color: var(--mut, #64748b);
}

.text-italic {
  font-style: italic;
}

.text-sm {
  font-size: 12px;
}

.font-mono {
  font-family: monospace;
}
</style>
