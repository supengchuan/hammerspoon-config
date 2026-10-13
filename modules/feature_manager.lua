local hotkeys = require("features.hotkeys")
local systemEvents = require("features.system_events")
local displayAwake = require("features.display_awake")

local M = {}
local logger = hs.logger.new("feature_manager")

local features = {
	{
		id = "hotkeys",
		title = "快捷键",
		module = hotkeys,
	},
	{
		id = "system_events",
		title = "锁屏/睡眠时暂停音乐",
		module = systemEvents,
	},
	{
		id = "display_awake",
		title = "显示器常亮",
		module = displayAwake,
	},
}

local function failureMessage(feature, enabled)
	return "无法" .. (enabled and "开启" or "关闭") .. "：" .. feature.title
end

local function applyState(feature, enabled)
	local action = enabled and feature.module.start or feature.module.stop
	local ok, err = pcall(action)

	if ok then
		return true, nil
	end

	local message = failureMessage(feature, enabled)
	logger.e(message .. ": " .. tostring(err))
	hs.alert.show(message)
	return false, message
end

function M.start(config)
	for _, feature in ipairs(features) do
		local enabled = config[feature.id] == true
		applyState(feature, enabled)
	end
end

return M
