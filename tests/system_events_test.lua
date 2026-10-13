local now = 10
local pauseCalls = 0
local pauseShouldFail = false
local watcherStartShouldFail = false
local watchers = {}

package.loaded["modules.media"] = {
	pauseAll = function()
		pauseCalls = pauseCalls + 1
		if pauseShouldFail then
			error("media pause failed")
		end
	end,
}

hs = {
	timer = { secondsSinceEpoch = function() return now end },
	caffeinate = {
		watcher = {
			systemWillSleep = "systemWillSleep",
			sessionDidResignActive = "sessionDidResignActive",
			screensDidLock = "screensDidLock",
			new = function(callback)
				local watcher = {
					callback = callback,
					startCount = 0,
					stopCount = 0,
				}
				function watcher:start()
					self.startCount = self.startCount + 1
					if watcherStartShouldFail then
						error("watcher start failed")
					end
				end
				function watcher:stop()
					self.stopCount = self.stopCount + 1
				end
				table.insert(watchers, watcher)
				return watcher
			end,
		},
	},
}

local systemEvents = require("modules.system_events")

systemEvents.start()
assert(systemEvents.isRunning() == true)
assert(#watchers == 1)
assert(watchers[1].startCount == 1)

systemEvents.start()
assert(#watchers == 1, "repeated start should not create another watcher")
assert(watchers[1].startCount == 1)

watchers[1].callback(hs.caffeinate.watcher.sessionDidResignActive)
assert(pauseCalls == 1)

watchers[1].callback(hs.caffeinate.watcher.screensDidLock)
watchers[1].callback(hs.caffeinate.watcher.systemWillSleep)
assert(pauseCalls == 1, "related lock events should be debounced")

now = 13
watchers[1].callback(hs.caffeinate.watcher.systemWillSleep)
assert(pauseCalls == 2)

now = 16
pauseShouldFail = true
local callbackOk = pcall(watchers[1].callback, hs.caffeinate.watcher.systemWillSleep)
assert(callbackOk == false, "media errors should still propagate")
pauseShouldFail = false

systemEvents.stop()
assert(systemEvents.isRunning() == false)
assert(watchers[1].stopCount == 1)

systemEvents.stop()
assert(watchers[1].stopCount == 1, "repeated stop should be inert")

systemEvents.start()
assert(systemEvents.isRunning() == true)
assert(#watchers == 2)
assert(watchers[2].startCount == 1)
systemEvents.stop()
assert(watchers[2].stopCount == 1)

package.loaded["modules.system_events"] = nil
watcherStartShouldFail = true
local failingSystemEvents = require("modules.system_events")
local startOk = pcall(failingSystemEvents.start)
assert(startOk == false, "watcher start failure should propagate")
assert(watchers[3].stopCount == 1, "failed watcher should be cleaned up")
assert(failingSystemEvents.isRunning() == false)

print("system events tests passed")
