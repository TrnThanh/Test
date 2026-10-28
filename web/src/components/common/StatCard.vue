<script setup lang="ts">
defineProps<{
  title: string;
  value: string | number;
  sub?: string;
  delta?: string;
  deltaType?: 'ok' | 'neutral' | 'bad';
}>();
</script>

<template>
  <div class="card stat">
    <small class="stat-title">{{ title }}</small>
    <b class="stat-value">{{ value }}</b>
    <span
      v-if="delta"
      class="delta"
      :class="{
        n: deltaType === 'neutral',
        b: deltaType === 'bad',
      }"
    >
      {{ delta }}
    </span>
    <div v-if="sub" class="stat-sub">{{ sub }}</div>
  </div>
</template>

<style scoped>
.stat {
  padding: 16px;
  display: flex;
  flex-direction: column;
}

.stat-title {
  color: var(--mut);
  font-size: 13px;
  font-weight: 500;
}

.stat-value {
  display: block;
  font-size: 28px;
  line-height: 1.2;
  margin: 6px 0 4px;
  color: var(--ink);
  font-variant-numeric: tabular-nums;
}

.stat-sub {
  color: var(--mut);
  font-size: 12.5px;
  margin-top: 2px;
}

.delta {
  font-size: 12px;
  font-weight: 600;
  color: var(--ok);
  margin-bottom: 2px;
}

.delta.n {
  color: var(--mut);
  font-weight: 400;
}

.delta.b {
  color: var(--bad);
}
</style>
