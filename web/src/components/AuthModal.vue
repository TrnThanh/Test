<script setup lang="ts">
import { ref } from 'vue';
import type { RoleLoginResponse } from '../types';
import { api } from '../services/api';

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'loginSuccess', user: RoleLoginResponse): void;
}>();

const props = defineProps<{
  initialRole?: 'user' | 'seller' | 'admin';
}>();

const mode = ref<'login' | 'register'>('login');
const role = ref<'user' | 'seller' | 'admin'>(props.initialRole || 'user');

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
      if (role.value === 'admin') {
        result = await api.loginAdmin({ email: email.value, password: password.value });
      } else if (role.value === 'seller') {
        result = await api.loginSeller({ email: email.value, password: password.value });
      } else {
        result = await api.loginUser({ email: email.value, password: password.value });
      }
    } else {
      if (role.value === 'admin') {
        throw new Error('Tài khoản Quản trị viên (Admin) chỉ được tạo bởi hệ thống, không hỗ trợ đăng ký tự do.');
      } else if (role.value === 'seller') {
        result = await api.registerSeller({
          email: email.value,
          password: password.value,
          full_name: fullName.value || undefined,
          shop_name: shopName.value,
          phone: phone.value || undefined,
        });
      } else {
        result = await api.registerUser({
          email: email.value,
          password: password.value,
          full_name: fullName.value || undefined,
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
  <div class="modal-backdrop" @click.self="emit('close')">
    <div class="modal-card auth-modal">
      <div class="modal-header">
        <h3>{{ mode === 'login' ? 'Đăng nhập' : 'Đăng ký tài khoản' }}</h3>
        <button type="button" class="modal-close" @click="emit('close')">×</button>
      </div>

      <div class="modal-body">
        <!-- Role Selector 2 Roles for Portal: Seller & Admin -->
        <div class="role-selector">
          <button
            type="button"
            class="role-btn"
            :class="{ active: role === 'seller' }"
            @click="role = 'seller'; error = null;"
          >
            🏢 Chủ Quán
          </button>
          <button
            type="button"
            class="role-btn"
            :class="{ active: role === 'admin' }"
            @click="role = 'admin'; mode = 'login'; error = null;"
          >
            ⚙️ Quản Trị Hệ Thống
          </button>
        </div>

        <!-- Mode Switcher (only show if not admin) -->
        <div v-if="role !== 'admin'" class="segmented-control">
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
            Đăng ký mới
          </button>
        </div>

        <!-- Error box -->
        <div v-if="error" class="alert alert-error" style="margin-top: 14px;">
          {{ error }}
        </div>

        <!-- Form -->
        <form style="margin-top: 14px;" @submit.prevent="handleSubmit">
          <div class="form-group">
            <label class="form-label">
              {{ role === 'admin' ? 'Tài khoản Quản trị / Email *' : 'Địa chỉ Email *' }}
            </label>
            <input
              v-model="email"
              :type="role === 'admin' ? 'text' : 'email'"
              class="form-input"
              required
              :placeholder="role === 'admin' ? 'admin hoặc admin@ptc1.vn' : 'email@example.com'"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Mật khẩu *</label>
            <input
              v-model="password"
              type="password"
              class="form-input"
              required
              placeholder="••••••••"
            />
          </div>

          <template v-if="mode === 'register'">
            <div class="form-group">
              <label class="form-label">Họ và tên</label>
              <input
                v-model="fullName"
                type="text"
                class="form-input"
                placeholder="Nguyễn Văn A"
              />
            </div>

            <template v-if="role === 'seller'">
              <div class="form-group">
                <label class="form-label">Tên quán ăn / Shop *</label>
                <input
                  v-model="shopName"
                  type="text"
                  class="form-input"
                  required
                  placeholder="Bún Bò Huế 365"
                />
              </div>

              <div class="form-group">
                <label class="form-label">Số điện thoại liên hệ</label>
                <input
                  v-model="phone"
                  type="tel"
                  class="form-input"
                  placeholder="0912345678"
                />
              </div>
            </template>
          </template>

          <div style="margin-top: 20px;">
            <button
              type="submit"
              class="btn btn-primary btn-block"
              :disabled="loading"
            >
              {{ loading ? 'Đang xử lý...' : (mode === 'login' ? 'Đăng nhập ngay' : 'Đăng ký tài khoản') }}
            </button>
          </div>

          <!-- Quick Mock Fill Shortcuts -->
          <div v-if="mode === 'login'" class="mock-hint">
            <span class="mock-label">Tài khoản Mock thử nghiệm:</span>
            <div class="mock-buttons">
              <button
                type="button"
                class="btn-mock"
                @click="role = 'seller'; email = 'seller@ptc1.vn'; password = 'seller123';"
              >
                Điền Chủ Quán (seller@ptc1.vn)
              </button>
              <button
                type="button"
                class="btn-mock"
                @click="role = 'admin'; email = 'admin@ptc1.vn'; password = 'admin123';"
              >
                Điền Admin (admin@ptc1.vn)
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-modal {
  max-width: 440px;
}

.role-selector {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  margin-bottom: 16px;
}

.role-btn {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  padding: 8px 6px;
  font-size: 0.85rem;
  font-weight: 600;
  border-radius: var(--radius-md);
  color: var(--c-text-muted);
  cursor: pointer;
  transition: var(--transition);
  text-align: center;
}

.role-btn:hover {
  border-color: #09090b;
  color: #09090b;
}

.role-btn.active {
  background-color: #18181b;
  border-color: #18181b;
  color: #ffffff;
}

.segmented-control {
  display: flex;
  background-color: var(--c-bg);
  padding: 4px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
  margin-bottom: 16px;
}

.segment-btn {
  flex: 1;
  background: transparent;
  border: none;
  padding: 8px;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--c-text-muted);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition);
}

.segment-btn.active {
  background: var(--c-surface);
  color: var(--c-text);
  box-shadow: var(--shadow-sm);
}

.mock-hint {
  margin-top: 16px;
  padding-top: 14px;
  border-top: 1px dashed var(--c-border);
}

.mock-label {
  display: block;
  font-size: 0.78rem;
  color: var(--c-text-muted);
  margin-bottom: 8px;
  font-weight: 500;
}

.mock-buttons {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.btn-mock {
  background: #f4f4f5;
  border: 1px solid #e4e4e7;
  color: #18181b;
  font-size: 0.8rem;
  padding: 6px 10px;
  border-radius: 4px;
  cursor: pointer;
  text-align: left;
  transition: var(--transition);
}

.btn-mock:hover {
  background: #e4e4e7;
  border-color: #d4d4d8;
}
</style>
