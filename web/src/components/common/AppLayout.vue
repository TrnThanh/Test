<script setup lang="ts">

import type { RoleLoginResponse } from '../../types';
import {
  Home,
  Store,
  Users,
  CloudSun,
  LogOut,
} from 'lucide-vue-next';
import ToastNotification from './ToastNotification.vue';

export interface NavItem {
  key: string;
  label: string;
  icon: any;
  count?: number | string;
}

withDefaults(
  defineProps<{
    currentTab: string;
    admin?: RoleLoginResponse | null;
    restaurantCount?: number;
    userCount?: number;
    weatherCount?: number;
  }>(),
  {
    admin: null,
    restaurantCount: undefined,
    userCount: undefined,
    weatherCount: undefined,
  }
);

const emit = defineEmits<{
  (e: 'update:currentTab', tab: string): void;
  (e: 'logout'): void;
}>();

</script>

<template>
  <div class="app">
    <!-- Sidebar / Topbar (<860px) -->
    <aside>
      <div class="brand">
        <div class="logo">P</div>
        <div class="brand-text">
          <b>PTC1</b>
          <small>Quản trị hệ thống</small>
        </div>
      </div>

      <nav>
        <button
          type="button"
          class="nav-btn"
          :class="{ on: currentTab === 'dashboard' }"
          @click="emit('update:currentTab', 'dashboard')"
        >
          <Home class="nav-icon" />
          <span>Tổng quan</span>
        </button>

        <button
          type="button"
          class="nav-btn"
          :class="{ on: currentTab === 'restaurants' }"
          @click="emit('update:currentTab', 'restaurants')"
        >
          <Store class="nav-icon" />
          <span>Cơ sở quán ăn</span>
          <em v-if="restaurantCount != null">{{ restaurantCount }}</em>
        </button>

        <button
          type="button"
          class="nav-btn"
          :class="{ on: currentTab === 'accounts' }"
          @click="emit('update:currentTab', 'accounts')"
        >
          <Users class="nav-icon" />
          <span>Người dùng</span>
          <em v-if="userCount != null">{{ userCount }}</em>
        </button>

        <button
          type="button"
          class="nav-btn"
          :class="{ on: currentTab === 'weather_rules' }"
          @click="emit('update:currentTab', 'weather_rules')"
        >
          <CloudSun class="nav-icon" />
          <span>Luật thời tiết</span>
          <em v-if="weatherCount != null">{{ weatherCount }}</em>
        </button>
      </nav>

      <!-- Admin Session Info & Controls -->
      <div class="me">
        <div class="av">
          {{ (admin?.full_name || admin?.email || 'A').charAt(0).toUpperCase() }}
        </div>
        <div class="me-info">
          <span class="me-name" :title="admin?.full_name || admin?.email || 'Admin'">
            {{ admin?.full_name || admin?.email || 'Admin' }}
          </span>
          <span class="me-role">Quản trị viên</span>
        </div>

        <button
          type="button"
          class="tb"
          aria-label="Đăng xuất"
          title="Đăng xuất"
          @click="emit('logout')"
        >
          <LogOut class="tb-icon" />
        </button>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main>
      <slot />
    </main>

    <!-- Global Toast Container -->
    <ToastNotification />
  </div>
</template>

<style scoped>
.app {
  display: grid;
  grid-template-columns: 232px 1fr;
  min-height: 100vh;
  background: var(--bg);
  color: var(--ink);
}

aside {
  background: var(--card);
  border-right: 1px solid var(--line);
  padding: 18px 12px;
  position: sticky;
  top: 0;
  height: 100vh;
  display: flex;
  flex-direction: column;
  gap: 4px;
  z-index: 10;
}

.brand {
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 4px 8px 18px;
}

.logo {
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: var(--pri);
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 700;
  font-size: 16px;
  flex: none;
}

.brand-text b {
  display: block;
  line-height: 1.2;
  color: var(--ink);
  font-size: 15px;
}

.brand-text small {
  color: var(--mut);
  font-size: 12px;
}

nav {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.nav-btn {
  display: flex;
  gap: 10px;
  align-items: center;
  padding: 9px 10px;
  border-radius: 8px;
  color: var(--mut);
  text-decoration: none;
  font-weight: 500;
  border: 1px solid transparent;
  background: none;
  width: 100%;
  text-align: left;
  font-size: 13.5px;
  transition: all 0.15s ease;
}

.nav-btn:hover {
  background: var(--bg);
  color: var(--ink);
}

.nav-btn.on {
  background: var(--pri-s);
  color: var(--pri);
  font-weight: 600;
}

.nav-btn em {
  margin-left: auto;
  font-style: normal;
  font-size: 11.5px;
  background: var(--bg);
  color: var(--mut);
  padding: 1px 7px;
  border-radius: 99px;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
}

.nav-btn.on em {
  background: var(--card);
  color: var(--pri);
}

.nav-icon {
  width: 17px;
  height: 17px;
  flex: none;
}

.me {
  margin-top: auto;
  display: flex;
  gap: 8px;
  align-items: center;
  padding: 12px 6px 4px;
  border-top: 1px solid var(--line);
}

.av {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: var(--pri-s);
  color: var(--pri);
  display: grid;
  place-items: center;
  font-weight: 600;
  font-size: 13px;
  flex: none;
}

.me-info {
  min-width: 0;
  flex: 1;
}

.me-name {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 600;
  color: var(--ink);
  font-size: 12.5px;
}

.me-role {
  display: block;
  color: var(--mut);
  font-size: 11.5px;
}

.tb {
  border: 1px solid var(--line);
  background: none;
  border-radius: 8px;
  padding: 6px;
  color: var(--mut);
  display: grid;
  place-items: center;
  flex: none;
  transition: all 0.15s ease;
}

.tb:hover {
  background: var(--bg);
  color: var(--ink);
  border-color: var(--pri);
}

.tb-icon {
  width: 15px;
  height: 15px;
}

main {
  padding: 28px 32px 48px;
  min-width: 0;
  max-width: 1180px;
  width: 100%;
}

@media (max-width: 860px) {
  .app {
    grid-template-columns: 1fr;
  }
  aside {
    position: static;
    height: auto;
    flex-direction: row;
    overflow-x: auto;
    padding: 10px 14px;
    align-items: center;
    border-right: none;
    border-bottom: 1px solid var(--line);
  }
  .brand {
    padding: 0 12px 0 0;
  }
  .brand-text small,
  .me,
  .nav-btn em {
    display: none;
  }
  nav {
    display: flex;
    flex-direction: row;
    gap: 4px;
    flex: 1;
    overflow-x: auto;
  }
  .nav-btn {
    white-space: nowrap;
    width: auto;
    padding: 7px 12px;
  }
  main {
    padding: 20px 16px 40px;
  }
}
</style>
