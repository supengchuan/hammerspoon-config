local apps = require("modules.apps")
local bluetooth = require("modules.bluetooth")
local mouse = require("modules.mouse")
local window = require("modules.window")

local M = {}
local activeHotkeys

local bindings = {
	{ { "ctrl", "cmd" }, "B", bluetooth.toggle },
	{ { "ctrl", "cmd" }, "M", mouse.locate },
	{ { "ctrl", "cmd" }, "N", window.moveToNextScreen },
	{ { "ctrl", "cmd" }, "P", window.moveToPreviousScreen },
	{ { "ctrl" }, "return", window.maximize },
	{ { "ctrl", "cmd" }, "return", window.toggleFullScreen },
	{ { "ctrl", "cmd" }, "T", apps.openWezTerm },
}

local function deleteHotkeys(hotkeys)
	for _, hotkey in ipairs(hotkeys) do
		hotkey:delete()
	end
end

function M.start()
	if activeHotkeys then
		return
	end

	local created = {}
	local ok, err = pcall(function()
		for _, binding in ipairs(bindings) do
			local hotkey = hs.hotkey.bind(binding[1], binding[2], binding[3])
			if not hotkey then
				error("failed to bind hotkey " .. binding[2])
			end
			table.insert(created, hotkey)
		end
	end)

	if not ok then
		deleteHotkeys(created)
		error(err, 0)
	end

	activeHotkeys = created
end

function M.stop()
	if not activeHotkeys then
		return
	end

	local hotkeys = activeHotkeys
	activeHotkeys = nil
	deleteHotkeys(hotkeys)
end

function M.isRunning()
	return activeHotkeys ~= nil
end

return M
