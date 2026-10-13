local media = require("modules.media")

local M = {}
local watcher
local lastPauseAt = 0

local function pauseOnce()
	local now = hs.timer.secondsSinceEpoch()

	-- 锁屏会连续触发多个相关事件，这里做防抖，保证一次锁屏只暂停一次。
	if now - lastPauseAt < 2 then
		return
	end

	lastPauseAt = now
	media.pauseAll()
end

local function handleEvent(event)
	if not watcher then
		return
	end

	-- sessionDidResignActive 比 screensDidLock 更早触发，可以在会话真正锁住前
	-- 给 QQ 音乐一点时间接收菜单命令。
	if
		event == hs.caffeinate.watcher.sessionDidResignActive
		or event == hs.caffeinate.watcher.screensDidLock
		or event == hs.caffeinate.watcher.systemWillSleep
	then
		pauseOnce()
	end
end

function M.start()
	if watcher then
		return
	end

	local candidate = hs.caffeinate.watcher.new(handleEvent)
	local ok, err = pcall(function()
		candidate:start()
	end)

	if not ok then
		pcall(function()
			candidate:stop()
		end)
		error(err, 0)
	end

	watcher = candidate
end

function M.stop()
	if not watcher then
		return
	end

	watcher:stop()
	watcher = nil
end

function M.isRunning()
	return watcher ~= nil
end

return M
