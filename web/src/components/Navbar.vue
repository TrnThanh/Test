<script setup lang="ts">
import type { RoleLoginResponse } from '../types';

defineProps<{
  activeTab: string; // 'seller' | 'admin'
  currentUser: RoleLoginResponse | null;
}>();

const emit = defineEmits<{
  (e: 'changeTab', tab: string): void;
  (e: 'openAuth'): void;
  (e: 'logout'): void;
}>();
</script>

<template>
  <header class="navbar">
    <div class="nav-container">
      <!-- Brand Logo / Portal Label -->
      <div class="brand">
        <span class="brand-badge">PORTAL</span>
        <div class="brand-info">
          <span class="brand-title">PTC1 Quản Trị</span>
          <span class="brand-sub">Hệ thống quản lý dữ liệu ẩm thực</span>
        </div>
      </div>

      <!-- Main Navigation Tabs: Quán Ăn / Món Ăn & Quản Trị Hệ Thống -->
      <nav class="nav-links">
        <button
          type="button"
          class="nav-tab"
          :class="{ active: activeTab === 'seller' }"
          @click="emit('changeTab', 'seller')"
        >
          <span class="tab-dot"></span>
          <span>Quán Ăn & Món Ăn</span>
        </button>
        <button
          type="button"
          class="nav-tab"
          :class="{ active: activeTab === 'admin' }"
          @click="emit('changeTab', 'admin')"
        >
          <span class="tab-dot"></span>
          <span>Quản Trị Hệ Thống</span>
        </button>
      </nav>

      <!-- Auth Area -->
      <div class="nav-auth">
        <template v-if="currentUser">
          <div class="user-pill">
            <span class="user-avatar">{{ (currentUser.shop_name || currentUser.email).charAt(0).toUpperCase() }}</span>
            <div class="user-details">
              <span class="user-name">
                {{ currentUser.shop_name || currentUser.full_name || currentUser.email }}
              </span>
              <span class="user-role-badge">
                {{ currentUser.role === 'admin' ? 'Admin' : 'Chủ Quán' }}
              </span>
            </div>
          </div>
          <button type="button" class="btn btn-outline btn-sm" @click="emit('logout')">
            Đăng xuất
          </button>
        </template>
        <template v-else>
          <button type="button" class="btn btn-primary btn-sm" @click="emit('openAuth')">
            Đăng nhập Quản Trị
          </button>
        </template>
      </div>
    </div>
  </header>
</template>

<style scoped>
.navbar {
  background: var(--c-surface);
  border-bottom: 1px solid var(--c-border);
  position: sticky;
  top: 0;
  z-index: 100;
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 12px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  user-select: none;
}

.brand-badge {
  background-color: #18181b;
  color: #ffffff;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  padding: 3px 7px;
  border-radius: 4px;
}

.brand-info {
  display: flex;
  flex-direction: column;
}

.brand-title {
  font-size: 1.12rem;
  font-weight: 700;
  color: var(--c-text);
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.brand-sub {
  font-size: 0.75rem;
  color: var(--c-text-muted);
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 4px;
  background-color: #f4f4f5;
  padding: 4px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
}

.nav-tab {
  background: transparent;
  border: none;
  font-size: 0.88rem;
  font-weight: 500;
  color: var(--c-text-muted);
  padding: 6px 14px;
  border-radius: 6px;
  cursor: pointer;
  transition: var(--transition);
  display: flex;
  align-items: center;
  gap: 6px;
}

.tab-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: transparent;
}

.nav-tab:hover {
  color: var(--c-text);
}

.nav-tab.active {
  color: #09090b;
  background-color: #ffffff;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.nav-tab.active .tab-dot {
  background-color: #18181b;
}

.nav-auth {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #f4f4f5;
  padding: 4px 10px 4px 5px;
  border-radius: var(--radius-md);
  border: 1px solid var(--c-border);
}

.user-avatar {
  width: 28px;
  height: 28px;
  border-radius: 4px;
  background: #18181b;
  color: #ffffff;
  font-weight: 700;
  font-size: 0.8rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-details {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-size: 0.82rem;
  font-weight: 600;
  max-width: 140px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: var(--c-text);
  line-height: 1.2;
}

.user-role-badge {
  font-size: 0.7rem;
  color: var(--c-text-muted);
}

@media (max-width: 768px) {
  .nav-container {
    flex-wrap: wrap;
    padding: 10px 16px;
  }
  .nav-links {
    order: 3;
    width: 100%;
    justify-content: center;
  }
}
</style>
