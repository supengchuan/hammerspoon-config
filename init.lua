local featureManager = require("modules.feature_manager")
local featureMenu = require("modules.feature_menu")

featureManager.start()
featureMenu.start()

hs.alert.show("Hammerspoon config loaded")
