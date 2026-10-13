local bluetoothCalls = {}
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

print("system events tests passed")
