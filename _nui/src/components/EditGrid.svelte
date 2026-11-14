<script lang="ts">
  import { REF_HEIGHT } from '../lib/layout';

  interface Props {
    size: number;
    stageW: number;
  }

  let { size, stageW }: Props = $props();

  const centerX = $derived(Math.round(stageW / 2));
</script>

<svg class="pointer-events-none absolute inset-0" width={stageW} height={REF_HEIGHT} aria-hidden="true">
  <defs>
    <pattern id="edit-grid" width={size} height={size} patternUnits="userSpaceOnUse">
      <path d="M0 0V{size}M0 0H{size}" fill="none" stroke="#3A3A3A" />
    </pattern>
  </defs>
  <rect width={stageW} height={REF_HEIGHT} fill="url(#edit-grid)" />
  <path d="M{centerX} 0V{REF_HEIGHT}M0 {REF_HEIGHT / 2}H{stageW}" fill="none" stroke="#23365F" stroke-width="1.5" />
</svg>
