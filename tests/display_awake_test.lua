local caffeinateCalls = {}
local executeCalls = {}
local powerSource = "AC Power"
local batteryCallback
local batteryWatcherStartCount = 0
local sessionCallback
local sessionWatcherStartCount = 0
local timerCallbacks = {}
local timerDelays = {}
local stoppedTimerCount = 0

hs = {
	battery = {
		powerSourceType = function()
			return powerSource
		end,
		watcher = {
			new = function(callback)
				batteryCallback = callback
				return {
					start = function()
						batteryWatcherStartCount = batteryWatcherStartCount + 1
					end,
				}
			end,
		},
	},
	caffeinate = {
		set = function(sleepType, enabled)
			table.insert(caffeinateCalls, { sleepType = sleepType, enabled = enabled })
		end,
		watcher = {
			sessionDidResignActive = "sessionDidResignActive",
			sessionDidBecomeActive = "sessionDidBecomeActive",
			screensDidLock = "screensDidLock",
			screensDidUnlock = "screensDidUnlock",
			new = function(callback)
				sessionCallback = callback
				return {
					start = function()
						sessionWatcherStartCount = sessionWatcherStartCount + 1
					end,
				}
			end,
		},
	},
	execute = function(command)
		table.insert(executeCalls, command)
	end,
	timer = {
		doAfter = function(delay, callback)
			table.insert(timerDelays, delay)
			table.insert(timerCallbacks, callback)
			return {
				stop = function()
					stoppedTimerCount = stoppedTimerCount + 1
				end,
			}
		end,
	},
}

local ok, displayAwake = pcall(require, "modules.display_awake")
assert(ok, "modules.display_awake should load")

displayAwake.start()

assert(#caffeinateCalls == 1)
assert(caffeinateCalls[1].sleepType == "displayIdle")
assert(caffeinateCalls[1].enabled == true)

assert(batteryCallback ~= nil, "battery watcher should be registered")
assert(batteryWatcherStartCount == 1)
assert(sessionCallback ~= nil, "session watcher should be registered")
assert(sessionWatcherStartCount == 1)

powerSource = "Battery Power"
batteryCallback()
assert(#caffeinateCalls == 2)
assert(caffeinateCalls[2].sleepType == "displayIdle")
assert(caffeinateCalls[2].enabled == false)

powerSource = "AC Power"
batteryCallback()
assert(#caffeinateCalls == 3)
assert(caffeinateCalls[3].sleepType == "displayIdle")
assert(caffeinateCalls[3].enabled == true)

sessionCallback(hs.caffeinate.watcher.sessionDidResignActive)
assert(#caffeinateCalls == 3)
assert(#executeCalls == 0)

sessionCallback(hs.caffeinate.watcher.screensDidLock)
assert(#caffeinateCalls == 3)
assert(#executeCalls == 0)
assert(#timerCallbacks == 1)
assert(timerDelays[1] == 10)

sessionCallback(hs.caffeinate.watcher.screensDidLock)
assert(#timerCallbacks == 1)
assert(#executeCalls == 0)

timerCallbacks[1]()
assert(#caffeinateCalls == 4)
assert(caffeinateCalls[4].sleepType == "displayIdle")
assert(caffeinateCalls[4].enabled == false)
assert(#executeCalls == 1)
assert(executeCalls[1] == "/usr/bin/pmset displaysleepnow")

batteryCallback()
assert(#caffeinateCalls == 4)

sessionCallback(hs.caffeinate.watcher.screensDidUnlock)
assert(#caffeinateCalls == 5)
assert(caffeinateCalls[5].sleepType == "displayIdle")
assert(caffeinateCalls[5].enabled == true)

sessionCallback(hs.caffeinate.watcher.sessionDidBecomeActive)
assert(#caffeinateCalls == 5)

sessionCallback(hs.caffeinate.watcher.sessionDidResignActive)
sessionCallback(hs.caffeinate.watcher.screensDidLock)
assert(#timerCallbacks == 2)

sessionCallback(hs.caffeinate.watcher.screensDidUnlock)
assert(stoppedTimerCount == 1)
assert(#executeCalls == 1)

timerCallbacks[2]()
assert(#executeCalls == 1)
assert(#caffeinateCalls == 5)

print("display awake tests passed")
