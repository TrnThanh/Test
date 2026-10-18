<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import type { RoleLoginResponse } from './types';
import Navbar from './components/Navbar.vue';
import SellerDashboard from './components/SellerDashboard.vue';
import AdminDashboard from './components/AdminDashboard.vue';
import AuthModal from './components/AuthModal.vue';

const currentPath = ref<string>('/seller');
const currentUser = ref<RoleLoginResponse | null>(null);
const showAuthModal = ref(false);

const STORAGE_KEY = 'ptc1_auth_session';

function restoreSession() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    try {
      currentUser.value = JSON.parse(saved);
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
  }
}

function syncPathFromUrl() {
  const path = window.location.pathname.toLowerCase();
  if (path.startsWith('/admin')) {
    currentPath.value = '/admin';
  } else {
    currentPath.value = '/seller';
  }
}

function navigateTo(path: string) {
  if (path !== currentPath.value) {
    currentPath.value = path;
    window.history.pushState(null, '', path);
  }
}

function handleLoginSuccess(user: RoleLoginResponse) {
  currentUser.value = user;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(user));

  // Auto redirect to matching portal based on role
  if (user.role === 'admin' && !currentPath.value.startsWith('/admin')) {
    navigateTo('/admin');
  } else if (user.role === 'seller' && !currentPath.value.startsWith('/seller')) {
    navigateTo('/seller');
  }
}

function handleLogout() {
  currentUser.value = null;
  localStorage.removeItem(STORAGE_KEY);
}

const authInitialRole = computed<'seller' | 'admin'>(() => {
  return currentPath.value.startsWith('/admin') ? 'admin' : 'seller';
});

onMounted(() => {
  restoreSession();
  syncPathFromUrl();

  window.addEventListener('popstate', () => {
    syncPathFromUrl();
  });
});
</script>

<template>
  <div class="app-layout">
    <Navbar
      :current-path="currentPath"
      :current-user="currentUser"
      @navigate="navigateTo"
      @open-auth="showAuthModal = true"
      @logout="handleLogout"
    />

    <main class="container main-content">
      <!-- Admin Portal View -->
      <template v-if="currentPath.startsWith('/admin')">
        <AdminDashboard
          v-if="currentUser?.role === 'admin'"
          :admin="currentUser"
        />
        <div v-else class="state-box">
          <h3>Yêu cầu quyền Quản Trị Viên (Admin)</h3>
          <p>Trang này dành riêng cho Quản trị viên hệ thống để giám sát toàn bộ nhà hàng, số liệu thống kê và quản lý người dùng.</p>
          <div style="margin-top: 16px; display: flex; gap: 10px; justify-content: center;">
            <button type="button" class="btn btn-primary" @click="showAuthModal = true">
              Đăng nhập Quản Trị
            </button>
            <button type="button" class="btn btn-outline" @click="navigateTo('/seller')">
              Về Cổng Chủ Quán
            </button>
          </div>
        </div>
      </template>

      <!-- Seller Portal View -->
      <template v-else>
        <SellerDashboard
          v-if="currentUser?.role === 'seller'"
          :seller="currentUser"
        />
        <div v-else class="state-box">
          <h3>Yêu cầu quyền Chủ Quán (Seller)</h3>
          <p>Trang này dành riêng cho Chủ quán để quản lý thông tin nhà hàng, giờ mở/đóng cửa, nhóm món (Category) và danh mục món ăn (Dishes).</p>
          <div style="margin-top: 16px; display: flex; gap: 10px; justify-content: center;">
            <button type="button" class="btn btn-primary" @click="showAuthModal = true">
              Đăng nhập / Đăng ký Chủ Quán
            </button>
            <button type="button" class="btn btn-outline" @click="navigateTo('/admin')">
              Đến Cổng Quản Trị
            </button>
          </div>
        </div>
      </template>
    </main>

    <footer class="app-footer">
      <div class="container footer-inner">
        <p>© 2026 PTC1 Spatial Food Platform • Cổng Quản Lý (Admin & Seller Portal)</p>
        <div class="tech-tags">
          <span class="badge badge-primary">Vue 3.5</span>
          <span class="badge badge-info">PostGIS 3.6</span>
          <span class="badge badge-success">FastAPI</span>
        </div>
      </div>
    </footer>

    <!-- Auth Modal -->
    <AuthModal
      v-if="showAuthModal"
      :initial-role="authInitialRole"
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
  padding-top: 24px;
}

.app-footer {
  background: var(--c-surface);
  border-top: 1px solid var(--c-border);
  padding: 18px 0;
  margin-top: 40px;
}

.footer-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.tech-tags {
  display: flex;
  gap: 8px;
}
</style>
