# Bluetooth Control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Bluetooth off before sleep, on after wake, and toggle it with `Ctrl + Cmd + B`.

**Architecture:** `modules/bluetooth.lua` owns the installed `blueutil` command. The existing event watcher and hotkey module call this interface rather than executing shell commands directly.

**Tech Stack:** Hammerspoon Lua, `/opt/homebrew/bin/blueutil` v2.13.0, Lua interpreter and `luac`.

## Global Constraints

- Use the installed absolute binary path `/opt/homebrew/bin/blueutil`.
- Sleep unconditionally runs `blueutil --power off`; wake unconditionally runs `blueutil --power on`.
- `Ctrl + Cmd + B` toggles based on current power state.
- Failed commands log through `hs.logger` and never show a success alert.

---

### Task 1: Bluetooth module with executable tests

**Files:**

- Create: `tests/bluetooth_test.lua`
- Create: `modules/bluetooth.lua`

**Interfaces:**

- Produces: `isOn() -> boolean|nil`, `setEnabled(enabled: boolean) -> boolean`, `toggle() -> boolean`.
- Consumes: `hs.execute(command) -> output, success`; `hs.alert.show(message)`; `hs.logger.new(name)`.

- [ ] **Step 1: Write the failing test**

Create `tests/bluetooth_test.lua` with an `hs` substitute that records commands and alerts:

```lua
local calls, alerts = {}, {}
hs = {
  execute = function(command)
    table.insert(calls, command)
    if command:find("--power$") then return "1\n", true end
    return "", true
  end,
  alert = { show = function(message) table.insert(alerts, message) end },
  logger = { new = function() return { e = function() end } end },
}

local bluetooth = require("modules.bluetooth")
assert(bluetooth.isOn() == true)
assert(bluetooth.setEnabled(false) == true)
assert(calls[2] == "/opt/homebrew/bin/blueutil --power off")
assert(bluetooth.toggle() == true)
assert(calls[4] == "/opt/homebrew/bin/blueutil --power off")
assert(alerts[1] == "Bluetooth turned off")
print("bluetooth tests passed")
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `lua tests/bluetooth_test.lua`

Expected: failure stating that `modules.bluetooth` cannot be found.

- [ ] **Step 3: Write the minimal implementation**

Create `modules/bluetooth.lua`:

```lua
local M = {}
local executable = "/opt/homebrew/bin/blueutil"
local logger = hs.logger.new("bluetooth")

local function execute(arguments)
  local output, success = hs.execute(executable .. " " .. arguments)
  if not success then logger.e("blueutil failed: " .. arguments) end
  return output, success
end

function M.isOn()
  local output, success = execute("--power")
  if not success then return nil end
  if output:match("^1%s*$") then return true end
  if output:match("^0%s*$") then return false end
  logger.e("unexpected blueutil power state: " .. output)
  return nil
end

function M.setEnabled(enabled)
  local _, success = execute("--power " .. (enabled and "on" or "off"))
  return success
end

function M.toggle()
  local isOn = M.isOn()
  if isOn == nil then return false end
  local enabled = not isOn
  if not M.setEnabled(enabled) then return false end
  hs.alert.show("Bluetooth turned " .. (enabled and "on" or "off"))
  return true
end

return M
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `lua tests/bluetooth_test.lua`

Expected: `bluetooth tests passed`.

- [ ] **Step 5: Commit**

```bash
git add modules/bluetooth.lua tests/bluetooth_test.lua
git commit -m "Add Bluetooth control module"
```

### Task 2: Connect system events and hotkey

**Files:**

- Modify: `modules/system_events.lua`
- Modify: `modules/hotkeys.lua`
- Modify: `README.md`
- Test: `tests/bluetooth_test.lua`

**Interfaces:**

- Consumes: `bluetooth.setEnabled(false|true)` and `bluetooth.toggle()`.
- Produces: Bluetooth controls are reachable from system sleep/wake and the hotkey.

- [ ] **Step 1: Write an integration test that initially fails**

Create `tests/system_events_test.lua`. Provide substitutions for `modules.media`, `modules.bluetooth`, and `hs.caffeinate.watcher`; load `modules.system_events`; invoke the captured callback with `systemWillSleep` and `systemDidWake`; assert calls equal `{ false, true }`. Stub `hs.hotkey.bind`, load `modules.hotkeys`, and assert one recorded binding has modifiers `{ "ctrl", "cmd" }`, key `"B"`, and callback `bluetooth.toggle`.

- [ ] **Step 2: Run the integration test to verify it fails**

Run: `lua tests/system_events_test.lua`

Expected: failure because neither consumer yet requires or calls `modules.bluetooth`.

- [ ] **Step 3: Wire the consumers**

At the top of `modules/system_events.lua`, add `local bluetooth = require("modules.bluetooth")`. In `handleEvent`, retain pause behavior and add:

```lua
if event == hs.caffeinate.watcher.systemWillSleep then
  bluetooth.setEnabled(false)
elseif event == hs.caffeinate.watcher.systemDidWake then
  bluetooth.setEnabled(true)
end
```

At the top of `modules/hotkeys.lua`, add `local bluetooth = require("modules.bluetooth")`; add:

```lua
hs.hotkey.bind({ "ctrl", "cmd" }, "B", bluetooth.toggle)
```

Update README with the new shortcut and sleep/wake Bluetooth behavior.

- [ ] **Step 4: Verify behavior and syntax**

Run:

```bash
lua tests/bluetooth_test.lua
lua tests/system_events_test.lua
luac -p init.lua modules/*.lua tests/bluetooth_test.lua tests/system_events_test.lua
git diff --check
```

Expected: test success and no syntax or whitespace errors.

- [ ] **Step 5: Commit**

```bash
git add modules/system_events.lua modules/hotkeys.lua README.md tests/system_events_test.lua
git commit -m "Automate Bluetooth during sleep and wake"
```
