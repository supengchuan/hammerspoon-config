local featureManager = require("modules.feature_manager")

local M = {}
local menuBar

local function buildMenu()
	local items = {}
	for _, feature in ipairs(featureManager.list()) do
		local id = feature.id
		table.insert(items, {
			title = feature.title,
			checked = feature.enabled,
			fn = function()
				local enabled = featureManager.isEnabled(id)
				if enabled ~= nil then
					featureManager.setEnabled(id, not enabled)
				end
			end,
		})
	end
	return items
end

function M.start()
	if menuBar then
		return
	end

	local candidate = hs.menubar.new(true, "hammerspoon-feature-menu")
	if not candidate then
		error("failed to create feature menu")
	end

	candidate:setTitle("HS")
	candidate:setTooltip("Hammerspoon 功能开关")
	candidate:setMenu(buildMenu)
	menuBar = candidate
end

return M
