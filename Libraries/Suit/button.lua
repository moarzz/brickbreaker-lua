-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

return function(core, text, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	opt.id = opt.id or text
	opt.font = opt.font or love.graphics.getFont()

	w = w or opt.font:getWidth(text) + 4
	h = h or opt.font:getHeight() + 4

	opt.state = core:registerHitbox(opt.id, x,y,w,h)
	core:registerDraw(opt.draw or core.theme.Button, text, opt, x,y,w,h)

	-- Detect right mouse button release
	local rightHit = false
	if not core.mouse_right_down and core:isActive(opt.id) and core:isHovered(opt.id) then
		if core._last_right_down then
			rightHit = true
		end
	end
	core._last_right_down = core.mouse_right_down
	return {
		id = opt.id,
		hit = core:mouseReleasedOn(opt.id),
		rightHit = rightHit,
		hovered = core:isHovered(opt.id),
		entered = core:isHovered(opt.id) and not core:wasHovered(opt.id),
		left = not core:isHovered(opt.id) and core:wasHovered(opt.id)
	}
end
