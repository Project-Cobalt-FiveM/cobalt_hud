import { STATUS_IDS } from './types';
import type { ComponentId, Layout, MinimapGeo, Rect } from './types';

export const REF_HEIGHT = 1080;
export const CIRCLE_SIZE = 44;
export const OUTLINE_PAD = 10;
export const SPEEDOMETER_SIZE = { w: 300, h: 264 };

const STATUS_SIZE = { w: 288, h: CIRCLE_SIZE };
const MIN_CIRCLE_GAP = 4;
const MIN_STATUS_W = STATUS_IDS.length * CIRCLE_SIZE + (STATUS_IDS.length - 1) * MIN_CIRCLE_GAP;
const STATUS_GAP_BELOW_MINIMAP = 16;
const SPEEDOMETER_MARGIN = { right: 40, bottom: 24 };

export type ComponentRects = { [K in ComponentId]: K extends 'minimap' ? Rect | null : Rect };

export function clampToStage(rect: Rect, stageW: number): Rect {
  return {
    ...rect,
    x: Math.min(Math.max(rect.x, 0), stageW - rect.w),
    y: Math.min(Math.max(rect.y, 0), REF_HEIGHT - rect.h),
  };
}

export function componentRects(layout: Layout, geo: MinimapGeo | null, stageW: number): ComponentRects {
  const statusDefault = {
    x: geo?.left ?? 40,
    y: (geo ? geo.top + geo.height : 976) + STATUS_GAP_BELOW_MINIMAP,
  };
  const speedometerDefault = {
    x: stageW - SPEEDOMETER_SIZE.w - SPEEDOMETER_MARGIN.right,
    y: REF_HEIGHT - SPEEDOMETER_SIZE.h - SPEEDOMETER_MARGIN.bottom,
  };
  const statusSize = { w: Math.max(geo?.width ?? STATUS_SIZE.w, MIN_STATUS_W), h: STATUS_SIZE.h };

  return {
    minimap: geo && { x: geo.left, y: geo.top, w: geo.width, h: geo.height },
    status: clampToStage({ ...(layout.status ?? statusDefault), ...statusSize }, stageW),
    speedometer: clampToStage({ ...(layout.speedometer ?? speedometerDefault), ...SPEEDOMETER_SIZE }, stageW),
  };
}

export function snapTo(value: number, grid: number): number {
  return Math.round(value / grid) * grid;
}
