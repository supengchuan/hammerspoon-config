local apps = require("modules.apps")
local mouse = require("modules.mouse")
local window = require("modules.window")

local M = {}

function M.bindAll()
	hs.hotkey.bind({ "ctrl", "cmd" }, "M", mouse.locate)
	hs.hotkey.bind({ "cmd", "ctrl" }, "T", apps.openWezTerm)
	hs.hotkey.bind({ "ctrl" }, "return", window.toggleFullScreen)
	hs.hotkey.bind({ "ctrl" }, ";", window.LeftSpace)
	hs.hotkey.bind({ "ctrl" }, "'", window.RightSpace)
	hs.hotkey.bind({ "ctrl" }, "[", window.MissionControl)
	hs.hotkey.bind({ "ctrl" }, "/", window.AppExpose)
end

return M
