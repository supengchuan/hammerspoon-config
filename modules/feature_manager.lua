local hotkeys = require("modules.hotkeys")
local systemEvents = require("modules.system_events")
local displayAwake = require("modules.display_awake")

local M = {}
local logger = hs.logger.new("feature_manager")

local features = {
	{
		id = "hotkeys",
		title = "快捷键",
		default = true,
		setting = "hammerspoon_feature_hotkeys",
		module = hotkeys,
	},
	{
		id = "system_events",
		title = "锁屏/睡眠时暂停音乐",
		default = true,
		setting = "hammerspoon_feature_system_events",
		module = systemEvents,
	},
	{
		id = "display_awake",
		title = "显示器常亮",
		default = false,
		setting = "hammerspoon_feature_display_awake",
		module = displayAwake,
	},
}

local featuresByID = {}
for _, feature in ipairs(features) do
	featuresByID[feature.id] = feature
end

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

function M.start()
	for _, feature in ipairs(features) do
		local saved = hs.settings.get(feature.setting)
		local enabled = feature.default
		if type(saved) == "boolean" then
			enabled = saved
		end
		applyState(feature, enabled)
	end
end

function M.list()
	local result = {}
	for _, feature in ipairs(features) do
		table.insert(result, {
			id = feature.id,
			title = feature.title,
			enabled = feature.module.isRunning(),
		})
	end
	return result
end

function M.isEnabled(id)
	local feature = featuresByID[id]
	if not feature then
		return nil
	end
	return feature.module.isRunning()
end

function M.setEnabled(id, enabled)
	local feature = featuresByID[id]
	if not feature then
		return false, "unknown feature: " .. tostring(id)
	end

	local ok, err = applyState(feature, enabled)
	if not ok then
		return false, err
	end

	hs.settings.set(feature.setting, enabled)
	return true, nil
end

return M
