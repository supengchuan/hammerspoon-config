local calls, alerts, logs, responses = {}, {}, {}, {}

local function assertEqual(actual, expected, message)
  assert(actual == expected, (message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function setResponses(...)
  responses = { ... }
end

local function resetObservations()
  calls, alerts, logs = {}, {}, {}
end

hs = {
  execute = function(command)
    table.insert(calls, command)
    local response = table.remove(responses, 1)
    assert(response ~= nil, "unexpected blueutil invocation")
    return response.output, response.success
  end,
  alert = { show = function(message) table.insert(alerts, message) end },
  logger = {
    new = function(name)
      assertEqual(name, "bluetooth", "logger name")
      return { e = function(message) table.insert(logs, message) end }
    end,
  },
}

local bluetooth = require("modules.bluetooth")

-- Query failure: do not toggle or alert, and preserve the command failure in the log.
resetObservations()
setResponses({ output = "", success = false })
assertEqual(bluetooth.toggle(), false, "query failure result")
assertEqual(calls[1], "/opt/homebrew/bin/blueutil --power", "query command")
assertEqual(logs[1], "blueutil failed: --power", "query failure log")
assertEqual(#alerts, 0, "query failure alerts")

-- Malformed power output is rejected without an alert and is logged for diagnosis.
resetObservations()
setResponses({ output = "unknown\n", success = true })
assertEqual(bluetooth.toggle(), false, "malformed power result")
assertEqual(logs[1], "unexpected blueutil power state: unknown\n", "malformed power log")
assertEqual(#alerts, 0, "malformed power alerts")

-- A failed state change reports failure and never claims success to the user.
resetObservations()
setResponses({ output = "", success = false })
assertEqual(bluetooth.setEnabled(false), false, "set failure result")
assertEqual(calls[1], "/opt/homebrew/bin/blueutil --power off", "set failure command")
assertEqual(logs[1], "blueutil failed: --power off", "set failure log")
assertEqual(#alerts, 0, "set failure alerts")

-- Toggle must also remain silent when the set command fails after a successful query.
resetObservations()
setResponses({ output = "1\n", success = true }, { output = "", success = false })
assertEqual(bluetooth.toggle(), false, "toggle set failure result")
assertEqual(calls[2], "/opt/homebrew/bin/blueutil --power off", "toggle set failure command")
assertEqual(logs[1], "blueutil failed: --power off", "toggle set failure log")
assertEqual(#alerts, 0, "toggle set failure alerts")

-- Both toggle directions execute the opposite state and alert only after success.
resetObservations()
setResponses({ output = "1\n", success = true }, { output = "", success = true })
assertEqual(bluetooth.toggle(), true, "toggle off result")
assertEqual(calls[2], "/opt/homebrew/bin/blueutil --power off", "toggle off command")
assertEqual(alerts[1], "Bluetooth turned off", "toggle off alert")
assertEqual(#logs, 0, "toggle off logs")

resetObservations()
setResponses({ output = "0\n", success = true }, { output = "", success = true })
assertEqual(bluetooth.toggle(), true, "toggle on result")
assertEqual(calls[2], "/opt/homebrew/bin/blueutil --power on", "toggle on command")
assertEqual(alerts[1], "Bluetooth turned on", "toggle on alert")
assertEqual(#logs, 0, "toggle on logs")

print("bluetooth tests passed")
