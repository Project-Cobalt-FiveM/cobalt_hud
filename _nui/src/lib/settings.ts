import { BAR_RULES, GRID_SIZES, isOneOf, isRecord, MINIMAP_MODES, SPEED_UNITS, STATUS_IDS, VOICE_RULES } from './types';
import type { Layout, Point, Rule, Settings, StatusId, StatusRules } from './types';

export const DEFAULT_LAYOUT: Layout = {
  minimapOffset: { x: 0, y: 0 },
  status: null,
  speedometer: null,
};

export const DEFAULT_SETTINGS: Settings = {
  minimap: 'always',
  cinematic: false,
  unit: 'mph',
  status: {
    voice: 'always',
    health: 'below:90',
    armor: 'above:0',
    hunger: 'below:50',
    thirst: 'below:50',
    stamina: 'below:100',
    stress: 'above:0',
    alcohol: 'above:0',
  },
  layout: DEFAULT_LAYOUT,
  editor: { snap: true, grid: 32, showGrid: true },
};

export function rulesFor(id: StatusId): readonly Rule[] {
  return id === 'voice' ? VOICE_RULES : BAR_RULES;
}

export interface RuleLabel {
  text: string;
  value?: string;
}

export function ruleLabel(rule: Rule): RuleLabel {
  switch (rule) {
    case 'always':
      return { text: 'Always' };
    case 'hidden':
      return { text: 'Hidden' };
    case 'talking':
      return { text: 'While talking' };
    default: {
      const [op, value] = rule.split(':');
      return { text: op === 'below' ? 'Below' : 'Above', value };
    }
  }
}

export function isStatusShown(rule: Rule, value: number, talking: boolean): boolean {
  switch (rule) {
    case 'always':
      return true;
    case 'hidden':
      return false;
    case 'talking':
      return talking;
    default: {
      const [op, threshold] = rule.split(':');
      return op === 'below' ? value < Number(threshold) : value > Number(threshold);
    }
  }
}

const isPoint = (value: unknown): value is Point =>
  isRecord(value) && Number.isFinite(value.x) && Number.isFinite(value.y);

const isBarRule = isOneOf(BAR_RULES);
const isVoiceRule = isOneOf(VOICE_RULES);
const isMinimapMode = isOneOf(MINIMAP_MODES);
const isSpeedUnit = isOneOf(SPEED_UNITS);
const isGridSize = isOneOf(GRID_SIZES);

function mergeStatus(saved: unknown): StatusRules {
  const source = isRecord(saved) ? saved : {};
  const voice = source.voice;
  const rules: StatusRules = { ...DEFAULT_SETTINGS.status, voice: isVoiceRule(voice) ? voice : DEFAULT_SETTINGS.status.voice };

  for (const id of STATUS_IDS) {
    if (id === 'voice') continue;
    const rule = source[id];
    if (isBarRule(rule)) rules[id] = rule;
  }

  return rules;
}

export function mergeSettings(saved: unknown): Settings {
  const source = isRecord(saved) ? saved : {};
  const layout = isRecord(source.layout) ? source.layout : {};
  const editor = isRecord(source.editor) ? source.editor : {};
  const defaults = DEFAULT_SETTINGS;

  return {
    minimap: isMinimapMode(source.minimap) ? source.minimap : defaults.minimap,
    cinematic: source.cinematic === true,
    unit: isSpeedUnit(source.unit) ? source.unit : defaults.unit,
    status: mergeStatus(source.status),
    layout: {
      minimapOffset: isPoint(layout.minimapOffset) ? layout.minimapOffset : defaults.layout.minimapOffset,
      status: isPoint(layout.status) ? layout.status : null,
      speedometer: isPoint(layout.speedometer) ? layout.speedometer : null,
    },
    editor: {
      snap: typeof editor.snap === 'boolean' ? editor.snap : defaults.editor.snap,
      grid: isGridSize(editor.grid) ? editor.grid : defaults.editor.grid,
      showGrid: typeof editor.showGrid === 'boolean' ? editor.showGrid : defaults.editor.showGrid,
    },
  };
}
