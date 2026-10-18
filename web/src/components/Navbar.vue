<script setup lang="ts">
import type { RoleLoginResponse } from '../types';

defineProps<{
  currentPath: string; // '/seller' or '/admin' or '/'
  currentUser: RoleLoginResponse | null;
}>();

const emit = defineEmits<{
  (e: 'navigate', path: string): void;
  (e: 'openAuth'): void;
  (e: 'logout'): void;
}>();
</script>

<template>
  <header class="navbar">
    <div class="nav-container">
      <div class="brand" @click="emit('navigate', '/seller')">
        <span class="brand-name">PTC1 Portal</span>
        <span class="portal-tag">Quản Lý</span>
      </div>

      <nav class="nav-links">
        <button
          type="button"
          class="nav-tab"
          :class="{ active: currentPath.startsWith('/seller') }"
          @click="emit('navigate', '/seller')"
        >
          Cổng Chủ Quán
        </button>
        <button
          type="button"
          class="nav-tab admin-tab"
          :class="{ active: currentPath.startsWith('/admin') }"
          @click="emit('navigate', '/admin')"
        >
          Cổng Quản Trị Hệ Thống
        </button>
      </nav>

      <div class="nav-auth">
        <template v-if="currentUser">
          <div class="user-pill">
            <span class="user-name">{{ currentUser.shop_name || currentUser.full_name || currentUser.email }}</span>
            <span class="badge" :class="currentUser.role === 'admin' ? 'badge-primary' : 'badge-success'">
              {{ currentUser.role === 'admin' ? 'Quản Trị' : 'Chủ Quán' }}
            </span>
          </div>
          <button type="button" class="btn btn-outline btn-sm" @click="emit('logout')">
            Đăng xuất
          </button>
        </template>
        <template v-else>
          <button type="button" class="btn btn-primary btn-sm" @click="emit('openAuth')">
            Đăng nhập Quản Lý
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
  font-size: 1.2rem;
  color: #000000;
  user-select: none;
}

.portal-tag {
  background: #f5f5f5;
  border: 1px solid var(--c-border);
  font-size: 0.72rem;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: var(--radius-sm);
  color: var(--c-text-muted);
  text-transform: uppercase;
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 8px;
}

.nav-tab {
  background: transparent;
  border: 1px solid transparent;
  font-size: 0.92rem;
  font-weight: 600;
  color: var(--c-text-muted);
  padding: 6px 14px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition);
}

.nav-tab:hover {
  color: #000000;
  border-color: var(--c-border);
}

.nav-tab.active {
  color: #ffffff;
  background: #000000;
  border-color: #000000;
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
  background: #ffffff;
  padding: 4px 10px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--c-border);
}

.user-name {
  font-size: 0.88rem;
  font-weight: 600;
  max-width: 140px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

@media (max-width: 768px) {
  .nav-container {
    flex-wrap: wrap;
  }
  .nav-links {
    order: 3;
    width: 100%;
    justify-content: flex-start;
    overflow-x: auto;
    padding-top: 8px;
  }
}
</style>
