local states = {
	hotkeys = true,
	system_events = false,
	display_awake = false,
}
local setCalls = {}

local featureManager = {}
function featureManager.list()
	return {
		{ id = "hotkeys", title = "快捷键", enabled = states.hotkeys },
		{ id = "system_events", title = "锁屏/睡眠时暂停音乐", enabled = states.system_events },
		{ id = "display_awake", title = "显示器常亮", enabled = states.display_awake },
	}
end
function featureManager.isEnabled(id)
	return states[id]
end
function featureManager.setEnabled(id, enabled)
	table.insert(setCalls, { id = id, enabled = enabled })
	states[id] = enabled
	return true, nil
end

package.loaded["modules.feature_manager"] = featureManager

local newCalls = {}
local menuBar = {}
function menuBar:setTitle(title)
	self.title = title
	return self
end
function menuBar:setTooltip(tooltip)
	self.tooltip = tooltip
	return self
end
function menuBar:setMenu(provider)
	self.provider = provider
	return self
end

hs = {
	menubar = {
		new = function(inMenuBar, autosaveName)
			table.insert(newCalls, { inMenuBar = inMenuBar, autosaveName = autosaveName })
			return menuBar
		end,
	},
}

local featureMenu = require("modules.feature_menu")
featureMenu.start()
featureMenu.start()

assert(#newCalls == 1, "repeated start should reuse the menu bar item")
assert(newCalls[1].inMenuBar == true)
assert(newCalls[1].autosaveName == "hammerspoon-feature-menu")
assert(menuBar.title == "HS")
assert(menuBar.tooltip == "Hammerspoon 功能开关")
assert(type(menuBar.provider) == "function")

local menu = menuBar.provider()
assert(#menu == 3)
assert(menu[1].title == "快捷键")
assert(menu[1].checked == true)
assert(menu[2].title == "锁屏/睡眠时暂停音乐")
assert(menu[2].checked == false)
assert(menu[3].title == "显示器常亮")
assert(menu[3].checked == false)

states.hotkeys = false
menu[1].fn()
assert(#setCalls == 1)
assert(setCalls[1].id == "hotkeys")
assert(setCalls[1].enabled == true, "click should invert the latest manager state")

local refreshedMenu = menuBar.provider()
assert(refreshedMenu[1].checked == true, "menu provider should read live state")

print("feature menu tests passed")
