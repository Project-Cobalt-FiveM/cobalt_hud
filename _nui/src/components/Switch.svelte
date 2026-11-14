<script lang="ts">
  interface Props {
    checked: boolean;
    label: string;
    size?: 'md' | 'sm';
    onchange: (checked: boolean) => void;
  }

  const SIZES = {
    md: { track: 'h-[22px] w-[38px]', knob: 'size-4', travel: 16 },
    sm: { track: 'h-5 w-[34px]', knob: 'size-3.5', travel: 14 },
  };

  let { checked, label, size = 'md', onchange }: Props = $props();

  const dims = $derived(SIZES[size]);
</script>

<button
  type="button"
  role="switch"
  aria-checked={checked}
  aria-label={label}
  onclick={() => onchange(!checked)}
  class={[
    'flex shrink-0 items-center rounded-full px-[3px] transition-colors duration-150 ease-cobalt outline-none focus-visible:ring-2 focus-visible:ring-cobalt',
    dims.track,
    checked ? 'bg-cobalt' : 'bg-secondary',
  ]}
>
  <span
    class={['rounded-full transition duration-150 ease-cobalt', dims.knob, checked ? 'bg-foreground' : 'bg-faint']}
    style:transform="translateX({checked ? dims.travel : 0}px)"
  ></span>
</button>
