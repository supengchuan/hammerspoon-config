local featureManager = require("core.feature_manager")
local featurePath = hs.configdir .. "/feature.lua"

if hs.fs.attributes(featurePath) then
	featureManager.start(dofile(featurePath))
end

hs.alert.show("Hammerspoon config loaded")
