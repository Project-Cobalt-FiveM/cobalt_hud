<script lang="ts" generics="T extends string">
  import CaretDownIcon from 'phosphor-svelte/lib/CaretDownIcon';
  import CheckIcon from 'phosphor-svelte/lib/CheckIcon';

  interface Option {
    value: T;
    text: string;
    emphasis?: string;
  }

  interface Props {
    options: readonly Option[];
    value: T;
    label: string;
    onchange: (value: T) => void;
  }

  let { options, value, label, onchange }: Props = $props();

  let open = $state(false);
  let active = $state(0);
  let root: HTMLDivElement | undefined = $state();

  const selected = $derived(options.find((option) => option.value === value));

  $effect(() => {
    if (!open) return;

    const onPointerDown = (event: PointerEvent) => {
      if (event.target instanceof Node && !root?.contains(event.target)) open = false;
    };

    window.addEventListener('pointerdown', onPointerDown);
    return () => window.removeEventListener('pointerdown', onPointerDown);
  });

  function openList() {
    active = Math.max(0, options.findIndex((option) => option.value === value));
    open = true;
  }

  function choose(option: Option | undefined) {
    if (option) onchange(option.value);
    open = false;
  }

  function onkeydown(event: KeyboardEvent) {
    const confirm = event.key === 'Enter' || event.key === ' ';

    if (!open) {
      if (confirm || event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();
        openList();
      }
      return;
    }

    if (event.key === 'Escape') {
      event.stopPropagation();
      open = false;
    } else if (event.key === 'ArrowDown') {
      event.preventDefault();
      active = Math.min(active + 1, options.length - 1);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      active = Math.max(active - 1, 0);
    } else if (confirm) {
      event.preventDefault();
      choose(options[active]);
    }
  }
</script>

{#snippet optionText(option: Option)}
  {option.text}
  {#if option.emphasis}<span class="font-semibold tabular-nums">{option.emphasis}</span>{/if}
{/snippet}

<div bind:this={root} class="relative shrink-0" role="presentation" {onkeydown}>
  <button
    type="button"
    aria-haspopup="listbox"
    aria-expanded={open}
    aria-label={label}
    onclick={() => (open ? (open = false) : openList())}
    class="flex h-[30px] w-32 items-center justify-between rounded-[7px] border border-border bg-muted pr-2 pl-2.5 text-[13px] leading-4 transition-colors duration-150 ease-cobalt outline-none hover:border-input focus-visible:ring-2 focus-visible:ring-cobalt"
  >
    <span>
      {#if selected}{@render optionText(selected)}{/if}
    </span>
    <CaretDownIcon size={11} weight="fill" color="#737373" />
  </button>

  {#if open}
    <ul role="listbox" aria-label={label} class="absolute top-[34px] right-0 z-10 w-40 rounded-lg border border-border bg-popover p-1">
      {#each options as option, i (option.value)}
        <li
          role="option"
          aria-selected={option.value === value}
          onpointerenter={() => (active = i)}
          onclick={() => choose(option)}
          onkeydown={() => {}}
          class={['flex h-8 cursor-default items-center justify-between rounded-md px-2 text-[13px]', i === active && 'bg-muted']}
        >
          <span>{@render optionText(option)}</span>
          {#if option.value === value}<CheckIcon size={12} weight="fill" color="#FAFAFA" />{/if}
        </li>
      {/each}
    </ul>
  {/if}
</div>
