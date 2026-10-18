<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse, Restaurant } from '../types';
import { api } from '../services/api';

const props = defineProps<{
  seller: RoleLoginResponse;
}>();

const restaurants = ref<Restaurant[]>([]);
const loading = ref(false);
const error = ref<string | null>(null);
const successMsg = ref<string | null>(null);

// Form state for Create / Edit
const showFormModal = ref(false);
const editingId = ref<number | null>(null);
const formName = ref('');
const formAddress = ref('');
const formPhone = ref('');
const formDesc = ref('');
const formLat = ref(21.0285);
const formLon = ref(105.8542);
const formLoading = ref(false);
const formError = ref<string | null>(null);

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
      // Create
      await api.createSellerRestaurant(props.seller.id, {
        name: formName.value,
        address: formAddress.value || undefined,
        phone: formPhone.value || undefined,
        description: formDesc.value || undefined,
        latitude: formLat.value,
        longitude: formLon.value,
      });
      successMsg.value = 'Tạo quán ăn mới thành công!';
    } else {
      // Update
      await api.updateSellerRestaurant(props.seller.id, editingId.value, {
        name: formName.value,
        address: formAddress.value || undefined,
        phone: formPhone.value || undefined,
        description: formDesc.value || undefined,
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
        ➕ Thêm quán ăn mới
      </button>
    </div>

    <!-- Success banner -->
    <div v-if="successMsg" class="alert alert-success">
      ✅ {{ successMsg }}
    </div>

    <!-- Error banner -->
    <div v-if="error" class="alert alert-error">
      ⚠️ {{ error }}
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
      <div class="icon">🏪</div>
      <h3>Bạn chưa đăng ký quán ăn nào</h3>
      <p>Hãy bắt đầu bằng cách thêm quán ăn đầu tiên của bạn vào hệ thống bản đồ!</p>
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
          <span class="badge" :class="r.is_active ? 'badge-success' : 'badge-danger'">
            {{ r.is_active ? 'Đang hoạt động' : 'Tạm dừng' }}
          </span>
        </div>

        <p v-if="r.address" class="meta">🏠 {{ r.address }}</p>
        <p v-if="r.phone" class="meta">📞 {{ r.phone }}</p>
        <p v-if="r.description" class="desc">{{ r.description }}</p>

        <div class="coords">
          Toạ độ: <code>{{ r.latitude }}, {{ r.longitude }}</code>
        </div>

        <div class="actions">
          <button type="button" class="btn btn-outline btn-sm" @click="openEditModal(r)">
            ✏️ Chỉnh sửa
          </button>
          <button type="button" class="btn btn-danger btn-sm" @click="handleDelete(r)">
            🗑️ Xoá
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Form Create / Edit -->
    <div v-if="showFormModal" class="modal-overlay" @click.self="showFormModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>{{ editingId == null ? 'Thêm Quán Ăn Mới' : 'Cập Nhật Quán Ăn' }}</h3>
          <button type="button" class="modal-close" @click="showFormModal = false">×</button>
        </div>

        <div v-if="formError" class="alert alert-error">
          ⚠️ {{ formError }}
        </div>

        <form @submit.prevent="handleSaveRestaurant">
          <div class="form-group">
            <label>Tên quán ăn *</label>
            <input v-model="formName" type="text" required placeholder="Bún Chả Hương Liên" />
          </div>

          <div class="form-group">
            <label>Địa chỉ hiển thị</label>
            <input v-model="formAddress" type="text" placeholder="24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội" />
          </div>

          <div class="form-group">
            <label>Hotline quán</label>
            <input v-model="formPhone" type="tel" placeholder="024 3943 4106" />
          </div>

          <div class="form-group">
            <label>Mô tả ngắn</label>
            <textarea v-model="formDesc" placeholder="Đặc sản bún chả gia truyền truyền thống"></textarea>
          </div>

          <div class="coords-grid">
            <div class="form-group">
              <label>Vĩ độ (Latitude) *</label>
              <input v-model.number="formLat" type="number" step="0.000001" required />
            </div>
            <div class="form-group">
              <label>Kinh độ (Longitude) *</label>
              <input v-model.number="formLon" type="number" step="0.000001" required />
            </div>
          </div>

          <div style="margin-top: 20px; display: flex; gap: 10px; justify-content: flex-end;">
            <button type="button" class="btn btn-outline" @click="showFormModal = false">
              Huỷ
            </button>
            <button type="submit" class="btn btn-primary" :disabled="formLoading">
              <span v-if="formLoading" class="spinner" style="width: 16px; height: 16px;"></span>
              <span v-else>{{ editingId == null ? 'Tạo quán' : 'Lưu thay đổi' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 20px;
}

.seller-card {
  display: flex;
  flex-direction: column;
}

.seller-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 8px;
}

.name {
  font-size: 1.15rem;
}

.meta {
  font-size: 0.88rem;
  color: var(--c-text);
  margin-bottom: 4px;
}

.desc {
  font-size: 0.85rem;
  color: var(--c-text-muted);
  margin-bottom: 8px;
}

.coords {
  font-size: 0.8rem;
  color: var(--c-text-muted);
  margin-bottom: 12px;
}

code {
  background: var(--c-bg);
  padding: 2px 6px;
  border-radius: 4px;
  border: 1px solid var(--c-border);
}

.actions {
  display: flex;
  gap: 8px;
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px dashed var(--c-border);
}

.coords-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
</style>
