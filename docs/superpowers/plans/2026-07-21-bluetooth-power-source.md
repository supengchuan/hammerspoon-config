# Bluetooth Power Source Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Bluetooth off before sleep only when the Mac is on battery or offline power.

**Architecture:** The existing system-event module reads `hs.battery.powerSourceType()` at the sleep boundary. It calls the existing Bluetooth module only for `Battery Power` and `Off Line`; wake handling remains unchanged.

**Tech Stack:** Hammerspoon Lua, `hs.battery`, existing Lua test scripts, `luac`.

## Global Constraints

- `Battery Power` and `Off Line` must call `bluetooth.setEnabled(false)` at `systemWillSleep`.
- `AC Power` must not call the Bluetooth module at `systemWillSleep`.
- `systemDidWake` must continue to call `bluetooth.setEnabled(true)` unconditionally.
- Existing media-pause behavior and the `Ctrl + Cmd + B` shortcut must remain unchanged.

---

### Task 1: Gate sleep Bluetooth shutdown by power source

**Files:**

- Modify: `modules/system_events.lua`
- Modify: `tests/system_events_test.lua`
- Modify: `README.md`

**Interfaces:**

- Consumes: `hs.battery.powerSourceType() -> "AC Power" | "Battery Power" | "Off Line"`.
- Consumes: `bluetooth.setEnabled(enabled: boolean)`.
- Produces: a sleep handler that disables Bluetooth only off AC power.

- [ ] **Step 1: Write the failing power-source test**

In `tests/system_events_test.lua`, extend the `hs` substitute with:

```lua
battery = { powerSourceType = function() return powerSource end },
```

Initialize `local powerSource = "AC Power"`. Replace the initial sleep assertion with these three independently reset cases:

```lua
powerSource = "AC Power"
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
assert(#bluetoothCalls == 0)

powerSource = "Battery Power"
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
assert(bluetoothCalls[1] == false)

powerSource = "Off Line"
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
assert(bluetoothCalls[2] == false)
```

Keep the existing wake assertion, adjusted so its expected call is the third recorded call and equals `true`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `lua tests/system_events_test.lua`

Expected: failure at the AC-power assertion because current code closes Bluetooth unconditionally on every sleep.

- [ ] **Step 3: Implement the conditional sleep behavior**

In `modules/system_events.lua`, replace the existing sleep action with:

```lua
if event == hs.caffeinate.watcher.systemWillSleep then
  local powerSource = hs.battery.powerSourceType()
  if powerSource == "Battery Power" or powerSource == "Off Line" then
    bluetooth.setEnabled(false)
  end
elseif event == hs.caffeinate.watcher.systemDidWake then
  bluetooth.setEnabled(true)
end
```

Update README’s automatic-behavior bullet to state that Bluetooth is closed only on battery or offline power and is retained on AC power.

- [ ] **Step 4: Run complete verification**

Run:

```bash
lua tests/system_events_test.lua
lua tests/bluetooth_test.lua
luac -p init.lua modules/*.lua tests/system_events_test.lua tests/bluetooth_test.lua
git diff --check
```

Expected: both test scripts print their success messages; syntax and whitespace checks produce no output.

- [ ] **Step 5: Commit**

```bash
git add modules/system_events.lua tests/system_events_test.lua README.md
git commit -m "Respect power source before disabling Bluetooth"
```

