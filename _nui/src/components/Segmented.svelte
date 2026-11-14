<script lang="ts" generics="T extends string | number">
  interface Option {
    value: T;
    label: string;
  }

  interface Props {
    options: readonly Option[];
    value: T;
    label: string;
    class?: string;
    itemClass?: string;
    onchange: (value: T) => void;
  }

  let { options, value, label, class: className = '', itemClass = '', onchange }: Props = $props();
</script>

<div role="radiogroup" aria-label={label} class={['flex rounded-lg border border-border bg-background p-[3px]', className]}>
  {#each options as option (option.value)}
    {@const selected = option.value === value}
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      onclick={() => onchange(option.value)}
      class={[
        'flex items-center justify-center rounded-md transition-colors duration-150 ease-cobalt outline-none focus-visible:ring-2 focus-visible:ring-cobalt',
        itemClass,
        selected ? 'bg-secondary font-semibold text-foreground' : 'font-medium text-muted-foreground hover:text-foreground',
      ]}
    >
      {option.label}
    </button>
  {/each}
</div>
