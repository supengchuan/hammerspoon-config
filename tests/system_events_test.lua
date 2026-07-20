local bluetoothCalls = {}
local bindings = {}
local systemEventCallback

package.loaded["modules.media"] = {
	pauseAll = function() end,
}
package.loaded["modules.bluetooth"] = {
	setEnabled = function(enabled)
		table.insert(bluetoothCalls, enabled)
	end,
	toggle = function() end,
}

hs = {
	timer = { secondsSinceEpoch = function() return 10 end },
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
systemEventCallback(hs.caffeinate.watcher.systemWillSleep)
systemEventCallback(hs.caffeinate.watcher.systemDidWake)

assert(#bluetoothCalls == 2)
assert(bluetoothCalls[1] == false)
assert(bluetoothCalls[2] == true)

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
