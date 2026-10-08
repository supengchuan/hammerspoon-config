local caffeinateCalls = {}

package.loaded["modules.hotkeys"] = {
	bindAll = function() end,
}
package.loaded["modules.system_events"] = {
	start = function() end,
}

hs = {
	alert = {
		show = function() end,
	},
	battery = {
		powerSourceType = function()
			return "AC Power"
		end,
		watcher = {
			new = function()
				return { start = function() end }
			end,
		},
	},
	caffeinate = {
		set = function(sleepType, enabled)
			table.insert(caffeinateCalls, { sleepType = sleepType, enabled = enabled })
		end,
		watcher = {
			new = function()
				return { start = function() end }
			end,
		},
	},
	execute = function() end,
}

dofile("init.lua")

assert(#caffeinateCalls == 1)
assert(caffeinateCalls[1].sleepType == "displayIdle")
assert(caffeinateCalls[1].enabled == true)

print("init tests passed")
