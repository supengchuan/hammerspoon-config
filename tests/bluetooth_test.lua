local calls, alerts = {}, {}
hs = {
  execute = function(command)
    table.insert(calls, command)
    if command:find("--power$") then return "1\n", true end
    return "", true
  end,
  alert = { show = function(message) table.insert(alerts, message) end },
  logger = { new = function() return { e = function() end } end },
}

local bluetooth = require("modules.bluetooth")
assert(bluetooth.isOn() == true)
assert(bluetooth.setEnabled(false) == true)
assert(calls[2] == "/opt/homebrew/bin/blueutil --power off")
assert(bluetooth.toggle() == true)
assert(calls[4] == "/opt/homebrew/bin/blueutil --power off")
assert(alerts[1] == "Bluetooth turned off")
print("bluetooth tests passed")
