<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue';
import { MoreVertical } from 'lucide-vue-next';

defineProps<{
  ariaLabel?: string;
}>();

const emit = defineEmits<{
  (e: 'open'): void;
  (e: 'close'): void;
}>();

// Global coordinator to ensure only one menu is open at a time across the entire app
const menuId = 'menu_' + Math.random().toString(36).slice(2, 9);
const activeMenuId = (window as any).__ptc1_active_menu_id || ref<string | null>(null);
(window as any).__ptc1_active_menu_id = activeMenuId;

const isOpen = computed(() => activeMenuId.value === menuId);

const buttonRef = ref<HTMLButtonElement | null>(null);
const dropdownRef = ref<HTMLElement | null>(null);

const menuStyle = ref<{
  top?: string;
  bottom?: string;
  right?: string;
  left?: string;
}>({});

function updatePosition() {
  if (!buttonRef.value) return;
  const rect = buttonRef.value.getBoundingClientRect();
  const menuEstHeight = 160;
  const menuEstWidth = 175;

  const spaceBelow = window.innerHeight - rect.bottom;
  const styleObj: typeof menuStyle.value = {};

  // Check if dropdown should flip upwards
  if (spaceBelow < menuEstHeight && rect.top > menuEstHeight) {
    styleObj.bottom = `${window.innerHeight - rect.top + 4}px`;
  } else {
    styleObj.top = `${rect.bottom + 4}px`;
  }

  // Right-align with the button, but keep inside viewport
  const rightOffset = window.innerWidth - rect.right;
  if (rightOffset < 10) {
    styleObj.right = '10px';
  } else if (rect.right - menuEstWidth < 10) {
    styleObj.left = '10px';
  } else {
    styleObj.right = `${rightOffset}px`;
  }

  menuStyle.value = styleObj;
}

function toggle(e: MouseEvent) {
  e.stopPropagation();
  if (isOpen.value) {
    close();
  } else {
    activeMenuId.value = menuId;
    updatePosition();
    emit('open');
    nextTick(() => {
      updatePosition();
    });
  }
}

function close() {
  if (activeMenuId.value === menuId) {
    activeMenuId.value = null;
    emit('close');
  }
}

function handleClickOutside(e: MouseEvent) {
  if (!isOpen.value) return;
  const target = e.target as Node;
  if (
    buttonRef.value &&
    !buttonRef.value.contains(target) &&
    dropdownRef.value &&
    !dropdownRef.value.contains(target)
  ) {
    close();
  }
}

function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Escape' && isOpen.value) {
    close();
  }
}

function handleScrollOrResize() {
  if (isOpen.value) {
    close();
  }
}

onMounted(() => {
  window.addEventListener('click', handleClickOutside, true);
  window.addEventListener('keydown', handleKeyDown);
  window.addEventListener('scroll', handleScrollOrResize, true);
  window.addEventListener('resize', handleScrollOrResize);
});

onUnmounted(() => {
  if (activeMenuId.value === menuId) {
    activeMenuId.value = null;
  }
  window.removeEventListener('click', handleClickOutside, true);
  window.removeEventListener('keydown', handleKeyDown);
  window.removeEventListener('scroll', handleScrollOrResize, true);
  window.removeEventListener('resize', handleScrollOrResize);
});

defineExpose({ close });
</script>

<template>
  <div class="row-action-menu">
    <button
      ref="buttonRef"
      type="button"
      class="kb-btn"
      :class="{ active: isOpen }"
      :aria-label="ariaLabel || 'Thêm thao tác'"
      :aria-expanded="isOpen"
      @click="toggle"
    >
      <MoreVertical class="kb-icon" />
    </button>

    <Teleport to="body">
      <Transition name="menu-pop">
        <div
          v-if="isOpen"
          ref="dropdownRef"
          class="menu-dropdown-portal"
          :style="menuStyle"
          role="menu"
          @click="close"
        >
          <slot />
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.row-action-menu {
  position: relative;
  display: inline-block;
}

.kb-btn {
  border: 1px solid var(--line);
  background: var(--card);
  border-radius: 8px;
  padding: 6px;
  color: var(--mut);
  display: grid;
  place-items: center;
  transition: all 0.15s ease;
}

.kb-btn:hover,
.kb-btn.active {
  border-color: var(--pri);
  color: var(--ink);
  background: var(--bg);
}

.kb-icon {
  width: 15px;
  height: 15px;
}
</style>

<style>
/* Portal dropdown styles attached to body to prevent overflow clipping */
.menu-dropdown-portal {
  position: fixed;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 10px;
  box-shadow: 0 10px 24px rgba(20, 32, 30, 0.16);
  min-width: 175px;
  z-index: 9999;
  padding: 5px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.menu-dropdown-portal button,
.menu-dropdown-portal a {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  border-radius: 6px;
  border: none;
  background: none;
  color: var(--ink);
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
  cursor: pointer;
  text-align: left;
  transition: all 0.12s ease;
}

.menu-dropdown-portal button:hover,
.menu-dropdown-portal a:hover {
  background: var(--bg);
  color: var(--pri);
}

.menu-dropdown-portal hr {
  border: 0;
  border-top: 1px solid var(--line);
  margin: 4px 0;
}

.menu-dropdown-portal button.danger-action,
.menu-dropdown-portal button.d {
  color: var(--bad);
}

.menu-dropdown-portal button.danger-action:hover,
.menu-dropdown-portal button.d:hover {
  background: var(--bad-s);
  color: var(--bad);
}

.menu-dropdown-portal .menu-item-icon {
  width: 15px;
  height: 15px;
  flex: none;
}

/* Transitions */
.menu-pop-enter-active,
.menu-pop-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.menu-pop-enter-from,
.menu-pop-leave-to {
  opacity: 0;
  transform: translateY(-4px) scale(0.96);
}
</style>
