local M = {}

function M.openWezTerm()
	local app = hs.application.get("WezTerm")

	if not app then
		hs.application.launchOrFocus("WezTerm")
		return
	end

	app:activate()

	hs.timer.doAfter(0.1, function()
		hs.eventtap.keyStroke({ "cmd" }, "n", 0, app)
	end)
end

return M
