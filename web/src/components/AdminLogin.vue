<script setup lang="ts">
import { ref } from 'vue';
import type { RoleLoginResponse } from '../types';
import { api } from '../services/api';

const emit = defineEmits<{
  (e: 'loginSuccess', user: RoleLoginResponse): void;
}>();

const email = ref('admin@example.com');
const password = ref('admin123');
const loading = ref(false);
const error = ref<string | null>(null);

async function handleLogin() {
  if (!email.value.trim() || !password.value) {
    error.value = 'Vui lòng nhập đầy đủ Email và Mật khẩu quản trị.';
    return;
  }

  error.value = null;
  loading.value = true;

  try {
    const res = await api.loginAdmin({
      email: email.value.trim(),
      password: password.value,
    });
    emit('loginSuccess', res);
  } catch (err: any) {
    error.value = err.message || 'Email hoặc mật khẩu quản trị không chính xác.';
  } finally {
    loading.value = false;
  }
}

function fillDefaultAdmin() {
  email.value = 'admin@example.com';
  password.value = 'admin123';
  handleLogin();
}
</script>

<template>
  <div class="login-wrapper">
    <div class="login-card">
      <div class="login-header">
        <div class="brand-badge">ADMIN CONSOLE</div>
        <h2>PTC1 Spatial Food</h2>
        <p class="subtitle">Cổng Quản Trị & Điều Hành Hệ Thống Dữ Liệu Ẩm Thực</p>
      </div>

      <div v-if="error" class="alert alert-error">
        {{ error }}
      </div>

      <form class="login-form" @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="admin-email">Email Quản Trị Viên</label>
          <input
            id="admin-email"
            v-model="email"
            type="email"
            class="input"
            placeholder="admin@example.com"
            required
            autocomplete="username"
          />
        </div>

        <div class="form-group">
          <label for="admin-password">Mật Khẩu</label>
          <input
            id="admin-password"
            v-model="password"
            type="password"
            class="input"
            placeholder="••••••••"
            required
            autocomplete="current-password"
          />
        </div>

        <button type="submit" class="btn btn-primary btn-block" :disabled="loading">
          {{ loading ? 'Đang xác thực...' : 'Đăng Nhập Quản Trị' }}
        </button>
      </form>

      <div class="login-footer">
        <div class="divider">
          <span>HOẶC</span>
        </div>
        <button type="button" class="btn btn-secondary btn-block" :disabled="loading" @click="fillDefaultAdmin">
          Đăng nhập nhanh với Tài Khoản Mẫu (admin@example.com)
        </button>
        <p class="hint">
          * Chỉ dành riêng cho ban điều hành và quản trị viên hệ thống. Người dùng thực khách vui lòng sử dụng ứng dụng Flutter Mobile.
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-wrapper {
  min-height: 80vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.login-card {
  width: 100%;
  max-width: 440px;
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 36px 32px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
}

.login-header {
  text-align: center;
  margin-bottom: 24px;
}

.brand-badge {
  display: inline-block;
  background-color: #18181b;
  color: #ffffff;
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  padding: 3px 8px;
  border-radius: 4px;
  margin-bottom: 12px;
}

.login-header h2 {
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--c-text);
  margin-bottom: 6px;
}

.subtitle {
  font-size: 0.88rem;
  color: var(--c-text-muted);
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--c-text);
}

.btn-block {
  width: 100%;
  padding: 10px 16px;
  font-size: 0.95rem;
}

.divider {
  display: flex;
  align-items: center;
  text-align: center;
  margin: 20px 0 16px;
  color: var(--c-text-muted);
  font-size: 0.75rem;
  letter-spacing: 0.08em;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid var(--c-border);
}

.divider span {
  padding: 0 10px;
}

.hint {
  margin-top: 16px;
  font-size: 0.78rem;
  color: var(--c-text-muted);
  line-height: 1.4;
  text-align: center;
}
</style>
