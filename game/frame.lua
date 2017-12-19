local frame_mod = {}
require("misc")

function new_player()
	local player = {}

	player.x = 0
	player.y = 0
	player.inputs = { q = false, w = false, e = false, r = false, mouse_x = 0, mouse_y = 0 }

	function player:tick()
		if self.inputs.q then
			self.x = self.inputs.mouse_x
			self.y = self.inputs.mouse_y
		end
	end

	function player:draw()
		love.graphics.setColor(100, 100, 100)
		love.graphics.rectangle("fill", self.x, self.y, 10, 10)
	end

	return player
end

function frame_mod.initial(player_count)
	local frame = {}
	frame.entities = {}

	for i=1, player_count do
		table.insert(frame.entities, new_player())
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
