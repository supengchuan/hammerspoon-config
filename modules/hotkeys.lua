local apps = require("modules.apps")
local mouse = require("modules.mouse")

local M = {}

function M.bindAll()
	hs.hotkey.bind({ "ctrl", "cmd" }, "M", mouse.locate)
	hs.hotkey.bind({ "cmd", "ctrl" }, "T", apps.openWezTerm)
end

return M
