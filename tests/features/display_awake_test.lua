local caffeinateCalls = {}
local executeCalls = {}
local powerSource = "AC Power"
local batteryWatchers = {}
local sessionWatchers = {}
local timerCallbacks = {}
local timerDelays = {}
local timers = {}
local sessionWatcherStartShouldFail = false

local function newWatcher(callback, shouldFail)
	local watcher = {
		callback = callback,
		startCount = 0,
		stopCount = 0,
	}
	function watcher:start()
		self.startCount = self.startCount + 1
		if shouldFail() then
			error("watcher start failed")
		end
	end
	function watcher:stop()
		self.stopCount = self.stopCount + 1
	end
	return watcher
end

local function lastCaffeinateEnabled()
	return caffeinateCalls[#caffeinateCalls].enabled
end

hs = {
	battery = {
		powerSourceType = function()
			return powerSource
		end,
		watcher = {
			new = function(callback)
				local watcher = newWatcher(callback, function() return false end)
				table.insert(batteryWatchers, watcher)
				return watcher
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
				local watcher = newWatcher(callback, function() return sessionWatcherStartShouldFail end)
				table.insert(sessionWatchers, watcher)
				return watcher
			end,
		},
	},
	execute = function(command)
		table.insert(executeCalls, command)
	end,
	timer = {
		doAfter = function(delay, callback)
			local timer = { stopCount = 0 }
			function timer:stop()
				self.stopCount = self.stopCount + 1
			end
			table.insert(timerDelays, delay)
			table.insert(timerCallbacks, callback)
			table.insert(timers, timer)
			return timer
		end,
	},
}

local displayAwake = require("features.display_awake")
assert(displayAwake.isRunning() == false)

displayAwake.start()
assert(displayAwake.isRunning() == true)
assert(#caffeinateCalls == 1)
assert(caffeinateCalls[1].sleepType == "displayIdle")
assert(caffeinateCalls[1].enabled == true)
assert(#batteryWatchers == 1)
assert(batteryWatchers[1].startCount == 1)
assert(#sessionWatchers == 1)
assert(sessionWatchers[1].startCount == 1)

displayAwake.start()
assert(#batteryWatchers == 1, "repeated start should not create battery watchers")
assert(#sessionWatchers == 1, "repeated start should not create session watchers")
assert(#caffeinateCalls == 1)

powerSource = "Battery Power"
batteryWatchers[1].callback()
assert(lastCaffeinateEnabled() == false)

powerSource = "AC Power"
batteryWatchers[1].callback()
assert(lastCaffeinateEnabled() == true)

sessionWatchers[1].callback(hs.caffeinate.watcher.sessionDidResignActive)
sessionWatchers[1].callback(hs.caffeinate.watcher.screensDidLock)
assert(#timerCallbacks == 1)
assert(timerDelays[1] == 10)

sessionWatchers[1].callback(hs.caffeinate.watcher.screensDidLock)
assert(#timerCallbacks == 1, "repeated lock should not schedule another timer")

timerCallbacks[1]()
assert(lastCaffeinateEnabled() == false)
assert(#executeCalls == 1)
assert(executeCalls[1] == "/usr/bin/pmset displaysleepnow")

batteryWatchers[1].callback()
assert(lastCaffeinateEnabled() == false, "inactive session should stay unprevented")

sessionWatchers[1].callback(hs.caffeinate.watcher.screensDidUnlock)
assert(lastCaffeinateEnabled() == true)

sessionWatchers[1].callback(hs.caffeinate.watcher.sessionDidResignActive)
sessionWatchers[1].callback(hs.caffeinate.watcher.screensDidLock)
assert(#timerCallbacks == 2)

displayAwake.stop()
assert(displayAwake.isRunning() == false)
assert(batteryWatchers[1].stopCount == 1)
assert(sessionWatchers[1].stopCount == 1)
assert(timers[2].stopCount == 1)
assert(lastCaffeinateEnabled() == false)

local callsAfterStop = #caffeinateCalls
timerCallbacks[2]()
assert(#executeCalls == 1, "stale timer should not request display sleep")
assert(#caffeinateCalls == callsAfterStop, "stale timer should not change prevention")

batteryWatchers[1].callback()
sessionWatchers[1].callback(hs.caffeinate.watcher.screensDidUnlock)
sessionWatchers[1].callback(hs.caffeinate.watcher.screensDidLock)
assert(#caffeinateCalls == callsAfterStop, "stale watcher callbacks should not change prevention")
assert(#timerCallbacks == 2, "stale watcher callbacks should not schedule timers")

displayAwake.stop()
assert(batteryWatchers[1].stopCount == 1)
assert(sessionWatchers[1].stopCount == 1)
assert(timers[2].stopCount == 1)
assert(#caffeinateCalls == callsAfterStop)

displayAwake.start()
assert(displayAwake.isRunning() == true)
assert(#batteryWatchers == 2)
assert(#sessionWatchers == 2)
assert(lastCaffeinateEnabled() == true)
displayAwake.stop()
assert(batteryWatchers[2].stopCount == 1)
assert(sessionWatchers[2].stopCount == 1)
assert(lastCaffeinateEnabled() == false)

package.loaded["features.display_awake"] = nil
sessionWatcherStartShouldFail = true
local failingDisplayAwake = require("features.display_awake")
local startOk = pcall(failingDisplayAwake.start)
assert(startOk == false, "partial watcher startup should fail")
assert(batteryWatchers[3].stopCount == 1)
assert(sessionWatchers[3].stopCount == 1)
assert(lastCaffeinateEnabled() == false, "failed startup should release display prevention")
assert(failingDisplayAwake.isRunning() == false)

print("display awake tests passed")
