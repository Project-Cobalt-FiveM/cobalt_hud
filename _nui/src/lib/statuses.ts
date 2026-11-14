import BrainIcon from 'phosphor-svelte/lib/BrainIcon';
import DropIcon from 'phosphor-svelte/lib/DropIcon';
import ForkKnifeIcon from 'phosphor-svelte/lib/ForkKnifeIcon';
import HeartIcon from 'phosphor-svelte/lib/HeartIcon';
import LightningIcon from 'phosphor-svelte/lib/LightningIcon';
import MicrophoneIcon from 'phosphor-svelte/lib/MicrophoneIcon';
import ShieldIcon from 'phosphor-svelte/lib/ShieldIcon';
import WineIcon from 'phosphor-svelte/lib/WineIcon';
import type { Status, StatusId } from './types';

export interface StatusMeta {
  label: string;
  color: string;
  icon: typeof HeartIcon;
}

export const STATUS_META: Record<StatusId, StatusMeta> = {
  voice: { label: 'Voice', color: '#5078D7', icon: MicrophoneIcon },
  health: { label: 'Health', color: '#EF4444', icon: HeartIcon },
  armor: { label: 'Armor', color: '#A78BFA', icon: ShieldIcon },
  hunger: { label: 'Hunger', color: '#F59E0B', icon: ForkKnifeIcon },
  thirst: { label: 'Thirst', color: '#38BDF8', icon: DropIcon },
  stamina: { label: 'Stamina', color: '#22C55E', icon: LightningIcon },
  stress: { label: 'Stress', color: '#EC4899', icon: BrainIcon },
  alcohol: { label: 'Alcohol', color: '#FACC15', icon: WineIcon },
};

export const PANEL_ORDER: readonly StatusId[] = ['health', 'armor', 'hunger', 'thirst', 'stamina', 'stress', 'alcohol', 'voice'];

const ALCOHOL_STAGE_COLORS = ['#A3A3A3', '#FACC15', '#F97316', '#EF4444'] as const;

export function statusColor(id: StatusId, status: Status): string {
  if (id !== 'alcohol') return STATUS_META[id].color;

  return ALCOHOL_STAGE_COLORS[Math.min(Math.max(status.alcoholStage, 0), ALCOHOL_STAGE_COLORS.length - 1)] ?? STATUS_META.alcohol.color;
}

export function statusValue(id: StatusId, status: Status): number {
  switch (id) {
    case 'voice':
      return status.talking ? 100 : (status.voiceLevel / 3) * 100;
    case 'armor':
      return status.armour;
    default:
      return status[id];
  }
}
