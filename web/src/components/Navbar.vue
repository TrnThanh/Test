<script setup lang="ts">
import type { RoleLoginResponse } from '../types';

defineProps<{
  activeTab: 'explore' | 'nearby' | 'geocoding' | 'seller';
  currentUser: RoleLoginResponse | null;
}>();

const emit = defineEmits<{
  (e: 'changeTab', tab: 'explore' | 'nearby' | 'geocoding' | 'seller'): void;
  (e: 'openAuth'): void;
  (e: 'logout'): void;
}>();
</script>

<template>
  <header class="navbar">
    <div class="nav-container">
      <div class="brand" @click="emit('changeTab', 'explore')">
        <span class="brand-icon">🍜</span>
        <span class="brand-name">PTC1 Food</span>
      </div>

      <nav class="nav-links">
        <button
          type="button"
          class="nav-tab"
          :class="{ active: activeTab === 'explore' }"
          @click="emit('changeTab', 'explore')"
        >
          🔍 Khám phá
        </button>
        <button
          type="button"
          class="nav-tab"
          :class="{ active: activeTab === 'nearby' }"
          @click="emit('changeTab', 'nearby')"
        >
          📍 Quán gần đây
        </button>
        <button
          type="button"
          class="nav-tab"
          :class="{ active: activeTab === 'geocoding' }"
          @click="emit('changeTab', 'geocoding')"
        >
          🗺️ Bản đồ OSM
        </button>
        <button
          v-if="currentUser?.role === 'seller'"
          type="button"
          class="nav-tab seller-tab"
          :class="{ active: activeTab === 'seller' }"
          @click="emit('changeTab', 'seller')"
        >
          🏪 Quán của tôi
        </button>
      </nav>

      <div class="nav-auth">
        <template v-if="currentUser">
          <div class="user-pill">
            <span class="user-name">{{ currentUser.full_name || currentUser.email }}</span>
            <span class="badge" :class="currentUser.role === 'seller' ? 'badge-primary' : 'badge-info'">
              {{ currentUser.role === 'seller' ? 'Chủ quán' : 'Khách' }}
            </span>
          </div>
          <button type="button" class="btn btn-outline btn-sm" @click="emit('logout')">
            Đăng xuất
          </button>
        </template>
        <template v-else>
          <button type="button" class="btn btn-primary btn-sm" @click="emit('openAuth')">
            Đăng nhập / Đăng ký
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
  box-shadow: var(--shadow-sm);
}

.nav-container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 12px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-weight: 800;
  font-size: 1.25rem;
  color: var(--c-primary);
  user-select: none;
}

.brand-icon {
  font-size: 1.5rem;
}

.nav-links {
  display: flex;
  gap: 6px;
}

.nav-tab {
  background: none;
  border: none;
  padding: 8px 14px;
  border-radius: var(--radius-sm);
  font-size: 0.92rem;
  font-weight: 600;
  color: var(--c-text-muted);
  cursor: pointer;
  transition: var(--transition);
}

.nav-tab:hover {
  background: var(--c-bg);
  color: var(--c-text);
}

.nav-tab.active {
  background: var(--c-primary-light);
  color: var(--c-primary);
}

.nav-auth {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.88rem;
  font-weight: 600;
}

.user-name {
  max-width: 140px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

@media (max-width: 768px) {
  .nav-container {
    flex-wrap: wrap;
    gap: 10px;
  }
  .nav-links {
    order: 3;
    width: 100%;
    overflow-x: auto;
    padding-bottom: 4px;
  }
}
</style>
