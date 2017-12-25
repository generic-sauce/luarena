local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

local cam_mod = {} -- a cam is just a viewport-generator; a viewport contains a rect in world coordinates

function get_screen_size()
	return vec_mod(love.graphics.getWidth(), love.graphics.getHeight())
end

function new_viewport(rect)
	local viewport = {}
	viewport.rect = rect

	function viewport:draw_world_rect(world_rect, r, g, b, a)
		local screen_rect = self:world_to_screen_rect(world_rect)
		love.graphics.setColor(r, g, b, a)
		love.graphics.rectangle("fill", screen_rect:left(), screen_rect:top(), screen_rect:width(), screen_rect:height())
	end

	function viewport:world_to_screen_vec(vec)
		local ret = vec - self.rect:left_top()
		local screen_size = get_screen_size()
		return ret
			:with_x(ret.x * screen_size.x / self.rect:width())
			:with_y(ret.y * screen_size.y / self.rect:height())
	end

	function viewport:screen_to_world_vec(vec)
		local screen_size = get_screen_size()
		return vec
			:with_x(vec.x * self.rect:width() / screen_size.x)
			:with_y(vec.y * self.rect:height() / screen_size.y)
			+ self.rect:left_top()
	end

	function viewport:world_to_screen_rect(world_rect)
		local size = world_rect:size()
		local screen_size = get_screen_size()
		return rect_mod.by_center_and_size(
			self:world_to_screen_vec(world_rect:center()),
			size
				:with_x(size.x * screen_size.x / self.rect:width())
				:with_y(size.y * screen_size.y / self.rect:height())
		)
	end

	return viewport
end

function cam_mod.fixed(pos)
	assert(pos ~= nil)

	local cam = {
		pos_vec = pos, -- in world coordinates
		zoom = 2 -- world_length * zoom = pixel_length
	}

	function cam:viewport(frame)
		return new_viewport(rect_mod.by_center_and_size(
			self.pos_vec,
			get_screen_size() / self.zoom
		))
	end

	return cam
end

function cam_mod.following(entity_id)
	assert(entity_id ~= nil)

	local cam = {
		entity_id = entity_id,
		zoom = 2 -- world_length * zoom = pixel_length
	}

	function cam:viewport(frame)
		return new_viewport(rect_mod.by_center_and_size(
			frame.entities[entity_id].shape:center(),
			get_screen_size() / self.zoom
		))
	end

	return cam
end

return cam_mod
