<script lang="ts">
  import MapPinIcon from 'phosphor-svelte/lib/MapPinIcon';
  import type { LocationInfo, Rect } from '../lib/types';

  interface Props {
    location: LocationInfo;
    anchor: Rect | null;
  }

  const CHIP_HEIGHT = 32;
  const GAP_ABOVE_MINIMAP = 8;

  let { location, anchor }: Props = $props();
</script>

{#if anchor && location.shown && location.street}
  <div
    class="absolute flex items-center gap-1.5 rounded-md border border-border bg-card px-2 text-[13px] leading-4 whitespace-nowrap"
    style:left="{anchor.x}px"
    style:top="{anchor.y - CHIP_HEIGHT - GAP_ABOVE_MINIMAP}px"
    style:height="{CHIP_HEIGHT}px"
    style:max-width="{anchor.w}px"
  >
    <span class="flex shrink-0"><MapPinIcon size={14} weight="fill" color="#A3A3A3" /></span>
    {#if location.postal}
      <span class="shrink-0 font-semibold tabular-nums">{location.postal}</span>
      <span class="h-4 w-px shrink-0 bg-border"></span>
    {/if}
    <span class="truncate font-medium">{location.street}</span>
    {#if location.area}
      <span class="truncate font-medium text-muted-foreground">{location.area}</span>
    {/if}
  </div>
{/if}
