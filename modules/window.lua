local M = {}

function M.toggleFullScreen()
	local win = hs.window.focusedWindow()

	if win then
		win:toggleFullScreen()
	end
end

local function ctrlDirection(direction)
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
	hs.eventtap.event.newKeyEvent(direction, true):post()
	hs.eventtap.event.newKeyEvent(direction, false):post()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
end

function M.LeftSpace()
	ctrlDirection("left")
end

function M.RightSpace()
	ctrlDirection("right")
end

function M.MissionControl()
	ctrlDirection("up")
end

function M.AppExpose()
	ctrlDirection("down")
end

return M
