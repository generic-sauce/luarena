local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

return function (archer)

	archer.q_cooldown = 0

	function archer:new_arrow()
		local arrow = {}

		arrow.owner = self
		arrow.shape = rect_mod.by_center_and_size(
			self.shape:center(),
			vec_mod(4, 4)
		)
		arrow.speed = (vec_mod(self.inputs.mouse_x, self.inputs.mouse_y) - self.shape:center()):normalized() * 2

		function arrow:tick(frame)
			self.shape = self.shape:with_center_keep_size(self.shape:center() + self.speed)
			if not frame.map:rect():surrounds(self.shape) then
				frame.entities:remove(self)
			end

			for key, entity in pairs(frame.entities) do
				if entity ~= self and entity ~= self.owner then
					if self.shape:intersects(entity.shape) then
						if entity.damage ~= nil then
							entity:damage(10)
							frame.entities:remove(self)
						end
					end
				end
			end

		end

		function arrow:draw(cam)
			cam:draw_world_rect(self.shape, 0, 0, 255)
		end

		return arrow
	end

	function archer:char_tick(frame)
		self.q_cooldown = math.max(0, self.q_cooldown - 1)
		if self.inputs.q and self.q_cooldown == 0 then
			self.q_cooldown = 100
			table.insert(frame.entities, self:new_arrow())
		end
	end

	return archer
end
