# Hammerspoon Feature Toggle Menubar Implementation Plan

> Superseded: feature enablement is now controlled by the Git-ignored `feature.lua`; see `README.md`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user enable and disable three Hammerspoon features immediately from a persistent menu bar menu without editing `init.lua` or reloading Hammerspoon.

**Architecture:** Each managed feature owns an idempotent `start()`/`stop()` lifecycle and reports actual state through `isRunning()`. A feature manager maps stable IDs to those modules, applies persisted `hs.settings` values, and isolates lifecycle failures; a separate menu module renders the manager's current state and toggles it.

**Tech Stack:** Lua 5.5, Hammerspoon APIs (`hs.hotkey`, `hs.caffeinate`, `hs.battery.watcher`, `hs.menubar`, `hs.settings`, `hs.logger`, `hs.alert`), standalone Lua assertion tests.

**Spec:** `docs/superpowers/specs/2026-10-13-feature-toggle-menubar-design.md`

## Global Constraints

- Managed features are exactly `hotkeys`, `system_events`, and `display_awake`.
- First-run defaults are enabled, enabled, and disabled respectively; a saved `false` must not be confused with a missing setting.
- Toggle actions take effect without `hs.reload()` and the menu checkmark reflects actual `isRunning()` state.
- Persist a selection only after its lifecycle call succeeds.
- `config_reloader` stays outside the feature registry and retains its current disabled state.
- Add no third-party dependency.
- The current baseline has two known failures: `tests/init_test.lua` expects display awake to be enabled, and `tests/system_events_test.lua` expects retired Bluetooth sleep handling. Tasks 2 and 6 replace those stale assertions.

## Review Focus

- Repeated calls and partially failed starts must not duplicate or leak resources; Tasks 1–3 test idempotence and rollback.
- A saved `false` and an invalid non-boolean setting must resolve differently: saved `false` wins, invalid data falls back to the declared default; Task 4 tests both.
- A lifecycle exception must not persist the requested state or prevent other features from initializing; Task 4 tests failure isolation.
- A stopped display timer must not execute `pmset` even if its captured callback is invoked after shutdown; Task 3 tests this race.
- Opening the menu after an out-of-band module state change must show actual state, and clicking must invert the latest state rather than a stale snapshot; Task 5 tests both.

---

### Task 1: Give hotkeys an idempotent lifecycle

**Files:**
- Create: `tests/hotkeys_test.lua`
- Modify: `modules/hotkeys.lua:6-18`
- Modify: `tests/system_events_test.lua:15-20,35-39,80-96`

**Interfaces:**
- Consumes: existing callbacks from `modules.apps`, `modules.bluetooth`, `modules.mouse`, and `modules.window`.
- Produces: `hotkeys.start() -> nil`, `hotkeys.stop() -> nil`, and `hotkeys.isRunning() -> boolean`.

- [ ] **Step 1: Write the failing lifecycle test**

Create `tests/hotkeys_test.lua` with `hs.hotkey.bind()` returning handles whose `delete()` calls are counted. Assert that the first `start()` creates the seven existing bindings, a second `start()` creates none, `isRunning()` is true, the first `stop()` deletes all seven once, a second `stop()` deletes none, and a later `start()` creates seven new handles. Keep the Bluetooth binding callback assertion currently located in `tests/system_events_test.lua`. In a fresh module load, make the fourth bind fail and assert the first three handles are deleted and `isRunning()` remains false.

- [ ] **Step 2: Remove unrelated hotkey assertions from the system-event test and run the new test**

Remove the Bluetooth/hotkey stubs and lines 80–96 from `tests/system_events_test.lua` after moving their coverage. Run: `lua tests/hotkeys_test.lua`

Expected: FAIL because `modules.hotkeys.start`, `stop`, and `isRunning` do not exist.

- [ ] **Step 3: Implement the hotkey lifecycle**

Replace `bindAll()` with `start()`, retain every object returned by `hs.hotkey.bind()` in a module-local array, delete them in `stop()`, clear the array, and derive `isRunning()` from whether the array is present. Build bindings in a temporary array so a failed bind deletes earlier handles before rethrowing. Do not keep a compatibility alias: all repository callers move to `start()`.

- [ ] **Step 4: Verify the hotkey tests**

Run: `lua tests/hotkeys_test.lua`

Expected: `hotkeys tests passed`.

- [ ] **Step 5: Commit**

```bash
git add modules/hotkeys.lua tests/hotkeys_test.lua tests/system_events_test.lua
git commit -m "Add hotkey feature lifecycle"
```

### Task 2: Give system events an idempotent lifecycle

**Files:**
- Modify: `modules/system_events.lua:1-46`
- Modify: `tests/system_events_test.lua`

**Interfaces:**
- Consumes: `media.pauseAll()` and `hs.caffeinate.watcher.new(callback)`.
- Produces: `systemEvents.start() -> nil`, `systemEvents.stop() -> nil`, and `systemEvents.isRunning() -> boolean`.

- [ ] **Step 1: Rewrite stale tests around the active responsibility**

Update `tests/system_events_test.lua` so its watcher stub counts `start()` and `stop()`. Preserve assertions that the three pause-triggering events call `media.pauseAll()` with the two-second debounce, remove every retired Bluetooth sleep assertion and stub, then assert: two `start()` calls construct/start one watcher; `stop()` stops it once and makes `isRunning()` false; a second `stop()` is inert; starting again creates a fresh watcher. In a fresh module load, make watcher startup fail and assert the candidate watcher is stopped and `isRunning()` remains false.

- [ ] **Step 2: Run the system-event test to verify lifecycle failure**

Run: `lua tests/system_events_test.lua`

Expected: FAIL because `stop()` and `isRunning()` are missing or duplicate `start()` creates a watcher.

- [ ] **Step 3: Implement the system-event lifecycle**

Make `start()` return early when `watcher` exists and publish the watcher reference only after startup succeeds; clean up and rethrow on startup failure. Add `stop()` to stop and clear the watcher, and `isRunning()` to return `watcher ~= nil`. Remove the unused `modules.bluetooth` dependency and its commented event block; keep media debounce behavior unchanged.

- [ ] **Step 4: Verify the system-event tests**

Run: `lua tests/system_events_test.lua`

Expected: `system events tests passed`.

- [ ] **Step 5: Commit**

```bash
git add modules/system_events.lua tests/system_events_test.lua
git commit -m "Add system event feature lifecycle"
```

### Task 3: Make display-awake shutdown complete and race-safe

**Files:**
- Modify: `modules/display_awake.lua:1-76`
- Modify: `tests/display_awake_test.lua`

**Interfaces:**
- Consumes: `hs.battery.watcher`, `hs.caffeinate.watcher`, `hs.timer`, `hs.caffeinate.set`, and `hs.execute`.
- Produces: `displayAwake.start() -> nil`, `displayAwake.stop() -> nil`, and `displayAwake.isRunning() -> boolean`.

- [ ] **Step 1: Add failing lifecycle and cleanup assertions**

Extend both watcher stubs with counted `stop()` methods. Assert that two `start()` calls create/start one watcher of each type; while a display-sleep timer is pending, `stop()` stops both watchers and the timer, sets `displayIdle` to `false`, and makes `isRunning()` false; a second `stop()` adds no calls; manually invoking the captured stale timer callback after stop does not call `/usr/bin/pmset displaysleepnow`; restarting creates fresh watchers and re-applies AC-power prevention. In a fresh module load, make session-watcher startup fail after the battery watcher starts and assert both candidates are stopped, display prevention is released, and `isRunning()` remains false.

- [ ] **Step 2: Run the display-awake test to verify it fails**

Run: `lua tests/display_awake_test.lua`

Expected: FAIL because lifecycle shutdown and idempotence are missing.

- [ ] **Step 3: Implement display-awake lifecycle cleanup**

Guard `start()` with an explicit module-local running flag, publish the running state only after both watchers start, and roll back candidates plus display prevention before rethrowing any startup error. Add `stop()` that marks the module stopped before cancelling the timer, stops and clears both watchers, resets session/timer request state, and calls the existing state helper to release `displayIdle`. Make the timer callback return immediately when the module is no longer running. Expose `isRunning()` from the running flag.

- [ ] **Step 4: Verify display-awake behavior**

Run: `lua tests/display_awake_test.lua`

Expected: `display awake tests passed`.

- [ ] **Step 5: Commit**

```bash
git add modules/display_awake.lua tests/display_awake_test.lua
git commit -m "Add display awake feature lifecycle"
```

### Task 4: Add persistent, failure-isolated feature management

**Files:**
- Create: `modules/feature_manager.lua`
- Create: `tests/feature_manager_test.lua`

**Interfaces:**
- Consumes: lifecycle modules from Tasks 1–3, `hs.settings.get(key)`, `hs.settings.set(key, boolean)`, `hs.logger.new("feature_manager")`, and `hs.alert.show(message)`.
- Produces: `featureManager.start() -> nil`, `featureManager.list() -> { { id: string, title: string, enabled: boolean } }`, `featureManager.isEnabled(id: string) -> boolean|nil`, and `featureManager.setEnabled(id: string, enabled: boolean) -> boolean, string|nil`.

- [ ] **Step 1: Write failing registry/default tests**

In `tests/feature_manager_test.lua`, inject lifecycle stubs through `package.loaded`. Drive the manager through the following ordered definitions, verifying their IDs and titles through `list()`, their defaults through startup calls, and their setting keys through persisted reads and writes:

```lua
{
  { id = "hotkeys", title = "快捷键", default = true, setting = "hammerspoon_feature_hotkeys" },
  { id = "system_events", title = "锁屏/睡眠时暂停音乐", default = true, setting = "hammerspoon_feature_system_events" },
  { id = "display_awake", title = "显示器常亮", default = false, setting = "hammerspoon_feature_display_awake" },
}
```

Test `nil` settings use defaults, saved `false` remains false, and a non-boolean saved value falls back to the default. Verify `list()` reports each stub's actual `isRunning()` value.

- [ ] **Step 2: Write failing toggle and failure-isolation tests**

Assert a successful `setEnabled("display_awake", true)` starts the module and saves `true`; disabling stops and saves `false`; an unknown ID returns `false` plus an error without writing settings. Make one lifecycle stub throw and assert the manager logs, alerts, returns failure, does not persist that request, and continues initializing the other two features.

- [ ] **Step 3: Run the feature-manager test to verify it fails**

Run: `lua tests/feature_manager_test.lua`

Expected: FAIL because `modules.feature_manager` does not exist.

- [ ] **Step 4: Implement the feature manager**

Create the static ordered definitions above. `start()` resolves only boolean settings, applies each feature independently through `pcall`, and continues after errors. `setEnabled()` validates the ID, invokes `start()` or `stop()` through the same failure boundary, persists only after success, and returns `(true, nil)` or `(false, message)`. `list()` must ask each module for live state on every call.

- [ ] **Step 5: Verify the feature-manager tests**

Run: `lua tests/feature_manager_test.lua`

Expected: `feature manager tests passed`.

- [ ] **Step 6: Commit**

```bash
git add modules/feature_manager.lua tests/feature_manager_test.lua
git commit -m "Add persistent feature manager"
```

### Task 5: Add the dynamic menu bar UI

**Files:**
- Create: `modules/feature_menu.lua`
- Create: `tests/feature_menu_test.lua`

**Interfaces:**
- Consumes: `featureManager.list()`, `featureManager.isEnabled(id)`, and `featureManager.setEnabled(id, enabled)` from Task 4, plus `hs.menubar.new(true, "hammerspoon-feature-menu")`.
- Produces: `featureMenu.start() -> nil`.

- [ ] **Step 1: Write the failing menu test**

Stub `modules.feature_manager` and `hs.menubar`. Assert `start()` creates one menu bar object even when called twice, sets title `HS`, sets tooltip `Hammerspoon 功能开关`, and installs a function-valued menu provider. Call the provider and assert the three returned item titles and `checked` values match `featureManager.list()`.

- [ ] **Step 2: Add live-state click assertions**

Change the manager stub's state after the menu table is generated, invoke a menu item's callback, and assert it calls `setEnabled(id, not currentState)` using the manager's latest state. Call the provider again and assert its checkmark reflects the changed state.

- [ ] **Step 3: Run the menu test to verify it fails**

Run: `lua tests/feature_menu_test.lua`

Expected: FAIL because `modules.feature_menu` does not exist.

- [ ] **Step 4: Implement the menu module**

Keep the `hs.menubar` object in module scope so it remains alive. Make `start()` idempotent, configure the exact autosave name/title/tooltip above, and pass `setMenu()` a provider that maps the manager's ordered live list to checkable callback items. Do not reload Hammerspoon in any callback.

- [ ] **Step 5: Verify the menu tests**

Run: `lua tests/feature_menu_test.lua`

Expected: `feature menu tests passed`.

- [ ] **Step 6: Commit**

```bash
git add modules/feature_menu.lua tests/feature_menu_test.lua
git commit -m "Add feature toggle menu"
```

### Task 6: Route startup through the manager and document the menu

**Files:**
- Modify: `init.lua:1-11`
- Modify: `tests/init_test.lua`
- Modify: `README.md`

**Interfaces:**
- Consumes: `featureManager.start()` from Task 4 and `featureMenu.start()` from Task 5.
- Produces: a startup path that initializes managed features before the menu and still shows `Hammerspoon config loaded`.

- [ ] **Step 1: Replace the stale init test**

Stub `modules.feature_manager` and `modules.feature_menu`, run `dofile("init.lua")`, and assert the manager and menu each start once in that order and the existing alert text is shown once. Remove every battery/caffeinate assertion; display-awake default behavior now belongs to `tests/feature_manager_test.lua`.

- [ ] **Step 2: Run the init test to verify it fails**

Run: `lua tests/init_test.lua`

Expected: FAIL because `init.lua` still requires and starts feature modules directly.

- [ ] **Step 3: Simplify `init.lua`**

Require only `modules.feature_manager` and `modules.feature_menu`, call their `start()` methods in that order, and retain `hs.alert.show("Hammerspoon config loaded")`. This intentionally replaces the user's current commented display-awake wiring with the persisted default-off registry entry.

- [ ] **Step 4: Document menu behavior**

Update `README.md` to explain the `HS` menu, the three switches, immediate effect, persistent state, and first-run defaults. Remove claims that configuration files automatically reload while `config_reloader` remains disabled.

- [ ] **Step 5: Run the complete automated suite**

Run: `for test_file in tests/*_test.lua; do lua "$test_file" || exit 1; done`

Expected: all seven test files print their success message and the command exits 0.

- [ ] **Step 6: Run Lua syntax validation**

Run: `for lua_file in init.lua modules/*.lua tests/*.lua; do luac -p "$lua_file" || exit 1; done`

Expected: no output and exit 0.

- [ ] **Step 7: Review the final diff for scope and whitespace errors**

Run: `git diff --check && git status --short`

Expected: no whitespace errors; only the planned source, test, README, and plan-related files are changed. The implementation must not overwrite unrelated user changes.

- [ ] **Step 8: Commit**

```bash
git add init.lua tests/init_test.lua README.md
git commit -m "Use persistent feature toggle menu"
```

### Task 7: Perform manual Hammerspoon acceptance

**Files:**
- No source changes expected.

**Interfaces:**
- Consumes: the completed startup path and menu.
- Produces: runtime evidence that the native Hammerspoon integration matches the unit-tested behavior.

- [ ] **Step 1: Reload the Hammerspoon configuration once**

Use the Hammerspoon app's Reload Config action. Expected: the `HS` menu appears and Hammerspoon shows `Hammerspoon config loaded` without a console error.

- [ ] **Step 2: Exercise all three toggles**

Open `HS`, toggle each feature off and on, reopen the menu after each click, and confirm the checkmark changes immediately. For display awake, finish with the user's intended state: off.

- [ ] **Step 3: Verify persistence**

Reload Hammerspoon again. Expected: all three checkmarks retain the selections from Step 2, with display awake still off.

- [ ] **Step 4: Record any environment-only limitation**

If UI control or Hammerspoon accessibility access is unavailable, report the exact unverified manual steps; do not claim runtime acceptance from unit tests alone.
