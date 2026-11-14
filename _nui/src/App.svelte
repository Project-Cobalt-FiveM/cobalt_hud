<script lang="ts">
  import { onMount, untrack } from 'svelte';
  import CinematicBars from './components/CinematicBars.svelte';
  import EditGrid from './components/EditGrid.svelte';
  import EditOutlines from './components/EditOutlines.svelte';
  import EditToolbar from './components/EditToolbar.svelte';
  import Location from './components/Location.svelte';
  import MinimapMock from './components/MinimapMock.svelte';
  import SettingsPanel from './components/SettingsPanel.svelte';
  import Speedometer from './components/Speedometer.svelte';
  import StatusCircles from './components/StatusCircles.svelte';
  import { componentRects, REF_HEIGHT } from './lib/layout';
  import { rise } from './lib/motion';
  import { fetchNui, onNuiMessage } from './lib/nui';
  import { DEFAULT_LAYOUT, DEFAULT_SETTINGS, mergeSettings } from './lib/settings';
  import type {
    ComponentId,
    EditorSettings,
    Layout,
    LocationInfo,
    MinimapGeo,
    NuiMessage,
    Point,
    Settings,
    Status,
    Vehicle,
  } from './lib/types';

  type Mode = 'hud' | 'panel' | 'edit';

  const EDIT_ENTER_DELAY = 250;

  let innerWidth = $state(window.innerWidth);
  let innerHeight = $state(window.innerHeight);

  let visible = $state(false);
  let paused = $state(false);
  let inventoryOpen = $state(false);
  let minimapGeo = $state<MinimapGeo | null>(null);
  const status = $state<Status>({ health: 100, armour: 0, hunger: 100, thirst: 100, stamina: 100, stress: 0, alcohol: 0, alcoholStage: 0, talking: false, voiceLevel: 2 });
  const vehicle = $state<Vehicle>({
    show: false,
    speed: 0,
    rpm: 0,
    gear: 0,
    drive: 'P',
    fuel: 100,
    fuelLow: false,
    engineOn: false,
    engineWarn: false,
    seatbelt: false,
    lights: false,
  });
  const location = $state<LocationInfo>({ shown: false, street: '', area: '', postal: '' });

  let saved = $state<Settings | null>(null);
  let draft = $state<Settings | null>(null);
  let mode = $state<Mode>('hud');
  let enteringEdit = $state(false);
  let editLayout = $state<Layout | null>(null);
  let history = $state<Layout[]>([]);
  let drag = $state<({ id: ComponentId } & Point) | null>(null);
  let lastApplied = '';

  const scale = $derived(Math.max(innerHeight, 1) / REF_HEIGHT);
  const stageW = $derived(innerWidth / scale);
  const panelSettings = $derived(draft ?? saved);
  const base = $derived(panelSettings ?? DEFAULT_SETTINGS);
  const active = $derived(editLayout ? { ...base, layout: editLayout } : base);
  const editing = $derived(mode === 'edit');
  const geo = $derived(
    minimapGeo && {
      left: minimapGeo.left / scale,
      top: minimapGeo.top / scale,
      width: minimapGeo.width / scale,
      height: minimapGeo.height / scale,
    },
  );
  const rects = $derived.by(() => {
    const result = componentRects(active.layout, geo, stageW);
    const dragged = drag && result[drag.id];
    if (drag && dragged) Object.assign(result, { [drag.id]: { ...dragged, x: drag.x, y: drag.y } });
    return result;
  });
  const hudShown = $derived(editing || (visible && !paused && !inventoryOpen && !active.cinematic));

  const pendingStatus: Partial<Status> = {};
  const pendingVehicle: Partial<Vehicle> = {};

  function flushPending<T extends object>(target: T, pending: Partial<T>) {
    Object.assign(target, pending);
    for (const key of Object.keys(pending)) delete pending[key as keyof T];
  }

  $effect(() => {
    if (!hudShown) return;

    untrack(() => {
      flushPending(status, pendingStatus);
      flushPending(vehicle, pendingVehicle);
    });
  });

  $effect(() => {
    if (!saved) return;

    const payload = { settings: $state.snapshot(active), editing };
    const json = JSON.stringify(payload);
    if (json === lastApplied) return;

    lastApplied = json;
    void fetchNui('applySettings', payload);
  });

  function handleMessage(message: NuiMessage) {
    switch (message.action) {
      case 'toggleHud':
        visible = message.visible;
        break;
      case 'setPaused':
        paused = message.paused;
        break;
      case 'hideHud':
        inventoryOpen = true;
        break;
      case 'showHud':
        inventoryOpen = false;
        break;
      case 'loadSettings':
        saved = mergeSettings(message.saved);
        break;
      case 'openMenu':
        mode = 'panel';
        break;
      case 'closeMenu':
        resetPanel();
        break;
      case 'updateStatus':
        Object.assign(hudShown ? status : pendingStatus, message.patch);
        break;
      case 'updateVehicle':
        Object.assign(hudShown ? vehicle : pendingVehicle, message.patch);
        break;
      case 'updateLocation':
        Object.assign(location, message.patch);
        break;
      case 'setMinimapGeo':
        minimapGeo = message.geo;
        break;
      default: {
        const unhandled: never = message;
        return unhandled;
      }
    }
  }

  onMount(() => onNuiMessage(handleMessage));

  function resetPanel() {
    enteringEdit = false;
    draft = null;
    mode = 'hud';
  }

  function closePanel() {
    resetPanel();
    void fetchNui('closeMenu', {});
  }

  function save() {
    if (!panelSettings) return;

    const settings = $state.snapshot(panelSettings);
    saved = settings;
    void fetchNui('saveSettings', settings);
    closePanel();
  }

  function enterEdit() {
    if (enteringEdit || !panelSettings) return;

    enteringEdit = true;
    setTimeout(() => {
      if (!enteringEdit || !panelSettings) return;

      enteringEdit = false;
      editLayout = $state.snapshot(panelSettings.layout);
      history = [];
      mode = 'edit';
    }, EDIT_ENTER_DELAY);
  }

  function leaveEdit() {
    editLayout = null;
    drag = null;
    mode = 'panel';
  }

  function finishEdit() {
    if (!saved || !panelSettings || !editLayout) return;

    const layout = $state.snapshot(editLayout);
    const next: Settings = { ...$state.snapshot(saved), layout, editor: $state.snapshot(panelSettings.editor) };
    saved = next;
    draft = { ...$state.snapshot(panelSettings), layout };
    void fetchNui('saveSettings', next);
    leaveEdit();
  }

  function changeLayout(layout: Layout) {
    if (editLayout) history = [...history, editLayout];
    editLayout = layout;
  }

  function undo() {
    const previous = history.at(-1);
    if (!previous) return;

    editLayout = previous;
    history = history.slice(0, -1);
  }

  function changeEditor(editor: EditorSettings) {
    if (panelSettings) draft = { ...panelSettings, editor };
  }

  function drop(id: ComponentId, position: Point) {
    drag = null;
    if (!editLayout) return;

    if (id !== 'minimap') {
      changeLayout({ ...editLayout, [id]: position });
      return;
    }

    if (!geo) return;

    const offset = editLayout.minimapOffset;
    changeLayout({
      ...editLayout,
      minimapOffset: { x: offset.x + position.x - geo.left, y: offset.y + position.y - geo.top },
    });
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key !== 'Escape') return;

    if (mode === 'edit') leaveEdit();
    else if (mode === 'panel') closePanel();
  }
</script>

<svelte:window bind:innerWidth bind:innerHeight {onkeydown} />

<div class="fixed inset-0 overflow-hidden">
  <div
    class="absolute top-0 left-0 origin-top-left"
    style:width="{stageW}px"
    style:height="{REF_HEIGHT}px"
    style:transform="scale({scale})"
  >
    {#if import.meta.env.DEV && rects.minimap}
      <MinimapMock rect={rects.minimap} />
    {/if}
    {#if editing && active.editor.showGrid}
      <EditGrid size={active.editor.grid} {stageW} />
    {/if}

    <div class="transition-opacity duration-200 ease-cobalt" style:opacity={hudShown ? 1 : 0}>
      {#if !editing}
        <Location {location} anchor={rects.minimap} />
      {/if}
      <StatusCircles {status} rules={active.status} rect={rects.status} showAll={editing} />
      {#if vehicle.show || editing}
        <div in:rise out:rise={{ duration: 150 }}>
          <Speedometer {vehicle} unit={active.unit} rect={rects.speedometer} />
        </div>
      {/if}
    </div>

    <CinematicBars on={active.cinematic && visible && !editing} {stageW} />

    {#if editing || enteringEdit}
      <EditOutlines
        {rects}
        interactive={editing}
        {stageW}
        {scale}
        editor={active.editor}
        dragging={drag?.id ?? null}
        ondrag={(id, position) => (drag = { id, ...position })}
        ondrop={drop}
      />
    {/if}
    {#if editing}
      <EditToolbar
        editor={active.editor}
        canUndo={history.length > 0}
        oneditorchange={changeEditor}
        onundo={undo}
        onreset={() => changeLayout(DEFAULT_LAYOUT)}
        ondone={finishEdit}
      />
    {/if}

    {#if mode === 'panel' && panelSettings}
      <SettingsPanel
        settings={panelSettings}
        {enteringEdit}
        onchange={(settings) => (draft = settings)}
        oneditpositions={enterEdit}
        onresetlayout={() => panelSettings && (draft = { ...panelSettings, layout: DEFAULT_LAYOUT })}
        onsave={save}
        onclose={closePanel}
      />
    {/if}
  </div>
</div>
