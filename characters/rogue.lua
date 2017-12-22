return function (rogue)

	rogue.q_cooldown = 0
	rogue.w_cooldown = 0

	function rogue:new_aoe()
		local aoe = {}

		aoe.owner = self
		aoe.x = self.x
		aoe.y = self.y
		aoe.life_counter = 100

		function aoe:tick(entities)
			if self.life_counter == 100 then
				for key, entity in pairs(entities) do
					if entity ~= self and entity ~= self.owner then
						if math.abs(self.x - entity.x) < 40 and math.abs(self.y - entity.y) < 40 then
							if entity.damage ~= nil then
								entity:damage(20)
							end
						end
					end
				end
			end

			self.life_counter = self.life_counter - 1
			if self.life_counter <= 0 then
				entities:remove(self)
			end
		end

		function aoe:draw()
			love.graphics.setColor(100, 100, 100, 100)
			love.graphics.rectangle("fill", self.x - 20, self.y - 20, 40, 40)
		end

		return aoe
	end


	function rogue:char_tick(entities)
		self.q_cooldown = math.max(0, self.q_cooldown - 1)
		self.w_cooldown = math.max(0, self.w_cooldown - 1)

		if self.inputs.q and self.q_cooldown == 0 then
			local MAX_JUMP = 200

			self.q_cooldown = 100

			local jump_x = self.inputs.mouse_x - self.x
			local jump_y = self.inputs.mouse_y - self.y

			local l = math.sqrt(jump_x^2 + jump_y^2)
			if l > MAX_JUMP then
				jump_x = MAX_JUMP * jump_x / l
				jump_y = MAX_JUMP * jump_y / l
			end

			self.x = self.x + jump_x
			self.y = self.y + jump_y

			self.walk_target_x, self.walk_target_y = nil, nil
		end

		if self.inputs.w and self.w_cooldown == 0 then
			self.w_cooldown = 100
			table.insert(entities, self:new_aoe())
		end
	end

	return rogue
end
