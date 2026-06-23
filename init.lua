local configReloader = require("modules.config_reloader")
local hotkeys = require("modules.hotkeys")

configReloader.start()
hotkeys.bindAll()

hs.alert.show("Hammerspoon config loaded")
