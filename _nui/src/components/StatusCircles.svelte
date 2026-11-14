<script lang="ts">
  import { CIRCLE_SIZE } from '../lib/layout';
  import { pop } from '../lib/motion';
  import { isStatusShown } from '../lib/settings';
  import { STATUS_META, statusColor, statusValue } from '../lib/statuses';
  import { STATUS_IDS } from '../lib/types';
  import type { Rect, Status, StatusRules } from '../lib/types';

  interface Props {
    status: Status;
    rules: StatusRules;
    rect: Rect;
    showAll: boolean;
  }

  const RADIUS = 18;
  const CIRCUMFERENCE = 2 * Math.PI * RADIUS;
  const IDLE_VOICE = '#525252';
  const IDLE_ICON = '#A3A3A3';

  let { status, rules, rect, showAll }: Props = $props();

  const gap = $derived((rect.w - STATUS_IDS.length * CIRCLE_SIZE) / (STATUS_IDS.length - 1));

  const circles = $derived(
    STATUS_IDS.map((id) => {
      const value = statusValue(id, status);
      const idle = id === 'voice' && !status.talking;
      const color = idle ? IDLE_VOICE : statusColor(id, status);

      return {
        id,
        icon: STATUS_META[id].icon,
        color,
        iconColor: idle ? IDLE_ICON : color,
        fraction: Math.min(Math.max(value / 100, 0), 1),
        shown: showAll || isStatusShown(rules[id], value, status.talking),
      };
    }),
  );
</script>

<div
  class="absolute flex items-center"
  style:left="{rect.x}px"
  style:top="{rect.y}px"
  style:width="{rect.w}px"
  style:height="{rect.h}px"
  style:gap="{gap}px"
>
  {#each circles as circle (circle.id)}
    {#if circle.shown}
      <div class="relative flex size-11 shrink-0 items-center justify-center" transition:pop>
        <svg width={CIRCLE_SIZE} height={CIRCLE_SIZE} viewBox="0 0 44 44" class="absolute inset-0">
          <circle cx="22" cy="22" r="22" fill="#141414" />
          <circle cx="22" cy="22" r={RADIUS} fill="none" stroke="#262626" stroke-width="3.5" />
          {#if circle.fraction > 0}
            <circle
              cx="22"
              cy="22"
              r={RADIUS}
              transform="rotate(-90 22 22)"
              fill="none"
              stroke={circle.color}
              stroke-width="3.5"
              stroke-linecap={circle.fraction < 1 ? 'round' : 'butt'}
              stroke-dasharray="{circle.fraction * CIRCUMFERENCE} {CIRCUMFERENCE}"
              class="transition-[stroke-dasharray] duration-300 ease-cobalt"
            />
          {/if}
        </svg>
        <span class="relative flex"><circle.icon size={16} weight="fill" color={circle.iconColor} /></span>
      </div>
    {/if}
  {/each}
</div>
