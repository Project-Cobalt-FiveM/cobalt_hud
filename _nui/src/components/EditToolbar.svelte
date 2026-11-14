<script lang="ts">
  import ArrowCounterClockwiseIcon from 'phosphor-svelte/lib/ArrowCounterClockwiseIcon';
  import EyeIcon from 'phosphor-svelte/lib/EyeIcon';
  import EyeSlashIcon from 'phosphor-svelte/lib/EyeSlashIcon';
  import GridFourIcon from 'phosphor-svelte/lib/GridFourIcon';
  import MagnetStraightIcon from 'phosphor-svelte/lib/MagnetStraightIcon';
  import CobaltMark from './CobaltMark.svelte';
  import Segmented from './Segmented.svelte';
  import Switch from './Switch.svelte';
  import { GRID_SIZES } from '../lib/types';
  import type { EditorSettings } from '../lib/types';

  interface Props {
    editor: EditorSettings;
    canUndo: boolean;
    oneditorchange: (editor: EditorSettings) => void;
    onundo: () => void;
    onreset: () => void;
    ondone: () => void;
  }

  const GRID_OPTIONS = GRID_SIZES.map((size) => ({ value: size, label: String(size) }));
  const toolbarButton =
    'flex h-[34px] items-center justify-center rounded-lg border border-border bg-muted transition-colors duration-150 ease-cobalt outline-none hover:bg-secondary focus-visible:ring-2 focus-visible:ring-cobalt';

  let { editor, canUndo, oneditorchange, onundo, onreset, ondone }: Props = $props();

  const set = (patch: Partial<EditorSettings>) => oneditorchange({ ...editor, ...patch });
  const GridVisibility = $derived(editor.showGrid ? EyeIcon : EyeSlashIcon);
</script>

{#snippet divider()}
  <div class="h-6 w-px shrink-0 bg-border"></div>
{/snippet}

<div class="absolute top-8 left-1/2 flex -translate-x-1/2 flex-col items-center gap-2">
  <div class="flex h-[52px] items-center gap-3 rounded-xl border border-border bg-card pr-2 pl-3.5">
    <div class="flex items-center gap-2">
      <CobaltMark size={24} />
      <span class="text-sm leading-[18px] font-semibold">Edit mode</span>
    </div>
    {@render divider()}
    <div class="flex items-center gap-2">
      <MagnetStraightIcon size={15} weight="fill" color="#A3A3A3" />
      <span class="text-[13px] leading-4 font-medium">Snap</span>
      <Switch size="sm" label="Snap to grid" checked={editor.snap} onchange={(snap) => set({ snap })} />
    </div>
    {@render divider()}
    <div class="flex items-center gap-2">
      <GridFourIcon size={15} weight="fill" color="#A3A3A3" />
      <span class="text-[13px] leading-4 font-medium">Grid</span>
      <Segmented
        label="Grid size"
        options={GRID_OPTIONS}
        value={editor.grid}
        onchange={(grid) => set({ grid })}
        class="h-[30px] gap-0.5"
        itemClass="w-[34px] text-xs leading-4 tabular-nums"
      />
      <button
        type="button"
        aria-label={editor.showGrid ? 'Hide grid' : 'Show grid'}
        aria-pressed={editor.showGrid}
        onclick={() => set({ showGrid: !editor.showGrid })}
        class={[
          'flex size-[30px] items-center justify-center rounded-lg transition-colors duration-150 ease-cobalt outline-none focus-visible:ring-2 focus-visible:ring-cobalt',
          editor.showGrid ? 'bg-secondary' : 'hover:bg-muted',
        ]}
      >
        <GridVisibility size={15} weight="fill" color={editor.showGrid ? '#FAFAFA' : '#A3A3A3'} />
      </button>
    </div>
    {@render divider()}
    <button type="button" aria-label="Undo" disabled={!canUndo} onclick={onundo} class="{toolbarButton} w-[34px] disabled:hover:bg-muted">
      <ArrowCounterClockwiseIcon size={15} weight="fill" color={canUndo ? '#FAFAFA' : '#525252'} />
    </button>
    <button type="button" onclick={onreset} class="{toolbarButton} px-3 text-[13px] leading-4 font-medium">Reset</button>
    <button
      type="button"
      onclick={ondone}
      class="flex h-[34px] items-center rounded-lg bg-cobalt px-4 text-[13px] leading-4 font-semibold transition-colors duration-150 ease-cobalt outline-none hover:bg-cobalt-hover focus-visible:ring-2 focus-visible:ring-foreground"
    >
      Done
    </button>
  </div>

  <div class="flex h-7 items-center gap-2.5 rounded-lg border border-border bg-card px-3 text-xs leading-4 text-muted-foreground">
    <span>Drag to move</span>
    <div class="h-3 w-px bg-border"></div>
    <span><span class="font-semibold text-foreground">Shift</span> moves freely</span>
    <div class="h-3 w-px bg-border"></div>
    <span><span class="font-semibold text-foreground">Esc</span> discards changes</span>
  </div>
</div>
