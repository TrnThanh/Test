<script setup lang="ts">
import type { RoleLoginResponse } from '../types';

defineProps<{
  activeTab: string; // 'restaurants' | 'stats'
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
        <div class="brand-icon">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect width="18" height="18" x="3" y="3" rx="2"/>
            <path d="M3 9h18"/>
            <path d="M9 21V9"/>
          </svg>
        </div>
        <div class="brand-info">
          <div class="brand-title-wrap">
            <span class="brand-title">PTC1 Console</span>
            <span class="brand-badge">ADMIN</span>
          </div>
          <span class="brand-sub">Hệ Thống Quản Trị Trung Tâm</span>
        </div>
      </div>

      <!-- Center Status / System Info -->
      <div class="nav-center">
        <span class="system-status-indicator">
          <span class="status-pulse"></span>
          <span>Hệ thống trực tuyến</span>
        </span>
      </div>

      <!-- Auth Area -->
      <div class="nav-auth">
        <template v-if="currentUser">
          <div class="user-pill">
            <span class="user-avatar">{{ ((currentUser.full_name || currentUser.email || 'A') as string).charAt(0).toUpperCase() }}</span>
            <div class="user-details">
              <span class="user-name">
                {{ currentUser.full_name || currentUser.email }}
              </span>
              <span class="user-role-badge">Quản Trị Viên</span>
            </div>
          </div>
          <button type="button" class="btn btn-outline btn-sm" @click="emit('logout')">
            Đăng xuất
          </button>
        </template>
        <template v-else>
          <button type="button" class="btn btn-primary btn-sm" @click="emit('openAuth')">
            Đăng nhập Admin
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

.brand-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background-color: #18181b;
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
}

.brand-info {
  display: flex;
  flex-direction: column;
}

.brand-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.brand-title {
  font-size: 1.12rem;
  font-weight: 700;
  color: var(--c-text);
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.brand-badge {
  background-color: #27272a;
  color: #fafafa;
  font-size: 0.65rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  padding: 2px 6px;
  border-radius: 4px;
}

.brand-sub {
  font-size: 0.75rem;
  color: var(--c-text-muted);
}

.nav-center {
  display: flex;
  align-items: center;
}

.system-status-indicator {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 4px 12px;
  border-radius: 9999px;
  background-color: #f4f4f5;
  border: 1px solid #e4e4e7;
  font-size: 0.78rem;
  font-weight: 500;
  color: #52525b;
}

.status-pulse {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background-color: #10b981;
  box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
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
  max-width: 160px;
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
    padding: 10px 16px;
  }
  .nav-center {
    display: none;
  }
}
</style>
