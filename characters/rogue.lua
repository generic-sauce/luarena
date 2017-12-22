local rect_mod = require('space/rect')
local vec_mod = require('space/vec')

return function (rogue)

	rogue.q_cooldown = 0
	rogue.w_cooldown = 0

	function rogue:new_aoe()
		local aoe = {}

		aoe.owner = self
		aoe.shape = rect_mod.by_center_and_size(
			self.shape:center(),
			vec_mod(100, 100)
		)
		aoe.life_counter = 100

		function aoe:tick(frame)
			if self.life_counter == 100 then
				for key, entity in pairs(frame.entities) do
					if entity ~= self
						and entity ~= self.owner
						and self.shape:intersects(entity.shape)
						and entity.damage ~= nil then
							entity:damage(20)
					end
				end
			end

			self.life_counter = self.life_counter - 1
			if self.life_counter <= 0 then
				frame.entities:remove(self)
			end
		end

		function aoe:draw(cam)
			cam:draw_world_rect(self.shape, 100, 100, 100, 100)
		end

		return aoe
	end


	function rogue:char_tick(frame)
		self.q_cooldown = math.max(0, self.q_cooldown - 1)
		self.w_cooldown = math.max(0, self.w_cooldown - 1)

		if self.inputs.q and self.q_cooldown == 0 then
			local MAX_JUMP = 200

			self.q_cooldown = 100

			local jump = vec_mod(self.inputs.mouse_x, self.inputs.mouse_y) - self.shape:center()

			if jump:length() > MAX_JUMP then
				jump = jump:normalized() * MAX_JUMP
			end

			self.shape = self.shape:with_center_keep_size(self.shape:center() + jump)
			self.walk_target = nil
		end

		if self.inputs.w and self.w_cooldown == 0 then
			self.w_cooldown = 100
			table.insert(frame.entities, self:new_aoe())
		end
	end

	return rogue
end
