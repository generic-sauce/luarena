function new_player(char)
	local player = {}

	player.x = 0
	player.y = 0
	player.health = 100
	player.walk_target_x, player.walk_target_y = nil, nil
	player.inputs = { q = false, w = false, e = false, r = false, mouse_x = 0, mouse_y = 0, click = false, rclick = false }

	function player:tick(frame)
		if self.inputs.rclick then
			self.walk_target_x = self.inputs.mouse_x
			self.walk_target_y = self.inputs.mouse_y
		end

		if self.walk_target_x ~= nil and self.walk_target_y ~= nil then
			local move_vec_x  = (self.walk_target_x - self.x)
			local move_vec_y  = (self.walk_target_y - self.y)
			local l = math.sqrt(move_vec_x^2 + move_vec_y^2)
			if l < 1 then
				self.x = self.walk_target_x
				self.y = self.walk_target_y
				self.walk_target_x, self.walk_target_y = nil, nil
			else
				self.x = self.x + move_vec_x / l
				self.y = self.y + move_vec_y / l
			end
		end

		if self.char_tick ~= nil then
			self:char_tick(frame)
		end
	end

	function player:draw()
		love.graphics.setColor(255, 0, 0)
		love.graphics.rectangle("fill", self.x - 5, self.y - 5 -10, 10 * self.health/100, 2)
		love.graphics.setColor(100, 100, 100)
		love.graphics.rectangle("fill", self.x - 5, self.y - 5, 10, 10)
	end

	return require("characters/" .. char)(player)
end

return new_player
