local function newFeature(name)
	local feature = {
		name = name,
		running = false,
		startCalls = 0,
		stopCalls = 0,
		failOnStart = false,
		failOnStop = false,
	}

	function feature.start()
		feature.startCalls = feature.startCalls + 1
		if feature.failOnStart then
			error(name .. " start failed")
		end
		feature.running = true
	end

	function feature.stop()
		feature.stopCalls = feature.stopCalls + 1
		if feature.failOnStop then
			error(name .. " stop failed")
		end
		feature.running = false
	end

	function feature.isRunning()
		return feature.running
	end

	return feature
end

local function loadManager(settingValues)
	local observations = {
		getKeys = {},
		sets = {},
		logs = {},
		alerts = {},
	}
	local features = {
		hotkeys = newFeature("hotkeys"),
		systemEvents = newFeature("system_events"),
		displayAwake = newFeature("display_awake"),
	}

	package.loaded["modules.feature_manager"] = nil
	package.loaded["modules.hotkeys"] = features.hotkeys
	package.loaded["modules.system_events"] = features.systemEvents
	package.loaded["modules.display_awake"] = features.displayAwake

	hs = {
		settings = {
			get = function(key)
				table.insert(observations.getKeys, key)
				return settingValues[key]
			end,
			set = function(key, value)
				settingValues[key] = value
				table.insert(observations.sets, { key = key, value = value })
			end,
		},
		logger = {
			new = function(name)
				assert(name == "feature_manager")
				return {
					e = function(first, second)
						table.insert(observations.logs, second or first)
					end,
				}
			end,
		},
		alert = {
			show = function(message)
				table.insert(observations.alerts, message)
			end,
		},
	}

	return require("modules.feature_manager"), features, observations
end

local settings = {
	hammerspoon_feature_system_events = false,
	hammerspoon_feature_display_awake = "invalid",
}
local manager, features, observations = loadManager(settings)

manager.start()
assert(features.hotkeys.running == true, "missing setting should use enabled default")
assert(features.systemEvents.running == false, "saved false should override enabled default")
assert(features.displayAwake.running == false, "invalid setting should use disabled default")
assert(#observations.getKeys == 3)
assert(observations.getKeys[1] == "hammerspoon_feature_hotkeys")
assert(observations.getKeys[2] == "hammerspoon_feature_system_events")
assert(observations.getKeys[3] == "hammerspoon_feature_display_awake")

local listed = manager.list()
assert(#listed == 3)
assert(listed[1].id == "hotkeys")
assert(listed[1].title == "快捷键")
assert(listed[1].enabled == true)
assert(listed[2].id == "system_events")
assert(listed[2].title == "锁屏/睡眠时暂停音乐")
assert(listed[2].enabled == false)
assert(listed[3].id == "display_awake")
assert(listed[3].title == "显示器常亮")
assert(listed[3].enabled == false)

features.hotkeys.running = false
assert(manager.isEnabled("hotkeys") == false, "state queries should be live")
assert(manager.list()[1].enabled == false, "list should report actual module state")

local enabled, enableError = manager.setEnabled("display_awake", true)
assert(enabled == true)
assert(enableError == nil)
assert(features.displayAwake.running == true)
assert(observations.sets[1].key == "hammerspoon_feature_display_awake")
assert(observations.sets[1].value == true)

local disabled, disableError = manager.setEnabled("display_awake", false)
assert(disabled == true)
assert(disableError == nil)
assert(features.displayAwake.running == false)
assert(observations.sets[2].key == "hammerspoon_feature_display_awake")
assert(observations.sets[2].value == false)

local writesBeforeUnknown = #observations.sets
local unknownOk, unknownError = manager.setEnabled("missing", true)
assert(unknownOk == false)
assert(unknownError == "unknown feature: missing")
assert(manager.isEnabled("missing") == nil)
assert(#observations.sets == writesBeforeUnknown)

local failingSettings = {
	hammerspoon_feature_hotkeys = true,
	hammerspoon_feature_system_events = true,
	hammerspoon_feature_display_awake = false,
}
local failingManager, failingFeatures, failingObservations = loadManager(failingSettings)
failingFeatures.hotkeys.failOnStart = true

failingManager.start()
assert(failingFeatures.hotkeys.running == false)
assert(failingFeatures.systemEvents.running == true, "one failure should not block later features")
assert(failingFeatures.displayAwake.running == false)
assert(#failingObservations.logs == 1)
assert(failingObservations.logs[1]:find("hotkeys start failed", 1, true) ~= nil)
assert(#failingObservations.alerts == 1)
assert(failingObservations.alerts[1]:find("快捷键", 1, true) ~= nil)
assert(#failingObservations.sets == 0, "startup should not rewrite preferences")

local failedOk, failedError = failingManager.setEnabled("hotkeys", true)
assert(failedOk == false)
assert(type(failedError) == "string")
assert(failedError:find("快捷键", 1, true) ~= nil)
assert(#failingObservations.logs == 2)
assert(#failingObservations.alerts == 2)
assert(#failingObservations.sets == 0, "failed toggles should not persist")

print("feature manager tests passed")
