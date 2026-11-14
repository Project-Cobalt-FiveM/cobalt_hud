export const STATUS_IDS = ['voice', 'health', 'armor', 'hunger', 'thirst', 'stamina', 'stress', 'alcohol'] as const;
export const BAR_RULES = ['always', 'below:100', 'below:90', 'below:75', 'below:50', 'below:25', 'above:0', 'hidden'] as const;
export const VOICE_RULES = ['always', 'talking', 'hidden'] as const;
export const MINIMAP_MODES = ['always', 'vehicle', 'off'] as const;
export const SPEED_UNITS = ['mph', 'kmh'] as const;
export const GRID_SIZES = [8, 16, 32, 64] as const;
export const DRIVE_STATES = ['P', 'R', 'N', 'D'] as const;

export type StatusId = (typeof STATUS_IDS)[number];
export type BarStatusId = Exclude<StatusId, 'voice'>;
export type BarRule = (typeof BAR_RULES)[number];
export type VoiceRule = (typeof VOICE_RULES)[number];
export type Rule = BarRule | VoiceRule;
export type MinimapMode = (typeof MINIMAP_MODES)[number];
export type SpeedUnit = (typeof SPEED_UNITS)[number];
export type GridSize = (typeof GRID_SIZES)[number];
export type DriveState = (typeof DRIVE_STATES)[number];
export type ComponentId = 'minimap' | 'status' | 'speedometer';

export interface Point {
  x: number;
  y: number;
}

export interface Rect extends Point {
  w: number;
  h: number;
}

export type StatusRules = { voice: VoiceRule } & Record<BarStatusId, BarRule>;

export interface Layout {
  minimapOffset: Point;
  status: Point | null;
  speedometer: Point | null;
}

export interface EditorSettings {
  snap: boolean;
  grid: GridSize;
  showGrid: boolean;
}

export interface Settings {
  minimap: MinimapMode;
  cinematic: boolean;
  unit: SpeedUnit;
  status: StatusRules;
  layout: Layout;
  editor: EditorSettings;
}

export interface Status {
  health: number;
  armour: number;
  hunger: number;
  thirst: number;
  stamina: number;
  stress: number;
  alcohol: number;
  alcoholStage: number;
  talking: boolean;
  voiceLevel: number;
}

export type Seatbelt = 'on' | 'off' | false;

export interface Vehicle {
  show: boolean;
  speed: number;
  rpm: number;
  gear: number;
  drive: DriveState;
  fuel: number;
  fuelLow: boolean;
  engineOn: boolean;
  engineWarn: boolean;
  seatbelt: Seatbelt;
  lights: boolean;
}

export interface MinimapGeo {
  left: number;
  top: number;
  width: number;
  height: number;
}

export interface LocationInfo {
  shown: boolean;
  street: string;
  area: string;
  postal: string;
}

export type NuiMessage =
  | { action: 'toggleHud'; visible: boolean }
  | { action: 'setPaused'; paused: boolean }
  | { action: 'hideHud' }
  | { action: 'showHud' }
  | { action: 'loadSettings'; saved: unknown }
  | { action: 'openMenu' }
  | { action: 'closeMenu' }
  | { action: 'updateStatus'; patch: Partial<Status> }
  | { action: 'updateVehicle'; patch: Partial<Vehicle> }
  | { action: 'setMinimapGeo'; geo: MinimapGeo }
  | { action: 'updateLocation'; patch: Partial<LocationInfo> };

export interface NuiCallbacks {
  closeMenu: Record<string, never>;
  applySettings: { settings: Settings; editing: boolean };
  saveSettings: Settings;
}

type Guard<T> = (value: unknown) => value is T;
type Shape<T> = { [K in keyof T]-?: Guard<T[K]> };

export const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const isNumber = (value: unknown): value is number => typeof value === 'number' && Number.isFinite(value);
const isBoolean: Guard<boolean> = (value) => typeof value === 'boolean';
const isString: Guard<string> = (value) => typeof value === 'string';

export function isOneOf<const T extends readonly unknown[]>(options: T): Guard<T[number]> {
  return (value): value is T[number] => options.includes(value);
}

const isSeatbelt: Guard<Seatbelt> = (value) => value === 'on' || value === 'off' || value === false;

const STATUS_SHAPE: Shape<Status> = {
  health: isNumber,
  armour: isNumber,
  hunger: isNumber,
  thirst: isNumber,
  stamina: isNumber,
  stress: isNumber,
  alcohol: isNumber,
  alcoholStage: isNumber,
  talking: isBoolean,
  voiceLevel: isNumber,
};

const VEHICLE_SHAPE: Shape<Vehicle> = {
  show: isBoolean,
  speed: isNumber,
  rpm: isNumber,
  gear: isNumber,
  drive: isOneOf(DRIVE_STATES),
  fuel: isNumber,
  fuelLow: isBoolean,
  engineOn: isBoolean,
  engineWarn: isBoolean,
  seatbelt: isSeatbelt,
  lights: isBoolean,
};

const LOCATION_SHAPE: Shape<LocationInfo> = {
  shown: isBoolean,
  street: isString,
  area: isString,
  postal: isString,
};

const GEO_SHAPE: Shape<MinimapGeo> = {
  left: isNumber,
  top: isNumber,
  width: isNumber,
  height: isNumber,
};

function toPatch<T>(value: unknown, shape: Shape<T>): Partial<T> {
  const patch: Partial<T> = {};
  if (!isRecord(value)) return patch;

  for (const key in shape) {
    const field = value[key];
    if (shape[key](field)) patch[key] = field;
  }

  return patch;
}

function toGeo(value: unknown): MinimapGeo | null {
  const geo = toPatch(value, GEO_SHAPE);
  const { left, top, width, height } = geo;
  if (left === undefined || top === undefined || width === undefined || height === undefined) return null;

  return { left, top, width, height };
}

export function toNuiMessage(value: unknown): NuiMessage | null {
  if (!isRecord(value)) return null;

  const data = value.data;
  const flag = (key: string) => isRecord(data) && data[key] === true;

  switch (value.action) {
    case 'toggleHud':
      return { action: 'toggleHud', visible: flag('visible') };
    case 'setPaused':
      return { action: 'setPaused', paused: flag('paused') };
    case 'hideHud':
    case 'showHud':
    case 'openMenu':
    case 'closeMenu':
      return { action: value.action };
    case 'loadSettings':
      return { action: 'loadSettings', saved: data };
    case 'updateStatus':
      return { action: 'updateStatus', patch: toPatch(data, STATUS_SHAPE) };
    case 'updateVehicle':
      return { action: 'updateVehicle', patch: toPatch(data, VEHICLE_SHAPE) };
    case 'updateLocation':
      return { action: 'updateLocation', patch: toPatch(data, LOCATION_SHAPE) };
    case 'setMinimapGeo': {
      const geo = toGeo(data);
      return geo && { action: 'setMinimapGeo', geo };
    }
    default:
      return null;
  }
}
