--local configReloader = require("modules.config_reloader")
local hotkeys = require("modules.hotkeys")
local systemEvents = require("modules.system_events")
local displayAwake = require("modules.display_awake")

--configReloader.start()
hotkeys.bindAll()
systemEvents.start()
displayAwake.start()

hs.alert.show("Hammerspoon config loaded")
