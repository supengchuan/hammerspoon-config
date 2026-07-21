local bluetoothCalls = {}
local bindings = {}
local systemEventCallback
local now = 10
local pauseShouldFail = false
local powerSource = "AC Power"

package.loaded["modules.media"] = {
	pauseAll = function()
		if pauseShouldFail then
			error("media pause failed")
		end
	end,
}
package.loaded["modules.bluetooth"] = {
	setEnabled = function(enabled)
		table.insert(bluetoothCalls, enabled)
	end,
	toggle = function() end,
}

hs = {
	battery = { powerSourceType = function() return powerSource end },
	timer = { secondsSinceEpoch = function() return now end },
	caffeinate = {
		watcher = {
			systemWillSleep = "systemWillSleep",
			systemDidWake = "systemDidWake",
			new = function(callback)
				systemEventCallback = callback
				return { start = function() end }
			end,
		},
	},
	hotkey = {
		bind = function(modifiers, key, callback)
			table.insert(bindings, { modifiers = modifiers, key = key, callback = callback })
		end,
	},
}

local systemEvents = require("modules.system_events")
systemEvents.start()

local function resetBluetoothCalls()
	bluetoothCalls = {}
end

powerSource = "AC Power"
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
assert(#bluetoothCalls == 0)

resetBluetoothCalls()
powerSource = "Battery Power"
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
assert(#bluetoothCalls == 1)
assert(bluetoothCalls[1] == false)

resetBluetoothCalls()
powerSource = "Off Line"
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
assert(#bluetoothCalls == 1)
assert(bluetoothCalls[1] == false)

resetBluetoothCalls()
systemEventCallback(hs.caffeinate.watcher.systemDidWake)
assert(#bluetoothCalls == 1)
assert(bluetoothCalls[1] == true)

-- A media failure must not suppress the battery-powered sleep Bluetooth action.
now = 13
pauseShouldFail = true
powerSource = "Battery Power"
resetBluetoothCalls()
local ok = pcall(systemEventCallback, hs.caffeinate.watcher.systemWillSleep)
assert(ok == false)
assert(#bluetoothCalls == 1)
assert(bluetoothCalls[1] == false)

local bluetooth = require("modules.bluetooth")
local hotkeys = require("modules.hotkeys")
hotkeys.bindAll()

local bluetoothBinding
for _, binding in ipairs(bindings) do
	if binding.key == "B" then
		bluetoothBinding = binding
		break
	end
end

assert(bluetoothBinding ~= nil)
assert(#bluetoothBinding.modifiers == 2)
assert(bluetoothBinding.modifiers[1] == "ctrl")
assert(bluetoothBinding.modifiers[2] == "cmd")
assert(bluetoothBinding.callback == bluetooth.toggle)
print("system events tests passed")
