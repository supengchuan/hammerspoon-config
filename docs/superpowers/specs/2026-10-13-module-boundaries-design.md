# Lua Module Boundaries Design

## Goal

Replace the generic `modules/` bucket with stable responsibility boundaries that make new features predictable to add and keep dependencies one-directional.

## Structure

```text
init.lua
feature.lua                 # local, ignored enablement configuration
feature.example.lua

core/
  feature_manager.lua       # feature lifecycle and enablement orchestration

features/
  hotkeys.lua               # user-switchable feature
  system_events.lua         # user-switchable feature
  display_awake.lua         # user-switchable feature

actions/
  apps.lua                  # reusable application operations
  bluetooth.lua             # reusable Bluetooth operations
  media.lua                 # reusable media operations
  mouse.lua                 # reusable pointer operations
  window.lua                # reusable window operations

tests/
  core/
  features/
  actions/
```

The test tree mirrors the source boundary. It does not need placeholder directories; only existing tests are moved.

## Boundary Rules

Dependencies flow in one direction:

```text
init.lua -> core -> features -> actions
```

- `core` owns feature registration, enablement and lifecycle. It must not contain user-facing behavior.
- `features` contains complete capabilities that can be enabled from `feature.lua`.
- `actions` contains reusable operations. An action must not know which feature invokes it or whether that feature is enabled.
- `actions` must not import `features` or `core`; `features` must not import `core`.
- A feature remains one file until it has multiple private implementation files. Only then does it become `features/<name>/init.lua`; shared operations still belong in `actions`.
- `feature.lua` and `feature.example.lua` remain at the repository root because they are user-facing configuration, not implementation modules.

## Migration

- Move each existing file to the matching responsibility directory.
- Update all `require` paths without changing runtime behavior or public module APIs.
- Move tests to mirror their source layer and update test module paths.
- Remove `modules/config_reloader.lua`: it is not reachable from the runtime and preserving dead code would weaken the new boundary.
- Update README paths and architecture documentation.
- Remove the empty `modules/` directory after migration.

## Verification

- All existing Lua tests pass from their new paths.
- Every tracked Lua file parses successfully.
- Repository search over active runtime source, tests and README finds no remaining `modules.` imports or references to `modules/`. Historical design and implementation records are not rewritten.
- With local `feature.lua`, Hammerspoon reloads with the same enabled and disabled feature state as before the migration.
- With `feature.lua` absent, no feature starts, preserving the current opt-in behavior.

## Non-goals

- No feature behavior, hotkey, event policy or configuration schema changes.
- No framework-like registry or automatic module discovery.
- No directory per feature until the feature actually needs private supporting files.
