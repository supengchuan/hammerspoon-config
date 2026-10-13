local M = {}
local batteryWatcher
local sessionWatcher
local sessionActive = true
local displayIdlePrevented
local displaySleepRequested = false
local displaySleepTimer
local running = false

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
		if not running then
			return
		end

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
	if running then
		return
	end

	sessionActive = true
	displaySleepRequested = false

	local batteryCandidate
	local sessionCandidate
	local ok, err = pcall(function()
		syncDisplayIdlePrevention()

		batteryCandidate = hs.battery.watcher.new(syncDisplayIdlePrevention)
		batteryCandidate:start()

		sessionCandidate = hs.caffeinate.watcher.new(handleSessionEvent)
		sessionCandidate:start()
	end)

	if not ok then
		if sessionCandidate then
			pcall(function()
				sessionCandidate:stop()
			end)
		end
		if batteryCandidate then
			pcall(function()
				batteryCandidate:stop()
			end)
		end
		cancelDisplaySleepTimer()
		sessionActive = true
		displaySleepRequested = false
		setDisplayIdlePrevented(false)
		error(err, 0)
	end

	batteryWatcher = batteryCandidate
	sessionWatcher = sessionCandidate
	running = true
end

function M.stop()
	if not running then
		return
	end

	running = false
	cancelDisplaySleepTimer()

	local battery = batteryWatcher
	local session = sessionWatcher
	batteryWatcher = nil
	sessionWatcher = nil

	local stopError
	if battery then
		local ok, err = pcall(function()
			battery:stop()
		end)
		if not ok then
			stopError = err
		end
	end
	if session then
		local ok, err = pcall(function()
			session:stop()
		end)
		if not ok and not stopError then
			stopError = err
		end
	end

	sessionActive = true
	displaySleepRequested = false
	setDisplayIdlePrevented(false)

	if stopError then
		error(stopError, 0)
	end
end

function M.isRunning()
	return running
end

return M
