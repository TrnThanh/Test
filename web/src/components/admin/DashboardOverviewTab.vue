<script setup lang="ts">
import { computed } from 'vue';
import type { SystemStats, Restaurant, Category, AdminUser } from '../../types';
import PageHeader from '../common/PageHeader.vue';
import StatCard from '../common/StatCard.vue';
import StatusPill from '../common/StatusPill.vue';
import { RefreshCw, UtensilsCrossed } from 'lucide-vue-next';

const props = withDefaults(
  defineProps<{
    stats: SystemStats | null;
    restaurants: Restaurant[];
    categories: Category[];
    users?: AdminUser[];
    loading: boolean;
  }>(),
  {
    users: () => [],
  }
);

const emit = defineEmits<{
  (e: 'refresh'): void;
  (e: 'selectRestaurantMenu', restaurantId: number): void;
  (e: 'switchTab', tab: string): void;
}>();

// Sort restaurants by created_at descending (or id descending) to take the 5 newest
const newestRestaurants = computed(() => {
  return [...props.restaurants]
    .sort((a, b) => {
      const timeA = a.created_at ? new Date(a.created_at).getTime() : a.id;
      const timeB = b.created_at ? new Date(b.created_at).getTime() : b.id;
      return timeB - timeA;
    })
    .slice(0, 5);
});

// Top categories sorted by dish count
const topCategories = computed(() => {
  return [...props.categories]
    .sort((a, b) => (b.dish_count || 0) - (a.dish_count || 0))
    .slice(0, 6);
});

const maxCategoryDishes = computed(() => {
  if (topCategories.value.length === 0) return 1;
  const max = Math.max(...topCategories.value.map((c) => c.dish_count || 0));
  return max > 0 ? max : 1;
});

// Weekly user chart calculation (grouping strictly by local date getFullYear/getMonth/getDate, avoiding UTC conversion)
const weeklyChartData = computed(() => {
  const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  const now = new Date();
  const buckets: { dateKey: string; label: string; count: number }[] = [];

  // Generate 7 consecutive local days ending today
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    const dateKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    const dayOfWeek = dayNames[d.getDay()];
    buckets.push({
      dateKey,
      label: dayOfWeek,
      count: 0,
    });
  }

  // Count users per local date if users list is available
  if (props.users && props.users.length > 0) {
    for (const u of props.users) {
      if (!u.created_at) continue;
      const uDate = new Date(u.created_at);
      if (isNaN(uDate.getTime())) continue;
      // Extract local year, month, date
      const uKey = `${uDate.getFullYear()}-${String(uDate.getMonth() + 1).padStart(2, '0')}-${String(uDate.getDate()).padStart(2, '0')}`;
      const bucket = buckets.find((b) => b.dateKey === uKey);
      if (bucket) {
        bucket.count++;
      }
    }
  }

  const maxVal = Math.max(...buckets.map((b) => b.count), 1);
  return buckets.map((b, idx) => ({
    day: b.label,
    value: b.count,
    height: maxVal > 0 && b.count > 0 ? (b.count / maxVal) * 105 : 4,
    isPeak: idx === 6 || (b.count === maxVal && b.count > 0),
  }));
});

function formatCreatedAt(dateStr?: string | null): string {
  if (!dateStr) return 'Mới thêm gần đây';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.toLocaleString('vi-VN', {
      hour: '2-digit',
      minute: '2-digit',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  } catch {
    return dateStr;
  }
}
</script>

<template>
  <div class="dashboard-overview">
    <PageHeader
      title="Tổng quan"
      subtitle="Thống kê hệ thống và hoạt động dữ liệu ẩm thực PTC1"
    >
      <template #actions>
        <button
          type="button"
          class="btn"
          aria-label="Làm mới dữ liệu tổng quan"
          :disabled="loading"
          @click="emit('refresh')"
        >
          <RefreshCw class="btn-icon" :class="{ 'spin-icon': loading }" />
          <span>{{ loading ? 'Đang nạp...' : 'Làm mới' }}</span>
        </button>
      </template>
    </PageHeader>

    <!-- 4 Stats Cards (No Deltas, Card 4 is "Tổng danh mục") -->
    <div class="stats-grid">
      <StatCard
        title="Cơ sở quán ăn"
        :value="stats?.total_restaurants ?? 0"
        :sub="`${stats?.active_restaurants ?? 0} đang mở · ${stats?.inactive_restaurants ?? 0} tạm tắt`"
      />
      <StatCard
        title="Món ăn"
        :value="stats?.total_dishes ?? 0"
        :sub="`${stats?.total_categories ?? categories.length} nhóm danh mục`"
      />
      <StatCard
        title="Người dùng app"
        :value="stats?.total_users ?? 0"
        sub="Đăng ký từ Mobile App"
      />
      <StatCard
        title="Tổng danh mục"
        :value="stats?.total_categories ?? categories.length"
        sub="Hệ thống danh mục món"
      />
    </div>

    <!-- 2 Column Chart & Category Breakdown Grid -->
    <div class="grid2">
      <!-- Handcrafted SVG Bar Chart -->
      <div class="card pad">
        <h3>Người dùng mới</h3>
        <p>Phân bổ hoạt động 7 ngày gần nhất</p>
        <div class="chart-wrapper">
          <svg
            viewBox="0 0 420 170"
            class="svg-chart"
            role="img"
            aria-label="Biểu đồ phân bổ người dùng mới 7 ngày qua"
          >
            <g v-for="(item, i) in weeklyChartData" :key="item.day">
              <!-- Bar -->
              <rect
                :x="14 + i * 58"
                :y="140 - Math.max(item.height, 4)"
                width="36"
                :height="Math.max(item.height, 4)"
                rx="6"
                :fill="item.isPeak ? 'var(--pri)' : 'var(--pri-s)'"
              />
              <!-- Value text -->
              <text
                :x="32 + i * 58"
                :y="132 - Math.max(item.height, 4)"
                text-anchor="middle"
                font-size="11"
                fill="var(--mut)"
              >
                {{ item.value }}
              </text>
              <!-- Day text -->
              <text
                :x="32 + i * 58"
                y="160"
                text-anchor="middle"
                font-size="11"
                fill="var(--mut)"
              >
                {{ item.day }}
              </text>
            </g>
          </svg>
        </div>
      </div>

      <!-- Categories Distribution Bar Rows -->
      <div class="card pad">
        <h3>Món theo danh mục</h3>
        <p>Tổng cộng {{ stats?.total_dishes ?? 0 }} món ăn trên hệ thống</p>
        <div v-if="topCategories.length > 0" class="category-bars">
          <div v-for="cat in topCategories" :key="cat.id" class="hb">
            <span class="cat-name" :title="cat.name">{{ cat.name }}</span>
            <span class="bar-track">
              <i
                :style="{
                  width: `${Math.round(((cat.dish_count || 0) / maxCategoryDishes) * 100)}%`,
                }"
              ></i>
            </span>
            <span>{{ cat.dish_count || 0 }}</span>
          </div>
        </div>
        <div v-else class="empty-cats">
          <span>Chưa có dữ liệu danh mục.</span>
        </div>
      </div>
    </div>

    <!-- Quán mới thêm (5 quán mới nhất theo created_at) -->
    <div class="card recent-card">
      <div class="pad recent-header">
        <h3>Quán mới thêm</h3>
        <p>5 cơ sở ẩm thực được khởi tạo gần nhất trong cơ sở dữ liệu</p>
      </div>

      <div class="wrap">
        <table>
          <thead>
            <tr>
              <th>Cơ sở</th>
              <th>Thời gian tạo</th>
              <th>Trạng thái</th>
              <th style="text-align: right;">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in newestRestaurants" :key="r.id">
              <td>
                <div class="ent">
                  <div class="sq">{{ r.name.charAt(0).toUpperCase() }}</div>
                  <div>
                    <b>{{ r.name }}</b>
                    <small>{{ r.phone || 'Chưa cập nhật SĐT' }}</small>
                  </div>
                </div>
              </td>
              <td class="text-mut">
                {{ formatCreatedAt(r.created_at) }}
              </td>
              <td>
                <StatusPill :active="r.is_active" />
              </td>
              <td style="text-align: right;">
                <button
                  type="button"
                  class="btn"
                  aria-label="Xem thực đơn của quán"
                  @click="emit('selectRestaurantMenu', r.id)"
                >
                  <UtensilsCrossed class="btn-icon" />
                  <span>Thực đơn</span>
                </button>
              </td>
            </tr>

            <tr v-if="newestRestaurants.length === 0">
              <td colspan="4" class="empty">
                Chưa có dữ liệu quán ăn. Vui lòng thêm quán mới tại tab Cơ sở quán ăn.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard-overview {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.btn-icon {
  width: 15px;
  height: 15px;
}

.spin-icon {
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
}

.grid2 {
  display: grid;
  grid-template-columns: 3fr 2fr;
  gap: 14px;
}

.chart-wrapper {
  margin-top: 8px;
}

.svg-chart {
  width: 100%;
  height: auto;
  display: block;
}

.category-bars {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cat-name {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-weight: 500;
}

.bar-track {
  background: var(--bg);
  border-radius: 4px;
  height: 8px;
  overflow: hidden;
  display: block;
}

.empty-cats {
  color: var(--mut);
  font-size: 13px;
  padding: 12px 0;
}

.recent-card {
  margin-top: 2px;
}

.recent-header {
  padding-bottom: 8px;
}

.text-mut {
  color: var(--mut);
  font-size: 13px;
}

@media (max-width: 860px) {
  .grid2 {
    grid-template-columns: 1fr;
  }
}
</style>
