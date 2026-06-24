local configReloader = require("modules.config_reloader")
local hotkeys = require("modules.hotkeys")
local systemEvents = require("modules.system_events")

configReloader.start()
hotkeys.bindAll()
systemEvents.start()

hs.alert.show("Hammerspoon config loaded")
