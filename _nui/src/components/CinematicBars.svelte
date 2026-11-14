<script lang="ts">
  import { REF_HEIGHT } from '../lib/layout';

  interface Props {
    on: boolean;
    stageW: number;
  }

  const CINEMA_ASPECT = 2.39;

  let { on, stageW }: Props = $props();

  const height = $derived(Math.max(0, (REF_HEIGHT - stageW / CINEMA_ASPECT) / 2));
</script>

<div class="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
  <div
    class="absolute inset-x-0 top-0 bg-black transition-transform duration-300 ease-cobalt"
    style:height="{height}px"
    style:transform={on ? 'none' : 'translateY(-100%)'}
  ></div>
  <div
    class="absolute inset-x-0 bottom-0 bg-black transition-transform duration-300 ease-cobalt"
    style:height="{height}px"
    style:transform={on ? 'none' : 'translateY(100%)'}
  ></div>
</div>
