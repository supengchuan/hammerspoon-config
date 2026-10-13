local M = {}

function M.toggleFullScreen()
	local win = hs.window.focusedWindow()

	if win then
		win:toggleFullScreen()
	end
end

function M.maximize()
	local win = hs.window.focusedWindow()

	if not win then
		return
	end

	win:setFrame(win:screen():frame(), 0)
end

local function isMaximized(win)
	local windowFrame = win:frame()
	local screenFrame = win:screen():frame()

	return windowFrame.x == screenFrame.x
		and windowFrame.y == screenFrame.y
		and windowFrame.w == screenFrame.w
		and windowFrame.h == screenFrame.h
end

local function nextScreenFor(screen)
	local screens = hs.screen.allScreens()

	for index, candidate in ipairs(screens) do
		if candidate:id() == screen:id() then
			return screens[(index - 2) % #screens + 1]
		end
	end

	return nil
end

local function previousScreenFor(screen)
	local screens = hs.screen.allScreens()

	for index, candidate in ipairs(screens) do
		if candidate:id() == screen:id() then
			return screens[index % #screens + 1]
		end
	end

	return nil
end

function M.moveToNextScreen()
	local win = hs.window.focusedWindow()

	if not win then
		return
	end

	local maximized = isMaximized(win)
	local nextScreen = nextScreenFor(win:screen())

	if nextScreen then
		win:moveToScreen(nextScreen, false, true, 0)

		if maximized then
			win:setFrame(nextScreen:frame(), 0)
		end
	end
end

function M.moveToPreviousScreen()
	local win = hs.window.focusedWindow()

	if not win then
		return
	end

	local maximized = isMaximized(win)
	local previousScreen = previousScreenFor(win:screen())

	if previousScreen then
		win:moveToScreen(previousScreen, false, true, 0)

		if maximized then
			win:setFrame(previousScreen:frame(), 0)
		end
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
