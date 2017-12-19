return function (archer)

	function archer:new_arrow()
		local arrow = {}

		arrow.owner = self
		arrow.x = self.x
		arrow.y = self.y
		arrow.speed_x = self.inputs.mouse_x - self.x
		arrow.speed_y = self.inputs.mouse_y - self.y
		local l = math.sqrt(arrow.speed_x^2 + arrow.speed_y^2)
		arrow.speed_x = arrow.speed_x / l
		arrow.speed_y = arrow.speed_y / l

		function arrow:destroy(frame)
			for key, entity in pairs(frame.entities) do
				if entity == self then
					table.remove(frame.entities, key)
				end
			end
		end

		function arrow:tick(frame)
			arrow.x = arrow.x + arrow.speed_x
			arrow.y = arrow.y + arrow.speed_y
			if arrow.x < 0 or arrow.x > 1000 or arrow.y < 0 or arrow.y > 1000 then
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
		if self.inputs.q then
			table.insert(frame.entities, self:new_arrow())
		end
	end

	return archer
end
