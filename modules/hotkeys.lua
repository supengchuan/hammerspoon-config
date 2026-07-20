local apps = require("modules.apps")
local bluetooth = require("modules.bluetooth")
local mouse = require("modules.mouse")
local window = require("modules.window")

local M = {}

function M.bindAll()
	hs.hotkey.bind({ "ctrl", "cmd" }, "B", bluetooth.toggle)
	hs.hotkey.bind({ "ctrl", "cmd" }, "M", mouse.locate)
	hs.hotkey.bind({ "ctrl", "cmd" }, "N", window.moveToNextScreen)
	hs.hotkey.bind({ "ctrl", "cmd" }, "P", window.moveToPreviousScreen)
	hs.hotkey.bind({ "ctrl" }, "return", window.maximize)
	hs.hotkey.bind({ "ctrl", "cmd" }, "return", window.toggleFullScreen)
	hs.hotkey.bind({ "ctrl", "cmd" }, "T", apps.openWezTerm)
end

return M
