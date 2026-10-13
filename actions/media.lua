local M = {}

local players = {
	{ bundleID = "com.tencent.QQMusicMac", pauseMenuItems = { ".*暂停.*", ".*Pause.*" } },
}

local function runningApp(bundleID)
	if hs.application.applicationsForBundleID then
		return hs.application.applicationsForBundleID(bundleID)[1]
	end

	for _, app in ipairs(hs.application.runningApplications()) do
		if app:bundleID() == bundleID then
			return app
		end
	end

	return nil
end

local function pauseWithMenu(app, player)
	if not player.pauseMenuItems then
		return false
	end

	-- QQ 音乐没有稳定的明确 pause API。这里选择菜单里的“暂停”，避免
	-- 使用播放/暂停媒体键导致“已经暂停时锁屏反而开始播放”。
	for _, item in ipairs(player.pauseMenuItems) do
		if app:selectMenuItem(item, true) then
			return true
		end
	end

	return false
end

local function pausePlayer(player)
	local app = runningApp(player.bundleID)

	if not app then
		return false
	end

	if pauseWithMenu(app, player) then
		return true
	end

	return false
end

function M.pauseAll()
	local didPause = false

	for _, player in ipairs(players) do
		didPause = pausePlayer(player) or didPause
	end

	return didPause
end

return M
