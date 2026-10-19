<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse } from './types';
import Navbar from './components/Navbar.vue';
import SellerDashboard from './components/SellerDashboard.vue';
import AdminDashboard from './components/AdminDashboard.vue';
import AuthModal from './components/AuthModal.vue';

// Default into Seller / Restaurant management
const activeTab = ref<string>('seller');
const currentUser = ref<RoleLoginResponse | null>(null);
const showAuthModal = ref(false);

const STORAGE_KEY = 'ptc1_auth_session';

function restoreSession() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    try {
      currentUser.value = JSON.parse(saved);
      if (currentUser.value?.role === 'admin') {
        activeTab.value = 'admin';
      } else {
        activeTab.value = 'seller';
      }
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
  }
}

function handleTabChange(tab: string) {
  if (tab === 'seller' && currentUser.value && currentUser.value.role !== 'seller') {
    showAuthModal.value = true;
    activeTab.value = tab;
    return;
  }
  if (tab === 'admin' && currentUser.value?.role !== 'admin') {
    showAuthModal.value = true;
    activeTab.value = tab;
    return;
  }
  activeTab.value = tab;
}

function handleLoginSuccess(user: RoleLoginResponse) {
  currentUser.value = user;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
  showAuthModal.value = false;

  if (user.role === 'admin') {
    activeTab.value = 'admin';
  } else {
    activeTab.value = 'seller';
  }
}

function handleLogout() {
  currentUser.value = null;
  localStorage.removeItem(STORAGE_KEY);
  activeTab.value = 'seller';
}

function quickLoginMock(role: 'seller' | 'admin') {
  activeTab.value = role;
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
      @open-auth="showAuthModal = true"
      @logout="handleLogout"
    />

    <!-- Main Content Area -->
    <main class="container main-content">
      <!-- Cổng Quản Lý Chủ Quán (Seller) -->
      <template v-if="activeTab === 'seller'">
        <SellerDashboard
          v-if="currentUser?.role === 'seller'"
          :seller="currentUser"
        />
        <div v-else class="portal-welcome-card">
          <div class="welcome-header">
            <h3>Cổng Quản Lý Chủ Quán (Seller Portal)</h3>
            <p>Khu vực quản lý thông tin cơ sở ẩm thực, phân loại nhóm món và thực đơn món ăn.</p>
          </div>
          <div class="welcome-actions">
            <button type="button" class="btn btn-primary" @click="showAuthModal = true">
              Đăng nhập / Đăng ký Chủ Quán
            </button>
            <button type="button" class="btn btn-secondary" @click="quickLoginMock('seller')">
              Đăng nhập nhanh với Mock Seller
            </button>
          </div>
        </div>
      </template>

      <!-- Cổng Quản Trị Hệ Thống (Admin) -->
      <template v-else-if="activeTab === 'admin'">
        <AdminDashboard
          v-if="currentUser?.role === 'admin'"
          :admin="currentUser"
        />
        <div v-else class="portal-welcome-card">
          <div class="welcome-header">
            <h3>Cổng Quản Trị Hệ Thống (Admin Portal)</h3>
            <p>Giám sát dữ liệu toàn bộ cơ sở quán ăn, người dùng và thiết lập phân quyền.</p>
          </div>
          <div class="welcome-actions">
            <button type="button" class="btn btn-primary" @click="showAuthModal = true">
              Đăng nhập Quản Trị
            </button>
            <button type="button" class="btn btn-secondary" @click="quickLoginMock('admin')">
              Đăng nhập nhanh với Mock Admin
            </button>
          </div>
        </div>
      </template>
    </main>

    <!-- Formal Simple Footer -->
    <footer class="app-footer">
      <div class="container footer-content">
        <div class="footer-left">
          <span class="footer-brand">PTC1 Portal</span>
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

    <!-- Auth Modal -->
    <AuthModal
      v-if="showAuthModal"
      :initial-role="activeTab === 'admin' ? 'admin' : 'seller'"
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
  padding-top: 32px;
  padding-bottom: 32px;
}

.portal-welcome-card {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  padding: 48px 32px;
  text-align: center;
  max-width: 640px;
  margin: 40px auto;
}

.welcome-header h3 {
  font-size: 1.3rem;
  margin-bottom: 8px;
}

.welcome-header p {
  color: var(--c-text-muted);
  font-size: 0.95rem;
}

.welcome-actions {
  margin-top: 24px;
  display: flex;
  gap: 10px;
  justify-content: center;
  flex-wrap: wrap;
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
