# Lua Module Boundaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic `modules/` bucket with enforceable `core/`, `features/`, and `actions/` boundaries without changing runtime behavior.

**Architecture:** Migrate from the dependency leaves upward so every commit remains runnable: reusable actions first, switchable features second, then lifecycle core and entry point. Preserve every module's existing public table and add a structural test that enforces `init -> core -> features -> actions`.

**Tech Stack:** Lua 5.4, Hammerspoon APIs, plain Lua assertion tests, Git

**Spec:** `docs/superpowers/specs/2026-10-13-module-boundaries-design.md`

## Global Constraints

- `feature.lua` and `feature.example.lua` remain at the repository root.
- Dependencies flow only `init.lua -> core -> features -> actions`.
- Public function names and runtime behavior remain unchanged.
- `modules/config_reloader.lua` is removed because it is unreachable dead code.
- Historical design and implementation records are not rewritten.
- Do not introduce automatic module discovery or per-feature directories.

## Review Focus

- Missing `feature.lua` must still start no features and must still show the load alert; Task 3 retains this entry-point test.
- Only literal Boolean `true` enables a feature; Task 3 retains the manager's strict-value test.
- Moved modules must not pass through stale `package.loaded["modules.*"]` stubs; Tasks 1–3 replace every test stub and require path before moving files.
- `actions` must never import `features` or `core`, and `features` must never import `core`; Task 4 pins both constraints in an architecture test.
- A Hammerspoon reload must produce feature running states equal to the local `feature.lua` values, including the all-disabled missing-file case; Task 4 performs this runtime smoke check.

---

### Task 1: Separate reusable actions

**Files:**
- Move: `modules/apps.lua` -> `actions/apps.lua`
- Move: `modules/bluetooth.lua` -> `actions/bluetooth.lua`
- Move: `modules/media.lua` -> `actions/media.lua`
- Move: `modules/mouse.lua` -> `actions/mouse.lua`
- Move: `modules/window.lua` -> `actions/window.lua`
- Modify: `modules/hotkeys.lua:1-4`
- Modify: `modules/system_events.lua:1`
- Move and modify: `tests/bluetooth_test.lua` -> `tests/actions/bluetooth_test.lua`
- Modify: `tests/hotkeys_test.lua:18-21`
- Modify: `tests/system_events_test.lua:7`

**Interfaces:**
- Consumes: existing action module tables and function names unchanged.
- Produces: `actions.apps`, `actions.bluetooth`, `actions.media`, `actions.mouse`, and `actions.window` for feature modules.

- [ ] **Step 1: Point tests and consumers at the new action namespace**

Replace only module identifiers: `modules.apps`, `modules.bluetooth`, `modules.media`, `modules.mouse`, and `modules.window` become their `actions.*` equivalents in the listed consumers and tests.

- [ ] **Step 2: Run the action test before moving files**

Run: `lua tests/bluetooth_test.lua`

Expected: FAIL because `actions.bluetooth` does not exist yet.

- [ ] **Step 3: Move the five action modules and Bluetooth test**

Create `actions/` and `tests/actions/`, then use `git mv` for the files listed above. Do not alter action implementations or exports.

- [ ] **Step 4: Run all affected tests**

Run: `lua tests/actions/bluetooth_test.lua && lua tests/hotkeys_test.lua && lua tests/system_events_test.lua`

Expected: all three print their pass messages and exit 0.

- [ ] **Step 5: Commit the action boundary**

```bash
git add actions modules/hotkeys.lua modules/system_events.lua tests
git commit -m "refactor: separate reusable actions"
```

### Task 2: Group switchable features

**Files:**
- Move: `modules/hotkeys.lua` -> `features/hotkeys.lua`
- Move: `modules/system_events.lua` -> `features/system_events.lua`
- Move: `modules/display_awake.lua` -> `features/display_awake.lua`
- Modify: `modules/feature_manager.lua:1-3`
- Move and modify: `tests/hotkeys_test.lua` -> `tests/features/hotkeys_test.lua`
- Move and modify: `tests/system_events_test.lua` -> `tests/features/system_events_test.lua`
- Move and modify: `tests/display_awake_test.lua` -> `tests/features/display_awake_test.lua`
- Modify: `tests/feature_manager_test.lua:39-41`

**Interfaces:**
- Consumes: action modules from Task 1.
- Produces: `features.hotkeys`, `features.system_events`, and `features.display_awake`, each retaining `start()`, `stop()`, and `isRunning()`.

- [ ] **Step 1: Point tests and the manager at the new feature namespace**

Replace `modules.hotkeys`, `modules.system_events`, and `modules.display_awake` with their `features.*` equivalents in all listed files, including `package.loaded` resets and stubs.

- [ ] **Step 2: Run a feature test before moving files**

Run: `lua tests/hotkeys_test.lua`

Expected: FAIL because `features.hotkeys` does not exist yet.

- [ ] **Step 3: Move the three feature modules and their tests**

Create `features/` and `tests/features/`, then use `git mv` for the files listed above. Do not change lifecycle behavior.

- [ ] **Step 4: Run feature and manager tests**

Run: `lua tests/features/hotkeys_test.lua && lua tests/features/system_events_test.lua && lua tests/features/display_awake_test.lua && lua tests/feature_manager_test.lua`

Expected: all four print their pass messages and exit 0.

- [ ] **Step 5: Commit the feature boundary**

```bash
git add features modules/feature_manager.lua tests
git commit -m "refactor: group switchable features"
```

### Task 3: Isolate lifecycle core and remove dead reload code

**Files:**
- Move: `modules/feature_manager.lua` -> `core/feature_manager.lua`
- Modify: `init.lua:1`
- Move and modify: `tests/feature_manager_test.lua` -> `tests/core/feature_manager_test.lua`
- Modify: `tests/init_test.lua:11`
- Delete: `modules/config_reloader.lua`

**Interfaces:**
- Consumes: feature lifecycle modules from Task 2 and the existing local configuration table.
- Produces: `core.feature_manager.start(config)` as the sole entry-point orchestration interface.

- [ ] **Step 1: Point entry-point tests and manager tests at `core.feature_manager`**

Replace both the real `require` target and all `package.loaded` manager keys with `core.feature_manager`; retain the existing missing-file, strict-Boolean, failure-isolation, alert, and logging assertions.

- [ ] **Step 2: Run the manager test before moving the core file**

Run: `lua tests/feature_manager_test.lua`

Expected: FAIL because `core.feature_manager` does not exist yet.

- [ ] **Step 3: Move the manager and its test, update `init.lua`, and delete dead code**

Create `core/` and `tests/core/`, use `git mv` for the manager and test, change `init.lua` to require `core.feature_manager`, and remove `modules/config_reloader.lua` with `git rm`. The now-empty `modules/` directory disappears.

- [ ] **Step 4: Run core and entry-point tests**

Run: `lua tests/core/feature_manager_test.lua && lua tests/init_test.lua`

Expected: both print their pass messages and exit 0; the init test verifies both present and missing `feature.lua` behavior.

- [ ] **Step 5: Commit the core boundary**

```bash
git add core init.lua tests
git commit -m "refactor: isolate feature lifecycle core"
```

### Task 4: Enforce and document the architecture

**Files:**
- Create: `tests/architecture_test.lua`
- Modify: `README.md:26`
- Modify: `README.md` architecture section

**Interfaces:**
- Consumes: final directory layout from Tasks 1–3.
- Produces: an executable boundary contract and accurate user documentation.

- [ ] **Step 1: Write the failing architecture test**

Create `tests/architecture_test.lua` using standard Lua file/process APIs. It must:

- scan `init.lua`, `README.md`, and Lua files beneath `actions/`, `core/`, `features/`, and `tests/`;
- reject literal legacy `modules.` imports and `modules/` paths without embedding those literals contiguously in its own source;
- reject imports of `core.*` or `features.*` from files beneath `actions/`;
- reject imports of `core.*` from files beneath `features/`;
- assert that the `modules/` directory no longer exists;
- print `architecture tests passed` on success.

- [ ] **Step 2: Run the architecture test before updating README**

Run: `lua tests/architecture_test.lua`

Expected: FAIL on README's legacy Bluetooth path.

- [ ] **Step 3: Update README paths and explain the three boundaries**

Change the Bluetooth source path to `actions/bluetooth.lua`. Add a concise structure section defining `core`, `features`, and `actions`, including the allowed dependency direction; do not document implementation details or historical migration.

- [ ] **Step 4: Run the complete static and unit verification**

Run: `find tests -name '*_test.lua' -exec lua {} \;`

Expected: six behavior tests plus the architecture test print pass messages and every process exits 0.

Run: `find . -path './.git' -prune -o -name '*.lua' -exec luac -p {} \;`

Expected: exit 0 with no syntax errors.

Run: `rg -n 'modules[./]' init.lua actions core features tests README.md feature.example.lua`

Expected: exit 1 with no matches.

- [ ] **Step 5: Reload Hammerspoon and compare runtime state to local configuration**

Run `hs -c 'hs.reload()'`, then query each feature module through `hs -c`. When `feature.lua` exists, assert each `isRunning()` equals whether its configuration value is literal `true`; when absent, assert all three are false.

Expected: the assertion command returns `ok`; the native Hammerspoon hammer icon remains the only menu bar icon.

- [ ] **Step 6: Commit the architecture guard and documentation**

```bash
git add README.md tests/architecture_test.lua
git commit -m "test: enforce Lua module boundaries"
```
