local bindCalls = 0
local deleteCalls = 0
local deleteAttempts = 0
local bindings = {}
local failOnBindCall
local failOnDeleteCall

local callbacks = {
	openWezTerm = function() end,
	toggleBluetooth = function() end,
	locateMouse = function() end,
	moveToNextScreen = function() end,
	moveToPreviousScreen = function() end,
	maximizeWindow = function() end,
	toggleFullScreen = function() end,
}

package.loaded["modules.apps"] = { openWezTerm = callbacks.openWezTerm }
package.loaded["modules.bluetooth"] = { toggle = callbacks.toggleBluetooth }
package.loaded["modules.mouse"] = { locate = callbacks.locateMouse }
package.loaded["modules.window"] = {
	moveToNextScreen = callbacks.moveToNextScreen,
	moveToPreviousScreen = callbacks.moveToPreviousScreen,
	maximize = callbacks.maximizeWindow,
	toggleFullScreen = callbacks.toggleFullScreen,
}

hs = {
	hotkey = {
		bind = function(modifiers, key, callback)
			bindCalls = bindCalls + 1
			if bindCalls == failOnBindCall then
				error("hotkey bind failed")
			end

			local handle = { deleted = false }
			function handle:delete()
				deleteAttempts = deleteAttempts + 1
				if deleteAttempts == failOnDeleteCall then
					error("hotkey delete failed")
				end
				assert(not self.deleted, "hotkey handle should only be deleted once")
				self.deleted = true
				deleteCalls = deleteCalls + 1
			end

			table.insert(bindings, {
				modifiers = modifiers,
				key = key,
				callback = callback,
				handle = handle,
			})
			return handle
		end,
	},
}

local hotkeys = require("modules.hotkeys")

hotkeys.start()
assert(hotkeys.isRunning() == true)
assert(bindCalls == 7)

hotkeys.start()
assert(bindCalls == 7, "repeated start should not duplicate bindings")

local bluetoothBinding
for _, binding in ipairs(bindings) do
	if binding.key == "B" then
		bluetoothBinding = binding
		break
	end
end

assert(bluetoothBinding ~= nil)
assert(#bluetoothBinding.modifiers == 2)
assert(bluetoothBinding.modifiers[1] == "ctrl")
assert(bluetoothBinding.modifiers[2] == "cmd")
assert(bluetoothBinding.callback == callbacks.toggleBluetooth)

hotkeys.stop()
assert(hotkeys.isRunning() == false)
assert(deleteCalls == 7)

hotkeys.stop()
assert(deleteCalls == 7, "repeated stop should not delete bindings again")

hotkeys.start()
assert(hotkeys.isRunning() == true)
assert(bindCalls == 14, "restart should create fresh bindings")
hotkeys.stop()
assert(deleteCalls == 14)

package.loaded["modules.hotkeys"] = nil
bindCalls = 0
deleteCalls = 0
bindings = {}
failOnBindCall = 4

local failingHotkeys = require("modules.hotkeys")
local ok = pcall(failingHotkeys.start)
assert(ok == false, "bind failure should propagate")
assert(deleteCalls == 3, "partial start should delete earlier bindings")
assert(failingHotkeys.isRunning() == false)

package.loaded["modules.hotkeys"] = nil
bindCalls = 0
deleteCalls = 0
deleteAttempts = 0
bindings = {}
failOnBindCall = nil
failOnDeleteCall = 4

local deleteFailingHotkeys = require("modules.hotkeys")
deleteFailingHotkeys.start()
local stopOk = pcall(deleteFailingHotkeys.stop)
assert(stopOk == false, "delete failure should propagate")
assert(deleteAttempts == 7, "stop should attempt every hotkey after one deletion fails")
assert(deleteCalls == 6)
assert(deleteFailingHotkeys.isRunning() == true, "failed handles should remain tracked")

failOnDeleteCall = nil
deleteFailingHotkeys.stop()
assert(deleteAttempts == 8, "retry should only delete the failed handle")
assert(deleteCalls == 7)
assert(deleteFailingHotkeys.isRunning() == false)

print("hotkeys tests passed")
