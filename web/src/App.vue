<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse } from './types';
import AdminDashboard from './components/AdminDashboard.vue';
import AdminLogin from './components/AdminLogin.vue';

const currentUser = ref<RoleLoginResponse | null>(null);
const STORAGE_KEY = 'ptc1_admin_auth_session';

function restoreSession() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    try {
      const user = JSON.parse(saved);
      if (user?.role === 'admin') {
        currentUser.value = user;
      } else {
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
  }
}

function handleLoginSuccess(user: RoleLoginResponse) {
  currentUser.value = user;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
}

function handleLogout() {
  currentUser.value = null;
  localStorage.removeItem(STORAGE_KEY);
}

onMounted(() => {
  restoreSession();
});
</script>

<template>
  <div class="app-layout">
    <!-- Main Workspace: Admin Dashboard (Khi đã đăng nhập) hoặc Admin Login (Khi chưa đăng nhập) -->
    <main class="main-body">
      <AdminDashboard
        v-if="currentUser?.role === 'admin'"
        :admin="currentUser"
        @logout="handleLogout"
      />
      <AdminLogin
        v-else
        @login-success="handleLoginSuccess"
      />
    </main>

    <!-- Formal Admin Footer -->
    <footer v-if="currentUser?.role !== 'admin'" class="app-footer">
      <div class="container footer-content">
        <div class="footer-left">
          <span class="footer-brand">PTC1 Admin Console</span>
          <span class="footer-divider">•</span>
          <span class="footer-copy">Hệ thống Quản trị & Điều hành Dữ liệu Ẩm thực Không gian</span>
        </div>
        <div class="footer-right">
          <span class="footer-meta">FastAPI & PostgreSQL PostGIS</span>
          <span class="footer-divider">•</span>
          <span class="footer-meta">Vue 3.5 Quản Trị</span>
        </div>
      </div>
    </footer>
  </div>
</template>

<style scoped>
.app-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #fafafa;
}

.main-body {
  flex: 1;
}

.app-footer {
  border-top: 1px solid var(--c-border);
  background-color: #ffffff;
  padding: 16px 0;
  margin-top: auto;
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 24px;
}

.footer-left,
.footer-right {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.82rem;
  color: var(--c-text-muted);
}

.footer-brand {
  font-weight: 700;
  color: var(--c-text);
}

.footer-divider {
  color: #d4d4d8;
}

@media (max-width: 640px) {
  .footer-content {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
