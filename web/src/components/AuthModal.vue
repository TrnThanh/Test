<script setup lang="ts">
import { ref } from 'vue';
import type { RoleLoginResponse } from '../types';
import { api } from '../services/api';

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'loginSuccess', user: RoleLoginResponse): void;
}>();

const mode = ref<'login' | 'register'>('login');
const role = ref<'user' | 'seller'>('user');

// Form fields
const email = ref('');
const password = ref('');
const fullName = ref('');
const shopName = ref('');
const phone = ref('');

const loading = ref(false);
const error = ref<string | null>(null);

async function handleSubmit() {
  error.value = null;
  loading.value = true;

  try {
    let result: RoleLoginResponse;
    if (mode.value === 'login') {
      if (role.value === 'user') {
        result = await api.loginUser({ email: email.value, password: password.value });
      } else {
        result = await api.loginSeller({ email: email.value, password: password.value });
      }
    } else {
      if (role.value === 'user') {
        result = await api.registerUser({
          email: email.value,
          password: password.value,
          full_name: fullName.value || undefined,
        });
      } else {
        result = await api.registerSeller({
          email: email.value,
          password: password.value,
          full_name: fullName.value || undefined,
          shop_name: shopName.value,
          phone: phone.value || undefined,
        });
      }
    }

    emit('loginSuccess', result);
    emit('close');
  } catch (err: any) {
    error.value = err.message || 'Xác thực không thành công';
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="modal-overlay" @click.self="emit('close')">
    <div class="modal-content auth-modal">
      <div class="modal-header">
        <h3>{{ mode === 'login' ? 'Đăng nhập' : 'Tạo tài khoản mới' }}</h3>
        <button type="button" class="modal-close" @click="emit('close')">×</button>
      </div>

      <!-- Mode Switcher -->
      <div class="segmented-control">
        <button
          type="button"
          class="segment-btn"
          :class="{ active: mode === 'login' }"
          @click="mode = 'login'; error = null;"
        >
          Đăng nhập
        </button>
        <button
          type="button"
          class="segment-btn"
          :class="{ active: mode === 'register' }"
          @click="mode = 'register'; error = null;"
        >
          Đăng ký
        </button>
      </div>

      <!-- Role Selector -->
      <div class="role-selector">
        <label
          class="role-card"
          :class="{ active: role === 'user' }"
          @click="role = 'user'; error = null;"
        >
          <input type="radio" name="role" value="user" :checked="role === 'user'" />
          <div>
            <div class="role-title">👤 Thực khách (User)</div>
            <div class="role-desc">Xem quán, tìm kiếm món ăn</div>
          </div>
        </label>

        <label
          class="role-card"
          :class="{ active: role === 'seller' }"
          @click="role = 'seller'; error = null;"
        >
          <input type="radio" name="role" value="seller" :checked="role === 'seller'" />
          <div>
            <div class="role-title">🏪 Chủ quán (Seller)</div>
            <div class="role-desc">Đăng quán, quản lý cửa hàng</div>
          </div>
        </label>
      </div>

      <!-- Error box -->
      <div v-if="error" class="alert alert-error" style="margin-top: 14px;">
        ⚠️ {{ error }}
      </div>

      <!-- Form -->
      <form style="margin-top: 14px;" @submit.prevent="handleSubmit">
        <div class="form-group">
          <label>Email *</label>
          <input
            v-model="email"
            type="email"
            required
            placeholder="example@domain.com"
          />
        </div>

        <div class="form-group">
          <label>Mật khẩu *</label>
          <input
            v-model="password"
            type="password"
            required
            placeholder="••••••••"
          />
        </div>

        <template v-if="mode === 'register'">
          <div class="form-group">
            <label>Họ và tên</label>
            <input
              v-model="fullName"
              type="text"
              placeholder="Nguyễn Văn A"
            />
          </div>

          <template v-if="role === 'seller'">
            <div class="form-group">
              <label>Tên quán ăn / Shop *</label>
              <input
                v-model="shopName"
                type="text"
                required
                placeholder="Phở Bát Đàn"
              />
            </div>

            <div class="form-group">
              <label>Số điện thoại liên hệ</label>
              <input
                v-model="phone"
                type="tel"
                placeholder="0912345678"
              />
            </div>
          </template>
        </template>

        <button
          type="submit"
          class="btn btn-primary"
          style="width: 100%; margin-top: 8px;"
          :disabled="loading"
        >
          <span v-if="loading" class="spinner" style="width: 16px; height: 16px;"></span>
          <span v-else>{{ mode === 'login' ? 'Đăng nhập ngay' : 'Đăng ký tài khoản' }}</span>
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.auth-modal {
  max-width: 440px;
}

.segmented-control {
  display: flex;
  background: var(--c-bg);
  padding: 4px;
  border-radius: var(--radius-sm);
  margin-bottom: 16px;
  border: 1px solid var(--c-border);
}

.segment-btn {
  flex: 1;
  background: none;
  border: none;
  padding: 8px;
  border-radius: var(--radius-sm);
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--c-text-muted);
  cursor: pointer;
  transition: var(--transition);
}

.segment-btn.active {
  background: var(--c-surface);
  color: var(--c-primary);
  box-shadow: var(--shadow-sm);
}

.role-selector {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 12px;
}

.role-card {
  border: 1px solid var(--c-border);
  border-radius: var(--radius-sm);
  padding: 10px;
  cursor: pointer;
  display: flex;
  align-items: flex-start;
  gap: 8px;
  transition: var(--transition);
}

.role-card input[type="radio"] {
  width: auto;
  margin-top: 3px;
  accent-color: var(--c-primary);
}

.role-card:hover {
  border-color: var(--c-border-hover);
}

.role-card.active {
  border-color: var(--c-primary);
  background: var(--c-primary-light);
}

.role-title {
  font-size: 0.88rem;
  font-weight: 700;
  color: var(--c-text);
}

.role-desc {
  font-size: 0.75rem;
  color: var(--c-text-muted);
  margin-top: 2px;
}
</style>
