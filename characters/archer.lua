return function (archer)

	archer.q_cooldown = 0

	function archer:new_arrow()
		local arrow = {}

		arrow.owner = self
		arrow.x = self.x
		arrow.y = self.y
		arrow.speed_x = self.inputs.mouse_x - self.x
		arrow.speed_y = self.inputs.mouse_y - self.y
		local l = math.sqrt(arrow.speed_x^2 + arrow.speed_y^2)
		arrow.speed_x = 2 * arrow.speed_x / l
		arrow.speed_y = 2 * arrow.speed_y / l

		function arrow:destroy(frame)
			for key, entity in pairs(frame.entities) do
				if entity == self then
					table.remove(frame.entities, key)
				end
			end
		end

		function arrow:tick(frame)
			self.x = self.x + self.speed_x
			self.y = self.y + self.speed_y
			if self.x < 0 or self.x > 1000 or self.y < 0 or self.y > 1000 then
				self:destroy(frame)
			end

			for key, entity in pairs(frame.entities) do
				if entity ~= self and entity ~= self.owner then
					if math.abs(self.x - entity.x) < 10 and math.abs(self.y - entity.y) < 10 then
						if entity.health ~= nil then
							entity.health = math.max(0, entity.health - 10)
							self:destroy(frame)
						end
					end
				end
			end

		end

		function arrow:draw()
			love.graphics.setColor(0, 0, 100)
			love.graphics.rectangle("fill", self.x - 2, self.y - 2, 4, 4)
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
