<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse } from './types';
import Navbar from './components/Navbar.vue';
import AdminDashboard from './components/AdminDashboard.vue';
import AuthModal from './components/AuthModal.vue';

const activeTab = ref<string>('restaurants');
const currentUser = ref<RoleLoginResponse | null>(null);
const showAuthModal = ref(false);

const STORAGE_KEY = 'ptc1_admin_session';

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

function handleTabChange(tab: string) {
  activeTab.value = tab;
}

function handleLoginSuccess(user: RoleLoginResponse) {
  currentUser.value = user;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
  showAuthModal.value = false;
}

function handleLogout() {
  currentUser.value = null;
  localStorage.removeItem(STORAGE_KEY);
}

function openAdminLogin() {
  showAuthModal.value = true;
}

onMounted(() => {
  restoreSession();
});
</script>

<template>
  <div class="app-layout">
    <!-- Header Navbar -->
    <Navbar
      :active-tab="activeTab"
      :current-user="currentUser"
      @change-tab="handleTabChange"
      @open-auth="openAdminLogin"
      @logout="handleLogout"
    />

    <!-- Main Content Area -->
    <main class="container main-content">
      <!-- Màn hình Quản Trị Hệ Thống (Admin Portal) -->
      <AdminDashboard
        v-if="currentUser?.role === 'admin'"
        :admin="currentUser"
      />

      <!-- Màn hình chưa đăng nhập Admin -->
      <div v-else class="admin-welcome-card">
        <div class="welcome-badge">ADMINISTRATION</div>
        <div class="welcome-header">
          <h2>Cổng Quản Trị Hệ Thống (Admin Portal)</h2>
          <p>
            Trang web này dành riêng cho Quản trị viên để giám sát cơ sở dữ liệu ẩm thực, quản lý các quán ăn và kiểm soát toàn bộ tài nguyên nền tảng.
          </p>
          <p class="seller-notice">
            * Lưu ý: Chủ quán (Seller) và Khách hàng sử dụng ứng dụng di động Flutter.
          </p>
        </div>

        <div class="welcome-actions">
          <button type="button" class="btn btn-primary" @click="openAdminLogin">
            Đăng nhập Quản Trị Viên
          </button>
        </div>
      </div>
    </main>

    <!-- Formal Simple Footer -->
    <footer class="app-footer">
      <div class="container footer-content">
        <div class="footer-left">
          <span class="footer-brand">PTC1 Admin Console</span>
          <span class="footer-divider">•</span>
          <span class="footer-copy">Hệ thống quản trị cơ sở dữ liệu ẩm thực</span>
        </div>
        <div class="footer-right">
          <span class="footer-meta">FastAPI & PostgreSQL</span>
          <span class="footer-divider">•</span>
          <span class="footer-meta">Vue 3.5</span>
        </div>
      </div>
    </footer>

    <!-- Auth Modal for Admin -->
    <AuthModal
      v-if="showAuthModal"
      @close="showAuthModal = false"
      @login-success="handleLoginSuccess"
    />
  </div>
</template>

<style scoped>
.app-layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.main-content {
  flex: 1;
  padding-top: 36px;
  padding-bottom: 36px;
}

.admin-welcome-card {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 56px 36px;
  text-align: center;
  max-width: 600px;
  margin: 60px auto;
}

.welcome-badge {
  display: inline-block;
  background-color: #f4f4f5;
  border: 1px solid #e4e4e7;
  color: #18181b;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  padding: 4px 10px;
  border-radius: 4px;
  margin-bottom: 16px;
}

.welcome-header h2 {
  font-size: 1.4rem;
  margin-bottom: 10px;
  font-weight: 700;
}

.welcome-header p {
  color: var(--c-text-muted);
  font-size: 0.95rem;
  line-height: 1.6;
}

.seller-notice {
  margin-top: 12px;
  font-size: 0.82rem !important;
  color: #71717a !important;
}

.welcome-actions {
  margin-top: 28px;
  display: flex;
  gap: 12px;
  justify-content: center;
}

/* Formal Simple Footer */
.app-footer {
  border-top: 1px solid var(--c-border);
  background-color: var(--c-surface);
  padding: 16px 0;
  margin-top: auto;
}

.footer-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding-top: 0;
  padding-bottom: 0;
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
  font-weight: 600;
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
