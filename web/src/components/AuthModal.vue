<script setup lang="ts">
import { ref } from 'vue';
import type { RoleLoginResponse } from '../types';
import { api } from '../services/api';

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'loginSuccess', user: RoleLoginResponse): void;
}>();

// Form fields
const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref<string | null>(null);

async function handleSubmit() {
  error.value = null;
  loading.value = true;

  try {
    const result = await api.loginAdmin({ email: email.value, password: password.value });
    emit('loginSuccess', result);
    emit('close');
  } catch (err: any) {
    error.value = err.message || 'Xác thực tài khoản Admin không thành công';
  } finally {
    loading.value = false;
  }
}

function fillMockAdmin() {
  email.value = 'admin@ptc1.vn';
  password.value = 'admin123';
  error.value = null;
}
</script>

<template>
  <div class="modal-backdrop" @click.self="emit('close')">
    <div class="modal-card auth-modal">
      <div class="modal-header">
        <div>
          <h3>Đăng nhập Quản Trị Hệ Thống</h3>
          <p style="font-size: 0.8rem; color: var(--c-text-muted); margin-top: 2px;">Cổng dành riêng cho Quản trị viên (Admin)</p>
        </div>
        <button type="button" class="modal-close" @click="emit('close')">×</button>
      </div>

      <div class="modal-body">
        <!-- Error box -->
        <div v-if="error" class="alert alert-error">
          {{ error }}
        </div>

        <!-- Form -->
        <form @submit.prevent="handleSubmit">
          <div class="form-group">
            <label class="form-label">Tài khoản Quản trị / Email *</label>
            <input
              v-model="email"
              type="text"
              class="form-input"
              required
              placeholder="admin@ptc1.vn hoặc admin"
              autofocus
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

          <div style="margin-top: 20px;">
            <button
              type="submit"
              class="btn btn-primary btn-block"
              :disabled="loading"
            >
              {{ loading ? 'Đang xác thực...' : 'Đăng nhập Quản Trị' }}
            </button>
          </div>

          <!-- Quick Mock Fill Shortcuts -->
          <div class="mock-hint">
            <span class="mock-label">Tài khoản Admin thử nghiệm:</span>
            <div class="mock-buttons">
              <button
                type="button"
                class="btn-mock"
                @click="fillMockAdmin"
              >
                ⚡ Điền tài khoản Admin: admin@ptc1.vn / admin123
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

.mock-hint {
  margin-top: 18px;
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
  padding: 8px 12px;
  border-radius: 4px;
  cursor: pointer;
  text-align: left;
  transition: var(--transition);
  font-weight: 500;
}

.btn-mock:hover {
  background: #e4e4e7;
  border-color: #d4d4d8;
}
</style>
