local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

return {
	fixed = function(pos)
		assert(pos ~= nil)

		local cam = {
			pos_vec = pos, -- in world coordinates
			zoom = 0.6 -- world_length * zoom = pixel_length
		}

		function cam:viewport() -- visible world-coordinates rect
			return rect_mod.by_center_and_size(
				self.pos_vec,
				vec_mod(love.graphics.getWidth(), love.graphics.getHeight()) / self.zoom
			)
		end

		function cam:draw_world_rect(world_rect, r, g, b, a)
			local screen_rect = cam:world_to_screen_rect(world_rect)
			love.graphics.setColor(r, g, b, a)
			love.graphics.rectangle("fill", screen_rect:left(), screen_rect:top(), screen_rect:width(), screen_rect:height())
		end

		function cam:world_to_screen_vec(vec)
			return (vec - self:viewport():left_top()) * self.zoom
		end

		function cam:screen_to_world_vec(vec)
			return vec / self.zoom + self:viewport():left_top()
		end

		function cam:world_to_screen_rect(rect)
			return rect_mod.by_center_and_size(
				self:world_to_screen_vec(rect:center()),
				rect:size() * self.zoom
			)
		end

		return cam
	end
}
