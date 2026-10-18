<script setup lang="ts">
import { ref, onMounted } from 'vue';
import type { RoleLoginResponse } from './types';
import Navbar from './components/Navbar.vue';
import RestaurantList from './components/RestaurantList.vue';
import NearbySearch from './components/NearbySearch.vue';
import GeocodingSearch from './components/GeocodingSearch.vue';
import SellerDashboard from './components/SellerDashboard.vue';
import AuthModal from './components/AuthModal.vue';

type Tab = 'explore' | 'nearby' | 'geocoding' | 'seller';

const activeTab = ref<Tab>('explore');
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

function handleLoginSuccess(user: RoleLoginResponse) {
  currentUser.value = user;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
  if (user.role === 'seller') {
    activeTab.value = 'seller';
  }
}

function handleLogout() {
  currentUser.value = null;
  localStorage.removeItem(STORAGE_KEY);
  if (activeTab.value === 'seller') {
    activeTab.value = 'explore';
  }
}

function handleChangeTab(tab: Tab) {
  if (tab === 'seller' && currentUser.value?.role !== 'seller') {
    showAuthModal.value = true;
    return;
  }
  activeTab.value = tab;
}

onMounted(() => {
  restoreSession();
});
</script>

<template>
  <div class="app-layout">
    <Navbar
      :active-tab="activeTab"
      :current-user="currentUser"
      @change-tab="handleChangeTab"
      @open-auth="showAuthModal = true"
      @logout="handleLogout"
    />

    <main class="container main-content">
      <RestaurantList v-if="activeTab === 'explore'" />
      <NearbySearch v-else-if="activeTab === 'nearby'" />
      <GeocodingSearch v-else-if="activeTab === 'geocoding'" />
      <SellerDashboard
        v-else-if="activeTab === 'seller' && currentUser?.role === 'seller'"
        :seller="currentUser"
      />
      <div v-else class="state-box">
        <div class="icon">🔒</div>
        <h3>Yêu cầu quyền Chủ quán (Seller)</h3>
        <p>Vui lòng đăng nhập với tài khoản Chủ quán để truy cập trang quản lý này.</p>
        <button type="button" class="btn btn-primary" style="margin-top: 14px;" @click="showAuthModal = true">
          Đăng nhập ngay
        </button>
      </div>
    </main>

    <footer class="app-footer">
      <div class="container footer-inner">
        <p>© 2026 PTC1 Spatial Food Platform • FastAPI + PostGIS + Vue 3</p>
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
