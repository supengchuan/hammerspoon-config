local M = {}

local ringSizes = { 260, 180, 100 }
local animationSteps = 12
local animationInterval = 0.03

local function createRing(pos, size)
	local ring = hs.drawing.circle(hs.geometry.rect(pos.x - size / 2, pos.y - size / 2, size, size))

	ring:setStrokeWidth(6)
	ring:setStrokeColor({ red = 1, green = 0, blue = 0, alpha = 0.9 })
	ring:setFill(false)
	ring:setLevel(hs.drawing.windowLevels.overlay)
	ring:show()

	return ring
end

local function updateRing(ring, pos, size, alpha)
	ring:setFrame(hs.geometry.rect(pos.x - size / 2, pos.y - size / 2, size, size))
	ring:setStrokeColor({
		red = 1,
		green = 0,
		blue = 0,
		alpha = alpha,
	})
end

function M.locate()
	local pos = hs.mouse.absolutePosition()
	local rings = {}

	for _, size in ipairs(ringSizes) do
		table.insert(rings, createRing(pos, size))
	end

	local currentStep = 0
	local timer

	timer = hs.timer.doEvery(animationInterval, function()
		currentStep = currentStep + 1

		local scale = 1 - currentStep / animationSteps * 0.45
		local alpha = 0.9 - currentStep / animationSteps * 0.7

		for index, ring in ipairs(rings) do
			updateRing(ring, pos, ringSizes[index] * scale, alpha)
		end

		if currentStep >= animationSteps then
			timer:stop()

			for _, ring in ipairs(rings) do
				ring:delete()
			end
		end
	end)
end

return M
