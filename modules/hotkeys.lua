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
	local failed = {}
	local firstError
	for _, hotkey in ipairs(hotkeys) do
		local ok, err = pcall(function()
			hotkey:delete()
		end)
		if not ok then
			table.insert(failed, hotkey)
			firstError = firstError or err
		end
	end
	return failed, firstError
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
		local failed = deleteHotkeys(created)
		if #failed > 0 then
			activeHotkeys = failed
		end
		error(err, 0)
	end

	activeHotkeys = created
end

function M.stop()
	if not activeHotkeys then
		return
	end

	local hotkeys = activeHotkeys
	local failed, err = deleteHotkeys(hotkeys)
	activeHotkeys = #failed > 0 and failed or nil
	if err then
		error(err, 0)
	end
end

function M.isRunning()
	return activeHotkeys ~= nil
end

return M
