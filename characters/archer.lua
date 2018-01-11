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
		arrow.speed = (self.inputs.mouse - self.shape:center()):normalized() * 2

		function arrow:on_enter_collider(frame, e)
			if e.damage and e ~= self.owner then
				e:damage(20)
				frame:remove(self)
			end
		end

		function arrow:tick(frame)
			self.shape = self.shape:with_center_keep_size(self.shape:center() + self.speed)
			if not frame.map:rect():surrounds(self.shape) then
				frame:remove(self)
			end

		end

		function arrow:draw(viewport)
			viewport:draw_world_rect(self.shape, 0, 0, 255)
		end

		return arrow
	end

	function archer:char_tick(frame)
		self.q_cooldown = math.max(0, self.q_cooldown - 1)
		if self.inputs.q and self.q_cooldown == 0 then
			self.q_cooldown = 100
			frame:add(self:new_arrow())
		end
	end

	return archer
end
