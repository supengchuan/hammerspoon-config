local function newFeature(name)
	local feature = {
		name = name,
		running = false,
		startCalls = 0,
		stopCalls = 0,
		failOnStart = false,
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
		feature.running = false
	end

	function feature.isRunning()
		return feature.running
	end

	return feature
end

local function loadManager()
	local observations = { logs = {}, alerts = {} }
	local features = {
		hotkeys = newFeature("hotkeys"),
		systemEvents = newFeature("system_events"),
		displayAwake = newFeature("display_awake"),
	}

	package.loaded["modules.feature_manager"] = nil
	package.loaded["features.hotkeys"] = features.hotkeys
	package.loaded["features.system_events"] = features.systemEvents
	package.loaded["features.display_awake"] = features.displayAwake

	hs = {
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

local manager, features = loadManager()
manager.start({
	hotkeys = true,
	system_events = "true",
	display_awake = 1,
})

assert(features.hotkeys.startCalls == 1, "literal true should enable a feature")
assert(features.systemEvents.startCalls == 0, "string true must not enable a feature")
assert(features.displayAwake.startCalls == 0, "truthy values must not enable a feature")
assert(features.systemEvents.stopCalls == 1)
assert(features.displayAwake.stopCalls == 1)

local emptyManager, emptyFeatures = loadManager()
emptyManager.start({})
assert(emptyFeatures.hotkeys.startCalls == 0)
assert(emptyFeatures.systemEvents.startCalls == 0)
assert(emptyFeatures.displayAwake.startCalls == 0)

local failingManager, failingFeatures, failingObservations = loadManager()
failingFeatures.hotkeys.failOnStart = true
failingManager.start({
	hotkeys = true,
	system_events = true,
	display_awake = true,
})

assert(failingFeatures.hotkeys.running == false)
assert(failingFeatures.systemEvents.running == true, "one failure should not block later features")
assert(failingFeatures.displayAwake.running == true, "one failure should not block later features")
assert(#failingObservations.logs == 1)
assert(failingObservations.logs[1]:find("hotkeys start failed", 1, true) ~= nil)
assert(#failingObservations.alerts == 1)
assert(failingObservations.alerts[1]:find("快捷键", 1, true) ~= nil)

print("feature manager tests passed")
