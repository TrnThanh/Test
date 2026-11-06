<script setup lang="ts">
import { ref, computed } from 'vue';
import type { Ingredient, IngredientGroup } from '../../types';
import {
  Sparkles,
  Plus,
  X,
  Check,
  Layers,
  ChevronDown,
  ChevronUp,
} from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    modelValue: string;
    availableIngredients: Ingredient[];
    ingredientGroups?: IngredientGroup[];
    dishName?: string;
    placeholder?: string;
  }>(),
  {
    dishName: '',
    ingredientGroups: () => [],
    placeholder: 'Tìm trong danh mục hoặc gõ tên mới rồi nhấn Enter...',
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', val: string): void;
}>();

const inputSearchText = ref('');
const isInputFocused = ref(false);
const inputEl = ref<HTMLInputElement | null>(null);

// Trạng thái mở rộng bảng duyệt theo nhóm
const isGroupBrowserOpen = ref(false);
const activeGroupId = ref<number | 'all'>('all');

function normalizeText(str: string): string {
  if (!str) return '';
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'd')
    .trim();
}

// Danh sách các nguyên liệu hiện đang được chọn (dạng mảng chuỗi)
const selectedList = computed<string[]>(() => {
  if (!props.modelValue) return [];
  return props.modelValue
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
});

// Hàm cập nhật danh sách và emit chuỗi phân tách bởi dấu phẩy
function updateList(newList: string[]) {
  const seen = new Set<string>();
  const cleanList: string[] = [];
  for (const item of newList) {
    const trimmed = item.trim();
    const lower = trimmed.toLowerCase();
    if (trimmed && !seen.has(lower)) {
      seen.add(lower);
      cleanList.push(trimmed);
    }
  }
  emit('update:modelValue', cleanList.join(', '));
}

function removeIngredient(index: number) {
  const list = [...selectedList.value];
  list.splice(index, 1);
  updateList(list);
}

function addIngredient(name: string) {
  const trimmed = name.trim();
  if (!trimmed) return;
  const list = [...selectedList.value];
  if (!list.map((s) => s.toLowerCase()).includes(trimmed.toLowerCase())) {
    list.push(trimmed);
    updateList(list);
  }
  inputSearchText.value = '';
}

function toggleIngredient(name: string) {
  const trimmed = name.trim();
  const lower = trimmed.toLowerCase();
  const list = [...selectedList.value];
  const idx = list.findIndex((s) => s.toLowerCase() === lower);
  if (idx >= 0) {
    list.splice(idx, 1);
    updateList(list);
  } else {
    list.push(trimmed);
    updateList(list);
  }
}

// Xử lý khi nhấn phím trong ô tìm kiếm
function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    e.preventDefault();
    if (filteredAutocomplete.value.length > 0) {
      addIngredient(filteredAutocomplete.value[0].name);
    } else if (inputSearchText.value.trim()) {
      addIngredient(inputSearchText.value.trim());
    }
  } else if (e.key === 'Backspace' && !inputSearchText.value && selectedList.value.length > 0) {
    removeIngredient(selectedList.value.length - 1);
  }
}

// Danh sách gợi ý Autocomplete theo từ khóa đang tìm
const filteredAutocomplete = computed(() => {
  const q = normalizeText(inputSearchText.value);
  if (!q) return [];
  const selectedLower = new Set(selectedList.value.map((s) => s.toLowerCase()));
  return props.availableIngredients
    .filter((ing) => {
      const matchName = normalizeText(ing.name).includes(q);
      const matchGroup = ing.group_name ? normalizeText(ing.group_name).includes(q) : false;
      return (matchName || matchGroup) && !selectedLower.has(ing.name.toLowerCase());
    })
    .slice(0, 10);
});

// Gợi ý thông minh (Smart Suggestions) dựa trên tên món ăn hiện tại
const smartSuggestions = computed(() => {
  const dn = normalizeText(props.dishName || '');
  if (!dn) return [];

  const candidates: string[] = [];
  if (dn.includes('pho')) {
    candidates.push('Bánh phở tươi Hà Nội', 'Thịt bò bắp hoa', 'Hành lá (hành hoa)', 'Quế hồi thảo quả', 'Nước mắm cá cơm Phú Quốc');
    if (dn.includes('ga')) candidates.push('Thịt gà ta thả vườn', 'Lá chanh bánh tẻ');
    if (dn.includes('tai') || dn.includes('nam') || dn.includes('gau')) candidates.push('Thịt bò bắp hoa', 'Gầu bò giòn');
  } else if (dn.includes('bun cha')) {
    candidates.push('Bún tươi sợi nhỏ', 'Thịt heo ba chỉ', 'Nạc vai heo', 'Nước mắm cá cơm Phú Quốc', 'Rau húng quế');
  } else if (dn.includes('bun dau')) {
    candidates.push('Bún tươi sợi nhỏ', 'Đậu hũ mơ chiên vàng', 'Mắm tôm Thanh Hóa', 'Thịt heo ba chỉ', 'Rau kinh giới');
  } else if (dn.includes('bun bo')) {
    candidates.push('Bún bò Huế sợi to', 'Nạm bò vân mỡ', 'Móng giò heo', 'Sả cây tươi', 'Ớt chỉ thiên cay xé');
  } else if (dn.includes('bun ca')) {
    candidates.push('Bún tươi sợi nhỏ', 'Chả cá thát lát', 'Rau thì là', 'Cà chua chín mọng', 'Nước mắm cá cơm Phú Quốc');
  } else if (dn.includes('com tam') || dn.includes('com suon')) {
    candidates.push('Gạo thơm ST25', 'Sườn non heo', 'Trứng gà ta', 'Dưa leo baby', 'Nước mắm cá cơm Phú Quốc');
  } else if (dn.includes('com ga')) {
    candidates.push('Gạo thơm ST25', 'Thịt gà ta thả vườn', 'Dưa leo baby', 'Nước mắm cá cơm Phú Quốc');
  } else if (dn.includes('com nieu')) {
    candidates.push('Gạo thơm ST25', 'Thăn bò mềm', 'Sốt tiêu đen Hồng Kông', 'Cá bống tượng');
  } else if (dn.includes('lau')) {
    candidates.push('Nấm kim châm', 'Bắp mỹ ngọt', 'Rau muống nước', 'Đậu hũ non', 'Mì tôm Miliket');
    if (dn.includes('thai') || dn.includes('tomyum')) candidates.push('Tôm sú tươi', 'Mực ống tươi', 'Sả cây tươi');
  } else if (dn.includes('oc')) {
    candidates.push('Ốc hương biển', 'Ốc móng tay', 'Bơ lạt thực vật', 'Tỏi tép Lý Sơn', 'Ớt chỉ thiên cay xé', 'Rau răm tươi');
  } else if (dn.includes('ca phe') || dn.includes('cafe')) {
    candidates.push('Cà phê Robusta Đắk Lắk', 'Sữa đặc có đường', 'Sữa tươi tiệt trùng');
    if (dn.includes('muoi')) candidates.push('Kem cheese mặn');
  } else if (dn.includes('tra sua')) {
    candidates.push('Trà đen Oolong đậm vị', 'Sữa tươi tiệt trùng', 'Trân châu đen dẻo dai', 'Sữa đặc có đường');
  } else if (dn.includes('banh mi')) {
    candidates.push('Bánh mì baguette', 'Thịt heo ba chỉ', 'Dưa leo baby', 'Rau mùi ta', 'Sốt mayonnaise');
  } else if (dn.includes('banh cuon')) {
    candidates.push('Nạc vai heo', 'Nấm mộc nhĩ', 'Hành phi giòn rụm', 'Nước mắm cá cơm Phú Quốc');
  } else if (dn.includes('chao')) {
    candidates.push('Gạo Tám xoan Hải Hậu', 'Hành lá (hành hoa)', 'Tiêu đen Phú Quốc', 'Quẩy giòn vàng ruộm');
    if (dn.includes('ech')) candidates.push('Gừng củ tươi', 'Dầu hào hảo hạng');
    if (dn.includes('suon')) candidates.push('Sườn sụn heo');
  } else if (dn.includes('xoi')) {
    candidates.push('Gạo nếp cái hoa vàng', 'Hành phi giòn rụm', 'Đậu xanh xát vỏ');
  } else if (dn.includes('ga')) {
    candidates.push('Thịt gà ta thả vườn', 'Lá chanh bánh tẻ', 'Hành lá (hành hoa)', 'Nước mắm cá cơm Phú Quốc');
  } else if (dn.includes('bo')) {
    candidates.push('Thịt bò bắp hoa', 'Thăn bò mềm', 'Tỏi tép Lý Sơn', 'Tiêu đen Phú Quốc');
  } else if (dn.includes('hai san') || dn.includes('tom') || dn.includes('muc')) {
    candidates.push('Tôm sú tươi', 'Mực ống tươi', 'Tỏi tép Lý Sơn', 'Ớt chỉ thiên cay xé');
  }

  const selectedLower = new Set(selectedList.value.map((s) => s.toLowerCase()));
  return candidates.filter((c) => !selectedLower.has(c.toLowerCase()));
});

function addAllSmartSuggestions() {
  const current = [...selectedList.value];
  for (const s of smartSuggestions.value) {
    if (!current.map((c) => c.toLowerCase()).includes(s.toLowerCase())) {
      current.push(s);
    }
  }
  updateList(current);
}

// Danh sách các nhóm nguyên liệu thực tế có sẵn
const availableGroups = computed(() => {
  if (props.ingredientGroups && props.ingredientGroups.length > 0) {
    return props.ingredientGroups;
  }
  const gMap = new Map<number, { id: number; name: string }>();
  for (const ing of props.availableIngredients) {
    if (ing.group_id && ing.group_name && !gMap.has(ing.group_id)) {
      gMap.set(ing.group_id, { id: ing.group_id, name: ing.group_name });
    }
  }
  return Array.from(gMap.values()).map((g) => ({
    id: g.id,
    name: g.name,
    display_order: 0,
    is_active: true,
    created_at: '',
  }));
});

// Các nguyên liệu thuộc nhóm đang xem trong Group Browser
const groupIngredients = computed(() => {
  if (activeGroupId.value === 'all') {
    return props.availableIngredients.slice(0, 40);
  }
  return props.availableIngredients.filter(
    (ing) => ing.group_id === activeGroupId.value
  );
});

function isIngredientSelected(name: string): boolean {
  return selectedList.value
    .map((s) => s.toLowerCase())
    .includes(name.toLowerCase());
}

function handleInputBlur() {
  setTimeout(() => {
    isInputFocused.value = false;
  }, 220);
}
</script>

<template>
  <div class="ingredient-box">
    <!-- 1. Vùng hiển thị Chips đã chọn + Ô tìm kiếm inline -->
    <div
      class="chip-input-container"
      :class="{ focused: isInputFocused }"
      @click="inputEl?.focus()"
    >
      <div
        v-for="(item, idx) in selectedList"
        :key="idx"
        class="selected-chip"
      >
        <span class="chip-text">{{ item }}</span>
        <button
          type="button"
          class="chip-remove"
          :title="`Xóa '${item}'`"
          @click.stop="removeIngredient(idx)"
        >
          <X class="w-3 h-3" />
        </button>
      </div>

      <input
        ref="inputEl"
        v-model="inputSearchText"
        type="text"
        class="inline-input"
        :placeholder="selectedList.length === 0 ? placeholder : 'Thêm nguyên liệu...'"
        @focus="isInputFocused = true"
        @blur="handleInputBlur"
        @keydown="handleKeyDown"
      />

      <!-- Dropdown Autocomplete khi người dùng gõ -->
      <div
        v-if="isInputFocused && (filteredAutocomplete.length > 0 || inputSearchText.trim())"
        class="autocomplete-dropdown"
      >
        <!-- Nút thêm nhanh mục mới nếu chưa có trong master -->
        <div
          v-if="
            inputSearchText.trim() &&
            !filteredAutocomplete.some(
              (i) => i.name.toLowerCase() === inputSearchText.trim().toLowerCase()
            )
          "
          class="dropdown-item new-item-row"
          @mousedown.prevent="addIngredient(inputSearchText.trim())"
        >
          <div class="item-main">
            <Plus class="w-4 h-4 text-emerald-600" />
            <span class="font-medium text-emerald-700">
              Thêm nguyên liệu mới: "<strong>{{ inputSearchText.trim() }}</strong>"
            </span>
          </div>
          <span class="item-badge-new">Nhấn Enter</span>
        </div>

        <div
          v-for="ing in filteredAutocomplete"
          :key="ing.id"
          class="dropdown-item"
          @mousedown.prevent="addIngredient(ing.name)"
        >
          <div class="item-main">
            <span class="item-name">{{ ing.name }}</span>
            <span v-if="ing.group_name" class="item-group-tag">
              {{ ing.group_name }}
            </span>
          </div>
          <span v-if="(ing.dish_count || 0) > 0" class="item-usage-badge">
            {{ ing.dish_count }} món dùng
          </span>
        </div>
      </div>
    </div>

    <!-- 2. Gợi ý thông minh (Smart Suggestions) theo tên món ăn -->
    <div
      v-if="smartSuggestions.length > 0"
      class="smart-suggestion-card"
    >
      <div class="smart-header">
        <div class="smart-title">
          <Sparkles class="w-4 h-4 text-amber-500" />
          <span>Gợi ý chuẩn cho món <strong>"{{ dishName }}"</strong>:</span>
        </div>
        <button
          type="button"
          class="btn-apply-all"
          @click="addAllSmartSuggestions"
        >
          <Plus class="w-3.5 h-3.5" />
          <span>Thêm tất cả</span>
        </button>
      </div>
      <div class="smart-chips-grid">
        <button
          v-for="s in smartSuggestions"
          :key="s"
          type="button"
          class="smart-chip"
          @click="addIngredient(s)"
        >
          <Plus class="w-3 h-3 text-emerald-600" />
          <span>{{ s }}</span>
        </button>
      </div>
    </div>

    <!-- 3. Thanh bật/tắt duyệt danh mục theo Nhóm nguyên liệu -->
    <div class="group-browser-section">
      <button
        type="button"
        class="toggle-browser-btn"
        @click="isGroupBrowserOpen = !isGroupBrowserOpen"
      >
        <div class="toggle-btn-left">
          <Layers class="w-4 h-4 text-emerald-600" />
          <span>Duyệt nhanh theo Nhóm nguyên liệu ({{ availableGroups.length }} nhóm, {{ availableIngredients.length }} nguyên liệu)</span>
        </div>
        <component
          :is="isGroupBrowserOpen ? ChevronUp : ChevronDown"
          class="w-4 h-4 text-slate-400"
        />
      </button>

      <!-- Panel duyệt nhóm dạng tabs cuộn -->
      <div v-if="isGroupBrowserOpen" class="group-browser-panel">
        <div class="group-tabs-row">
          <button
            type="button"
            class="group-tab"
            :class="{ active: activeGroupId === 'all' }"
            @click="activeGroupId = 'all'"
          >
            Tất cả
          </button>
          <button
            v-for="g in availableGroups"
            :key="g.id"
            type="button"
            class="group-tab"
            :class="{ active: activeGroupId === g.id }"
            @click="activeGroupId = g.id"
          >
            {{ g.name }}
          </button>
        </div>

        <!-- Lưới nguyên liệu trong nhóm -->
        <div class="group-ingredients-grid">
          <button
            v-for="ing in groupIngredients"
            :key="ing.id"
            type="button"
            class="browse-chip"
            :class="{ selected: isIngredientSelected(ing.name) }"
            @click="toggleIngredient(ing.name)"
          >
            <component
              :is="isIngredientSelected(ing.name) ? Check : Plus"
              class="w-3 h-3"
            />
            <span>{{ ing.name }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ingredient-box {
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: 100%;
}

/* 1. Tag Container Input */
.chip-input-container {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  min-height: 44px;
  background: var(--card, #ffffff);
  border: 1px solid var(--line, #cbd5e1);
  border-radius: 8px;
  position: relative;
  cursor: text;
  transition: all 0.2s ease;
}

.chip-input-container.focused {
  border-color: #10b981;
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.15);
}

.selected-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 6px;
  color: #065f46;
  font-size: 13px;
  font-weight: 500;
  line-height: 1.2;
}

.chip-remove {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  cursor: pointer;
  color: #059669;
  padding: 1px;
  border-radius: 50%;
  transition: background 0.15s ease;
}

.chip-remove:hover {
  background: #d1fae5;
  color: #b91c1c;
}

.inline-input {
  flex: 1;
  min-width: 180px;
  border: none;
  outline: none;
  background: transparent;
  font-size: 13.5px;
  color: var(--fg, #1e293b);
  padding: 4px 2px;
}

.inline-input::placeholder {
  color: #94a3b8;
  font-size: 13px;
}

/* Dropdown Autocomplete */
.autocomplete-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 20px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.05);
  z-index: 100;
  max-height: 250px;
  overflow-y: auto;
}

.dropdown-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  cursor: pointer;
  transition: background 0.12s ease;
  font-size: 13.5px;
  border-bottom: 1px solid #f8fafc;
}

.dropdown-item:last-child {
  border-bottom: none;
}

.dropdown-item:hover {
  background: #f0fdf4;
}

.item-main {
  display: flex;
  align-items: center;
  gap: 8px;
}

.item-name {
  font-weight: 500;
  color: #0f172a;
}

.item-group-tag {
  font-size: 11px;
  padding: 1px 6px;
  background: #f1f5f9;
  color: #475569;
  border-radius: 4px;
}

.item-usage-badge {
  font-size: 11px;
  color: #2563eb;
  background: #eff6ff;
  padding: 2px 6px;
  border-radius: 10px;
  font-weight: 500;
}

.new-item-row {
  background: #f0fdf4;
}

.item-badge-new {
  font-size: 11px;
  color: #059669;
  font-weight: 600;
}

/* 2. Smart Suggestion Card */
.smart-suggestion-card {
  background: #fffbeb;
  border: 1px dashed #fcd34d;
  border-radius: 8px;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.smart-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.smart-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: #92400e;
}

.btn-apply-all {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11.5px;
  font-weight: 600;
  color: #b45309;
  background: #fef3c7;
  border: 1px solid #fde68a;
  border-radius: 6px;
  padding: 3px 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-apply-all:hover {
  background: #fde68a;
  color: #78350f;
}

.smart-chips-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.smart-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 500;
  background: #ffffff;
  border: 1px solid #fde68a;
  color: #78350f;
  padding: 3px 8px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.smart-chip:hover {
  background: #fef3c7;
  border-color: #f59e0b;
}

/* 3. Group Browser Section */
.group-browser-section {
  display: flex;
  flex-direction: column;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #f8fafc;
}

.toggle-browser-btn {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 8px 12px;
  background: #f8fafc;
  border: none;
  cursor: pointer;
  font-size: 12.5px;
  font-weight: 600;
  color: #334155;
  transition: background 0.15s ease;
}

.toggle-browser-btn:hover {
  background: #f1f5f9;
}

.toggle-btn-left {
  display: flex;
  align-items: center;
  gap: 6px;
}

.group-browser-panel {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px 12px;
  background: #ffffff;
  border-top: 1px solid #e2e8f0;
}

.group-tabs-row {
  display: flex;
  gap: 6px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.group-tabs-row::-webkit-scrollbar {
  height: 4px;
}

.group-tabs-row::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.group-tab {
  white-space: nowrap;
  font-size: 11.5px;
  font-weight: 500;
  padding: 4px 10px;
  background: #f1f5f9;
  border: 1px solid transparent;
  border-radius: 20px;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}

.group-tab:hover {
  background: #e2e8f0;
  color: #0f172a;
}

.group-tab.active {
  background: #065f46;
  color: #ffffff;
  border-color: #065f46;
}

.group-ingredients-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  max-height: 160px;
  overflow-y: auto;
  padding: 2px;
}

.group-ingredients-grid::-webkit-scrollbar {
  width: 4px;
}

.group-ingredients-grid::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.browse-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 500;
  padding: 3px 8px;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
}

.browse-chip:hover {
  border-color: #10b981;
  color: #065f46;
}

.browse-chip.selected {
  background: #ecfdf5;
  border-color: #10b981;
  color: #065f46;
  font-weight: 600;
}
</style>
