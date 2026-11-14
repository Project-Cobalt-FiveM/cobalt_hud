<script lang="ts">
  interface Props {
    size: number;
    surface?: string;
  }

  let { size, surface = '#141414' }: Props = $props();
</script>

<svg width={size} height={size} viewBox="0 0 120 120" fill="none" aria-hidden="true" class="shrink-0">
  <path d="M14 14 L44 36 L60 44 L76 36 L106 14 L101 74 C100 96 84 108 60 108 C36 108 20 96 19 74 Z" fill="#FAFAFA" />
  <path d="M53.2 52.8 A13 13 0 1 0 53.2 71.2" stroke={surface} stroke-width="7" stroke-linecap="round" />
  <circle cx="76" cy="62" r="12" stroke={surface} stroke-width="7" />
  <circle cx="76" cy="62" r="4.5" fill="#5078D7" />
  <path d="M55.5 79 L64.5 79 L60 87 Z" fill={surface} />
</svg>
