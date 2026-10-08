local M = {}
local batteryWatcher
local sessionWatcher
local sessionActive = true
local displayIdlePrevented
local displaySleepRequested = false
local displaySleepTimer

local DISPLAY_SLEEP_DELAY_SECONDS = 10

local function setDisplayIdlePrevented(enabled)
	if displayIdlePrevented == enabled then
		return
	end

	displayIdlePrevented = enabled
	hs.caffeinate.set("displayIdle", enabled)
end

local function syncDisplayIdlePrevention()
	local shouldPrevent = sessionActive and hs.battery.powerSourceType() == "AC Power"
	setDisplayIdlePrevented(shouldPrevent)
end

local function cancelDisplaySleepTimer()
	if not displaySleepTimer then
		return
	end

	displaySleepTimer:stop()
	displaySleepTimer = nil
end

local function scheduleDisplaySleep()
	if displaySleepTimer or displaySleepRequested then
		return
	end

	displaySleepTimer = hs.timer.doAfter(DISPLAY_SLEEP_DELAY_SECONDS, function()
		displaySleepTimer = nil
		if sessionActive then
			return
		end

		setDisplayIdlePrevented(false)
		displaySleepRequested = true
		hs.execute("/usr/bin/pmset displaysleepnow")
	end)
end

local function handleSessionEvent(event)
	if event == hs.caffeinate.watcher.sessionDidResignActive or event == hs.caffeinate.watcher.screensDidLock then
		sessionActive = false

		if event == hs.caffeinate.watcher.screensDidLock then
			scheduleDisplaySleep()
		end
	elseif event == hs.caffeinate.watcher.sessionDidBecomeActive or event == hs.caffeinate.watcher.screensDidUnlock then
		sessionActive = true
		cancelDisplaySleepTimer()
		displaySleepRequested = false
		syncDisplayIdlePrevention()
	end
end

function M.start()
	syncDisplayIdlePrevention()

	batteryWatcher = hs.battery.watcher.new(syncDisplayIdlePrevention)
	batteryWatcher:start()

	sessionWatcher = hs.caffeinate.watcher.new(handleSessionEvent)
	sessionWatcher:start()
end

return M
