<script lang="ts">
  import HandGrabbingIcon from 'phosphor-svelte/lib/HandGrabbingIcon';
  import { OUTLINE_PAD, clampToStage, snapTo } from '../lib/layout';
  import type { ComponentRects } from '../lib/layout';
  import type { ComponentId, EditorSettings, Point } from '../lib/types';

  interface Props {
    rects: ComponentRects;
    interactive: boolean;
    stageW: number;
    scale: number;
    editor: EditorSettings;
    dragging: ComponentId | null;
    ondrag: (id: ComponentId, position: Point) => void;
    ondrop: (id: ComponentId, position: Point) => void;
  }

  const IDS: readonly ComponentId[] = ['minimap', 'status', 'speedometer'];
  const LABELS: Record<ComponentId, string> = { minimap: 'Minimap', status: 'Status circles', speedometer: 'Speedometer' };
  const ALWAYS_TAGGED = new Set<ComponentId>(['minimap', 'speedometer']);

  let { rects, interactive, stageW, scale, editor, dragging, ondrag, ondrop }: Props = $props();

  function startDrag(id: ComponentId, event: PointerEvent) {
    const origin = rects[id];
    if (event.button !== 0 || !origin) return;

    event.preventDefault();

    const startX = event.clientX / scale;
    const startY = event.clientY / scale;
    let last: Point = { x: origin.x, y: origin.y };

    const position = (move: PointerEvent): Point => {
      let x = origin.x + move.clientX / scale - startX;
      let y = origin.y + move.clientY / scale - startY;

      if (editor.snap && !move.shiftKey) {
        x = snapTo(x, editor.grid);
        y = snapTo(y, editor.grid);
      }

      const clamped = clampToStage({ ...origin, x, y }, stageW);
      return { x: clamped.x, y: clamped.y };
    };

    const onMove = (move: PointerEvent) => {
      last = position(move);
      ondrag(id, last);
    };

    const onUp = () => {
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerup', onUp);
      ondrop(id, last);
    };

    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
    ondrag(id, last);
  }
</script>

<div class={{ 'pointer-events-none': !interactive }}>
  {#each IDS as id (id)}
    {@const rect = rects[id]}
    {@const active = dragging === id}
    {#if rect}
      <div
        role="button"
        tabindex="-1"
        aria-label="Move {LABELS[id].toLowerCase()}"
        onpointerdown={(event) => startDrag(id, event)}
        class={[
          'absolute rounded-[10px] border-cobalt',
          active ? 'cursor-grabbing border-2 border-solid' : 'cursor-grab border-[1.5px] border-dashed',
        ]}
        style:left="{rect.x - OUTLINE_PAD}px"
        style:top="{rect.y - OUTLINE_PAD}px"
        style:width="{rect.w + OUTLINE_PAD * 2}px"
        style:height="{rect.h + OUTLINE_PAD * 2}px"
      >
        {#if active || ALWAYS_TAGGED.has(id)}
          <div class="absolute -top-3 left-2 flex h-[22px] items-center gap-[5px] rounded-md bg-cobalt pr-2 pl-1.5">
            <HandGrabbingIcon size={12} weight="fill" color="#FAFAFA" />
            <span class="text-[11px] leading-[14px] font-semibold whitespace-nowrap">{LABELS[id]}</span>
          </div>
        {/if}
        {#if active}
          <div
            class="absolute -top-3 right-2 flex h-[22px] items-center gap-2 rounded-md border border-cobalt bg-card px-2 text-[11px] leading-[14px] font-semibold text-muted-foreground"
          >
            <span>X <span class="text-foreground tabular-nums">{Math.round(rect.x)}</span></span>
            <span>Y <span class="text-foreground tabular-nums">{Math.round(rect.y)}</span></span>
          </div>
        {/if}
      </div>
    {/if}
  {/each}
</div>
