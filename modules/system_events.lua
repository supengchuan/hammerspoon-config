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
	-- sessionDidResignActive 比 screensDidLock 更早触发，可以在会话真正锁住前
	-- 给 QQ 音乐一点时间接收菜单命令。
	if event == hs.caffeinate.watcher.sessionDidResignActive
		or event == hs.caffeinate.watcher.screensDidLock
		or event == hs.caffeinate.watcher.systemWillSleep then
		pauseOnce()
	end
end

function M.start()
	watcher = hs.caffeinate.watcher.new(handleEvent)
	watcher:start()
end

return M
