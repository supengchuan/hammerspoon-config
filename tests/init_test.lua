local events = {}

package.loaded["modules.feature_manager"] = {
	start = function()
		table.insert(events, "manager")
	end,
}
package.loaded["modules.feature_menu"] = {
	start = function()
		table.insert(events, "menu")
	end,
}

package.loaded["modules.hotkeys"] = {
	bindAll = function()
		error("old hotkey startup path used")
	end,
}
package.loaded["modules.system_events"] = {
	start = function()
		error("old system-event startup path used")
	end,
}
package.loaded["modules.display_awake"] = {
	start = function()
		error("old display-awake startup path used")
	end,
}

hs = {
	alert = {
		show = function(message)
			table.insert(events, "alert:" .. message)
		end,
	},
}

dofile("init.lua")

assert(#events == 3)
assert(events[1] == "manager")
assert(events[2] == "menu")
assert(events[3] == "alert:Hammerspoon config loaded")

print("init tests passed")
