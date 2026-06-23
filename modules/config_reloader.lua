local M = {}
local watcher

local function shouldReload(files)
	for _, file in ipairs(files) do
		if file:sub(-4) == ".lua" then
			return true
		end
	end

	return false
end

function M.start()
	local configDir = os.getenv("HOME") .. "/.hammerspoon/"

	watcher = hs.pathwatcher.new(configDir, function(files)
		if shouldReload(files) then
			hs.reload()
		end
	end)

	watcher:start()
end

return M
