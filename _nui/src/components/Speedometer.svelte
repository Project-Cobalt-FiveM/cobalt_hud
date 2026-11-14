<script lang="ts">
  import EngineIcon from 'phosphor-svelte/lib/EngineIcon';
  import GasPumpIcon from 'phosphor-svelte/lib/GasPumpIcon';
  import HeadlightsIcon from 'phosphor-svelte/lib/HeadlightsIcon';
  import SeatbeltIcon from 'phosphor-svelte/lib/SeatbeltIcon';
  import { DRIVE_STATES } from '../lib/types';
  import type { Rect, SpeedUnit, Vehicle } from '../lib/types';

  interface Props {
    vehicle: Vehicle;
    unit: SpeedUnit;
    rect: Rect;
  }

  const CX = 150;
  const CY = 150;
  const START_DEG = 135;
  const SWEEP_DEG = 270;
  const SPEED_R = 120;
  const RPM_R = 104;
  const TICK_INNER_R = 92;
  const TICK_OUTER_R = 97;
  const LABEL_R = 80;
  const REDLINE = 0.85;
  const TICK_STEP = 20;
  const DIM = '#525252';
  const SCALES: Record<SpeedUnit, { max: number; label: string }> = {
    mph: { max: 160, label: 'mph' },
    kmh: { max: 260, label: 'km/h' },
  };

  let { vehicle, unit, rect }: Props = $props();

  function point(fraction: number, r: number) {
    const rad = ((START_DEG + SWEEP_DEG * fraction) * Math.PI) / 180;
    return { x: CX + r * Math.cos(rad), y: CY + r * Math.sin(rad) };
  }

  function arc(from: number, to: number, r: number): string {
    const a = point(from, r);
    const b = point(to, r);
    const large = (to - from) * SWEEP_DEG > 180 ? 1 : 0;
    return `M${a.x.toFixed(2)} ${a.y.toFixed(2)} A${r} ${r} 0 ${large} 1 ${b.x.toFixed(2)} ${b.y.toFixed(2)}`;
  }

  const scale = $derived(SCALES[unit]);
  const speedFraction = $derived(Math.min(vehicle.speed / scale.max, 1));
  const rpmFraction = $derived(Math.min(Math.max(vehicle.rpm / 100, 0), REDLINE));
  const ticks = $derived(
    Array.from({ length: scale.max / TICK_STEP + 1 }, (_, i) => {
      const fraction = (i * TICK_STEP) / scale.max;
      return {
        value: i * TICK_STEP,
        inner: point(fraction, TICK_INNER_R),
        outer: point(fraction, TICK_OUTER_R),
        label: point(fraction, LABEL_R),
      };
    }),
  );
  const engineColor = $derived(vehicle.engineWarn ? '#EF4444' : vehicle.engineOn ? '#FAFAFA' : DIM);
  const engineLabel = $derived(vehicle.engineWarn ? 'Engine warning' : vehicle.engineOn ? 'Engine on' : 'Engine off');
  const fullArc = arc(0, 1, SPEED_R);
  const redlineArc = arc(REDLINE, 1, RPM_R);
</script>

<div class="absolute" style:left="{rect.x}px" style:top="{rect.y}px" style:width="{rect.w}px" style:height="{rect.h}px">
  <svg width="300" height="264" viewBox="0 0 300 264" class="absolute inset-0">
    <path d={fullArc} fill="none" stroke="#262626" stroke-width="6" stroke-linecap="round" />
    {#if speedFraction > 0}
      <path d={arc(0, speedFraction, SPEED_R)} fill="none" stroke="#5078D7" stroke-width="6" stroke-linecap="round" />
    {/if}
    {#if rpmFraction > 0}
      <path d={arc(0, rpmFraction, RPM_R)} fill="none" stroke="#FAFAFA" stroke-width="2" stroke-linecap="round" />
    {/if}
    {#if rpmFraction < REDLINE}
      <path d={arc(rpmFraction, REDLINE, RPM_R)} fill="none" stroke="#3A3A3A" stroke-width="2" stroke-linecap="round" />
    {/if}
    <path d={redlineArc} fill="none" stroke="#EF4444" stroke-width="2" stroke-linecap="round" />
    {#each ticks as tick (tick.value)}
      <line x1={tick.inner.x} y1={tick.inner.y} x2={tick.outer.x} y2={tick.outer.y} stroke="#A3A3A3" stroke-width="2" stroke-linecap="round" />
      <text x={tick.label.x} y={tick.label.y} fill="#A3A3A3" font-size="11" font-weight="500" text-anchor="middle">{tick.value}</text>
    {/each}
  </svg>

  <div class="absolute inset-x-0 top-[100px] flex flex-col items-center">
    <span class="text-[68px] leading-[68px] font-semibold tracking-[-0.03em] tabular-nums">{vehicle.speed}</span>
    <span class="text-[13px] leading-4 font-medium text-muted-foreground">{scale.label}</span>
  </div>

  <div class="absolute inset-x-0 top-[196px] flex justify-center gap-[14px]">
    {#if vehicle.seatbelt}
      <span role="img" aria-label={vehicle.seatbelt === 'on' ? 'Seatbelt on' : 'Seatbelt off'} class="flex">
        <SeatbeltIcon size={16} weight="fill" color={vehicle.seatbelt === 'on' ? DIM : '#EAB308'} />
      </span>
    {/if}
    <span role="img" aria-label={engineLabel} class="flex">
      <EngineIcon size={16} weight="fill" color={engineColor} />
    </span>
    <span role="img" aria-label="Headlights" class="flex">
      <HeadlightsIcon size={16} weight="fill" color={vehicle.lights ? '#FAFAFA' : DIM} />
    </span>
  </div>

  <div class="absolute inset-x-0 top-[232px] flex items-center justify-center gap-3">
    <div class="flex items-center gap-[5px]">
      <GasPumpIcon size={14} weight="fill" color={vehicle.fuelLow ? '#EAB308' : '#A3A3A3'} />
      <span class="text-[13px] leading-4 font-semibold tabular-nums">{vehicle.fuel}%</span>
    </div>
    <div class="h-3.5 w-px bg-dim"></div>
    <div class="flex items-baseline gap-[7px] text-[13px] leading-4 font-semibold">
      {#each DRIVE_STATES as drive (drive)}
        {#if drive === vehicle.drive}
          <span class="text-[15px] leading-[18px] font-bold text-cobalt">
            {drive}{#if drive === 'D' && vehicle.gear > 0}<span class="text-[11px] leading-[14px] font-semibold text-foreground tabular-nums">{vehicle.gear}</span>{/if}
          </span>
        {:else}
          <span class="text-faint">{drive}</span>
        {/if}
      {/each}
    </div>
  </div>
</div>
