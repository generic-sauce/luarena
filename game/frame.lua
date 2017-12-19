local frame_mod = {}
require("misc")

function new_player(char)
	local player = {}

	player.x = 0
	player.y = 0
	player.walk_target_x, player.walk_target_y = nil, nil
	player.inputs = { q = false, w = false, e = false, r = false, mouse_x = 0, mouse_y = 0, click = false, rclick = false }

	function player:tick()
		if self.inputs.rclick then
			self.walk_target_x = self.inputs.mouse_x
			self.walk_target_y = self.inputs.mouse_y
		end

		if self.walk_target_x ~= nil and self.walk_target_y ~= nil then
			local move_vec_x  = (self.walk_target_x - self.x)
			local move_vec_y  = (self.walk_target_y - self.y)
			local l = math.sqrt(move_vec_x^2 + move_vec_y^2)
			self.x = self.x + move_vec_x / l
			self.y = self.y + move_vec_y / l
		end
	end

	function player:draw()
		love.graphics.setColor(100, 100, 100)
		love.graphics.rectangle("fill", self.x, self.y, 10, 10)
	end

	return require("characters/" .. char)(player)
end

function frame_mod.initial(chars)
	local frame = {}
	frame.entities = {}

	for _, char in pairs(chars) do
		table.insert(frame.entities, new_player(char))
	end

	function frame:tick()
		for _, entity in pairs(self.entities) do
			entity:tick()
		end
	end

	function frame:draw()
		for _, entity in pairs(self.entities) do
			entity:draw()
		end
	end

	function frame:clone()
		return clone(self)
	end

	return frame
end

return frame_mod
