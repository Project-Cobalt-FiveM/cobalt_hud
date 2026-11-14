import { REF_HEIGHT } from './layout';
import { onMockCallback } from './nui';
import type { LocationInfo, Point, Status, Vehicle } from './types';

const MINIMAP = { left: 40, top: 792, width: 288, height: 184 };

const STATUS: Status = { health: 82, armour: 40, hunger: 46, thirst: 22, stamina: 99, stress: 35, alcohol: 62, alcoholStage: 2, talking: true, voiceLevel: 2 };

const VEHICLE: Vehicle = {
  show: true,
  speed: 87,
  rpm: 62,
  gear: 4,
  drive: 'D',
  fuel: 68,
  fuelLow: false,
  engineOn: true,
  engineWarn: false,
  seatbelt: 'off',
  lights: true,
};

const LOCATION: LocationInfo = { shown: true, street: 'Alta St', area: 'Downtown Vinewood', postal: '468' };

function post(action: string, data?: unknown) {
  window.postMessage({ action, data });
}

function postMinimapGeo(offset: Point) {
  const scale = window.innerHeight / REF_HEIGHT;

  post('setMinimapGeo', {
    left: (MINIMAP.left + offset.x) * scale,
    top: (MINIMAP.top + offset.y) * scale,
    width: MINIMAP.width * scale,
    height: MINIMAP.height * scale,
  });
}

export function startMock(): void {
  let offset: Point = { x: 0, y: 0 };

  onMockCallback((name, data) => {
    if (name !== 'applySettings' || !('settings' in data)) return;

    const next = data.settings.layout.minimapOffset;
    if (next.x === offset.x && next.y === offset.y) return;

    offset = next;
    postMinimapGeo(offset);
  });

  window.addEventListener('resize', () => postMinimapGeo(offset));
  document.body.style.background = '#2B2620';

  setTimeout(() => {
    post('loadSettings', { minimap: 'vehicle' });
    postMinimapGeo(offset);
    post('toggleHud', { visible: true });
    post('updateStatus', STATUS);
    post('updateVehicle', VEHICLE);
    post('updateLocation', LOCATION);
    if (new URLSearchParams(location.search).has('menu')) post('openMenu');
  }, 100);
}
