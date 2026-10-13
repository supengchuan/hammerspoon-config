local M = {}
local executable = "/opt/homebrew/bin/blueutil"
local logger = hs.logger.new("bluetooth")

local function execute(arguments)
  local output, success = hs.execute(executable .. " " .. arguments)
  if not success then logger.e("blueutil failed: " .. arguments) end
  return output, success
end

function M.isOn()
  local output, success = execute("--power")
  if not success then return nil end
  if output:match("^1%s*$") then return true end
  if output:match("^0%s*$") then return false end
  logger.e("unexpected blueutil power state: " .. output)
  return nil
end

function M.setEnabled(enabled)
  local _, success = execute("--power " .. (enabled and "on" or "off"))
  return success
end

function M.toggle()
  local isOn = M.isOn()
  if isOn == nil then return false end
  local enabled = not isOn
  if not M.setEnabled(enabled) then return false end
  hs.alert.show("Bluetooth turned " .. (enabled and "on" or "off"))
  return true
end

return M
