local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')

local cam_mod = {} -- a cam is just a viewport-generator

local function get_screen_size()
	return vec_mod(love.graphics.getWidth(), love.graphics.getHeight())
end

local function new_viewport(pos, zoom)
	local viewport = {}
	viewport.pos = pos -- in world coordinates (center of view)
	viewport.zoom = zoom -- world_length * zoom = pixel_length

	function viewport:rect() -- in world coordinates
		return rect_mod.by_center_and_size(
			self.pos,
			get_screen_size() / self.zoom
		)
	end

	function viewport:draw_world_rect(world_rect, r, g, b, a)
		local screen_rect = self:world_to_screen_rect(world_rect)
		love.graphics.setColor(r, g, b, a)
		love.graphics.rectangle("fill", screen_rect:left(), screen_rect:top(), screen_rect:width(), screen_rect:height())
	end

	function viewport:draw_shape(shape, r, g, b, a)
		love.graphics.setColor(r, g, b, a)
		if shape.shape_type == "polygon" then
			local vertices = {}
			for _, p in pairs(shape:abs_points()) do
				local v = self:world_to_screen_pos(p)
				table.insert(vertices, v.x)
				table.insert(vertices, v.y)
			end
			love.graphics.polygon("fill", vertices)
		elseif shape.shape_type == "circle" then
			local pos = self:world_to_screen_pos(shape:center())
			local radius = shape.radius * self.zoom
			love.graphics.circle("fill", pos.x, pos.y, radius)
		else
			assert(false)
		end
	end

	function viewport:world_to_screen_pos(pos)
		return (pos - self:rect():left_top()) * self.zoom
	end

	function viewport:world_to_screen_size(size)
		return size * self.zoom
	end

	function viewport:screen_to_world_vec(vec)
		return (vec / self.zoom) + self:rect():left_top()
	end

	function viewport:world_to_screen_rect(world_rect)
		local size = world_rect:size()
		return rect_mod.by_center_and_size(
			self:world_to_screen_pos(world_rect:center()),
			self:world_to_screen_size(size)
		)
	end

	return viewport
end

function cam_mod.fixed(pos)
	assert(pos)

	local cam = {
		pos_vec = pos,
		zoom = 2
	}

	function cam:viewport(frame)
		return new_viewport(
			self.pos_vec,
			self.zoom
		)
	end

	return cam
end

function cam_mod.following(entity_id)
	assert(entity_id)

	local cam = {
		entity_id = entity_id,
		zoom = 2
	}

	function cam:viewport(frame)
		return new_viewport(
			frame.entities[entity_id].shape:center(),
			self.zoom
		)
	end

	return cam
end

return cam_mod
