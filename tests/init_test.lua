local originalDofile = dofile
local featurePath = "/test/config/feature.lua"
local events = {}
local featureFileExists = false
local featureConfig = {
	hotkeys = true,
	system_events = false,
	display_awake = false,
}

package.loaded["modules.feature_manager"] = {
	start = function(config)
		table.insert(events, { name = "manager", config = config })
	end,
}
package.loaded["modules.feature_menu"] = {
	start = function()
		error("feature menu should not start")
	end,
}

dofile = function(path)
	if path == featurePath then
		return featureConfig
	end
	return originalDofile(path)
end

hs = {
	configdir = "/test/config",
	fs = {
		attributes = function(path)
			assert(path == featurePath)
			return featureFileExists and { mode = "file" } or nil
		end,
	},
	alert = {
		show = function(message)
			table.insert(events, { name = "alert", message = message })
		end,
	},
}

originalDofile("init.lua")
assert(#events == 1, "missing feature.lua should not start the feature manager")
assert(events[1].name == "alert")

events = {}
featureFileExists = true
originalDofile("init.lua")

assert(#events == 2)
assert(events[1].name == "manager")
assert(events[1].config == featureConfig)
assert(events[2].name == "alert")
assert(events[2].message == "Hammerspoon config loaded")

dofile = originalDofile

print("init tests passed")
