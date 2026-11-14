<script lang="ts">
  import type { Rect } from '../lib/types';

  interface Props {
    rect: Rect;
  }

  let { rect }: Props = $props();
</script>

<svg
  class="absolute"
  style:left="{rect.x}px"
  style:top="{rect.y}px"
  width={rect.w}
  height={rect.h}
  viewBox="0 0 288 184"
  preserveAspectRatio="none"
  aria-hidden="true"
>
  <rect width="288" height="184" fill="#3A3D3F" />
  <path d="M196 0 H288 V96 C262 92 240 74 226 52 C214 34 204 16 196 0 Z" fill="#2C4A63" />
  <path d="M0 150 C40 138 70 140 96 152 C118 162 128 174 132 184 H0 Z" fill="#45503F" />
  <path d="M-10 118 L300 70" stroke="#8E9193" stroke-width="7" />
  <path d="M90 -10 L120 194" stroke="#6E7173" stroke-width="4" />
  <path d="M168 -10 C176 60 178 120 160 194" fill="none" stroke="#6E7173" stroke-width="4" />
  <path d="M0 40 L210 64" stroke="#5F6264" stroke-width="3" />
  <path d="M30 184 L250 120" stroke="#5F6264" stroke-width="3" />
  <path d="M230 184 L262 104" stroke="#5F6264" stroke-width="3" />
  <path d="M44 0 L60 184" stroke="#555859" stroke-width="2" />
  <path d="M0 92 L288 132" stroke="#555859" stroke-width="2" />
  <rect x="104" y="20" width="22" height="16" fill="#47494B" />
  <rect x="132" y="128" width="26" height="20" fill="#47494B" />
  <rect x="200" y="132" width="18" height="24" fill="#47494B" />
  <circle cx="232" cy="40" r="5" fill="#F2C744" stroke="#1A1A1A" stroke-width="1.5" />
  <path d="M144 82 L152 102 L144 97 L136 102 Z" fill="#FAFAFA" stroke="#1A1A1A" />
  <text x="144" y="13" font-size="10" font-weight="700" text-anchor="middle" fill="#FAFAFA">N</text>
</svg>
