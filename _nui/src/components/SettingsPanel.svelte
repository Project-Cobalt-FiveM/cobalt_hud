<script lang="ts">
  import XIcon from 'phosphor-svelte/lib/XIcon';
  import CobaltMark from './CobaltMark.svelte';
  import Segmented from './Segmented.svelte';
  import Select from './Select.svelte';
  import Switch from './Switch.svelte';
  import { rise } from '../lib/motion';
  import { ruleLabel, rulesFor } from '../lib/settings';
  import { PANEL_ORDER, STATUS_META } from '../lib/statuses';
  import type { MinimapMode, Rule, Settings, SpeedUnit, StatusId, StatusRules } from '../lib/types';

  interface Props {
    settings: Settings;
    enteringEdit: boolean;
    onchange: (settings: Settings) => void;
    oneditpositions: () => void;
    onresetlayout: () => void;
    onsave: () => void;
    onclose: () => void;
  }

  const MINIMAP_OPTIONS: { value: MinimapMode; label: string }[] = [
    { value: 'always', label: 'Always' },
    { value: 'vehicle', label: 'In vehicle' },
    { value: 'off', label: 'Off' },
  ];

  const UNIT_OPTIONS: { value: SpeedUnit; label: string }[] = [
    { value: 'mph', label: 'mph' },
    { value: 'kmh', label: 'km/h' },
  ];

  const ruleOptions = (id: StatusId) =>
    rulesFor(id).map((rule) => {
      const { text, value } = ruleLabel(rule);
      return { value: rule, text, emphasis: value };
    });

  const section = 'flex flex-col border-b border-border px-[18px] py-4';
  const sectionLabel = 'text-xs leading-4 font-medium text-faint';
  const rowTitle = 'text-sm leading-[18px] font-medium';
  const secondaryButton =
    'flex h-9 items-center rounded-lg border border-border bg-muted px-3.5 text-sm leading-[18px] font-medium transition-colors duration-150 ease-cobalt outline-none hover:bg-secondary focus-visible:ring-2 focus-visible:ring-cobalt';

  let { settings, enteringEdit, onchange, oneditpositions, onresetlayout, onsave, onclose }: Props = $props();

  const set = (patch: Partial<Settings>) => onchange({ ...settings, ...patch });

  function setRule(id: StatusId, rule: Rule) {
    const status: StatusRules = { ...settings.status };

    if (id === 'voice') {
      if (rule === 'always' || rule === 'talking' || rule === 'hidden') status.voice = rule;
    } else if (rule !== 'talking') {
      status[id] = rule;
    }

    set({ status });
  }
</script>

{#snippet toggleRow(title: string, description: string, checked: boolean, onrowchange: (checked: boolean) => void)}
  <div class="flex items-center gap-3">
    <div class="flex flex-1 flex-col gap-0.5">
      <span class={rowTitle}>{title}</span>
      <span class="text-xs leading-4 text-muted-foreground">{description}</span>
    </div>
    <Switch {checked} label={title} onchange={onrowchange} />
  </div>
{/snippet}

<div class="pointer-events-none absolute inset-x-0 top-[186px] flex justify-center">
  <div
    role="dialog"
    aria-label="HUD settings"
    class="pointer-events-auto flex w-[440px] flex-col rounded-[14px] border border-border bg-card"
    in:rise
    out:rise={{ duration: 150 }}
  >
    <header class="flex items-center gap-3 border-b border-border pt-4 pr-4 pb-3.5 pl-[18px]">
      <CobaltMark size={32} />
      <div class="flex flex-col gap-px">
        <h1 class="text-base leading-5 font-semibold tracking-[-0.01em]">HUD settings</h1>
        <p class="text-xs leading-4 text-faint">Open anytime with <span class="font-semibold text-muted-foreground">/hud</span></p>
      </div>
      <button
        type="button"
        aria-label="Close"
        onclick={onclose}
        class="ml-auto flex size-8 shrink-0 items-center justify-center rounded-lg border border-border bg-muted transition-colors duration-150 ease-cobalt outline-none hover:bg-secondary focus-visible:ring-2 focus-visible:ring-cobalt"
      >
        <XIcon size={14} weight="fill" color="#A3A3A3" />
      </button>
    </header>

    <section class="{section} gap-3.5">
      <h2 class={sectionLabel}>Layout</h2>
      {@render toggleRow('Edit positions', 'Drag anything on screen to move it', enteringEdit, (on) => on && oneditpositions())}
      {@render toggleRow('Cinematic bars', 'Letterbox the screen for scenes and clips', settings.cinematic, (cinematic) => set({ cinematic }))}
      <div class="flex flex-col gap-2">
        <span class={rowTitle}>Minimap</span>
        <Segmented
          label="Minimap"
          options={MINIMAP_OPTIONS}
          value={settings.minimap}
          onchange={(minimap) => set({ minimap })}
          class="h-[34px] gap-[3px]"
          itemClass="flex-1 text-[13px] leading-4"
        />
      </div>
    </section>

    <section class="{section} gap-2.5">
      <div class="flex items-baseline justify-between">
        <h2 class={sectionLabel}>Status circles</h2>
        <span class="text-xs leading-4 text-faint">Show when</span>
      </div>
      {#each PANEL_ORDER as id (id)}
        {@const meta = STATUS_META[id]}
        <div class="flex items-center gap-2.5">
          <div class="flex size-7 shrink-0 items-center justify-center rounded-full bg-muted">
            <meta.icon size={13} weight="fill" color={meta.color} />
          </div>
          <span class="flex-1 {rowTitle}">{meta.label}</span>
          <Select
            label="Show {meta.label.toLowerCase()} when"
            value={settings.status[id]}
            options={ruleOptions(id)}
            onchange={(rule) => setRule(id, rule)}
          />
        </div>
      {/each}
    </section>

    <section class="{section} flex-row items-center gap-3">
      <span class="flex-1 {rowTitle}">Speed units</span>
      <Segmented
        label="Speed units"
        options={UNIT_OPTIONS}
        value={settings.unit}
        onchange={(unit) => set({ unit })}
        class="h-[30px] gap-[3px]"
        itemClass="w-14 text-[13px] leading-4"
      />
    </section>

    <footer class="flex items-center gap-2 px-[18px] py-3.5">
      <button type="button" onclick={onresetlayout} class={secondaryButton}>Reset layout</button>
      <button
        type="button"
        onclick={onsave}
        class="ml-auto flex h-9 items-center rounded-lg bg-cobalt px-[18px] text-sm leading-[18px] font-semibold transition-colors duration-150 ease-cobalt outline-none hover:bg-cobalt-hover focus-visible:ring-2 focus-visible:ring-foreground"
      >
        Save
      </button>
    </footer>
  </div>
</div>
