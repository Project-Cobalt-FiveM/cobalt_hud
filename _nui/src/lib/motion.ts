import type { TransitionConfig } from 'svelte/transition';

function cubicBezier(x1: number, y1: number, x2: number, y2: number): (progress: number) => number {
  const cx = 3 * x1;
  const bx = 3 * (x2 - x1) - cx;
  const ax = 1 - cx - bx;
  const cy = 3 * y1;
  const by = 3 * (y2 - y1) - cy;
  const ay = 1 - cy - by;
  const curveX = (t: number) => ((ax * t + bx) * t + cx) * t;
  const curveY = (t: number) => ((ay * t + by) * t + cy) * t;
  const slopeX = (t: number) => (3 * ax * t + 2 * bx) * t + cx;

  return (progress) => {
    let t = progress;

    for (let i = 0; i < 8; i++) {
      const error = curveX(t) - progress;
      const slope = slopeX(t);
      if (Math.abs(error) < 1e-5 || Math.abs(slope) < 1e-6) break;
      t -= error / slope;
    }

    return curveY(Math.min(1, Math.max(0, t)));
  };
}

export const easeCobalt = cubicBezier(0.2, 0, 0, 1);

export function rise(_node: Element, { duration = 200, distance = 4 } = {}): TransitionConfig {
  return {
    duration,
    easing: easeCobalt,
    css: (t) => `opacity: ${t}; transform: translateY(${(1 - t) * distance}px)`,
  };
}

export function pop(_node: Element, { duration = 200 } = {}): TransitionConfig {
  return {
    duration,
    easing: easeCobalt,
    css: (t) => `opacity: ${t}; transform: scale(${0.9 + 0.1 * t})`,
  };
}
