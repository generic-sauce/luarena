local frame_mod = {}
local clone_mod = require("game/clone")

function new_player()
	local player = {}

	player.x = 0
	player.y = 0
	player.inputs = { q = false, w = false, e = false, r = false }

	function player:tick()
		if self.inputs.q == true then
			self.x = self.x + 1
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
		return clone_mod.clone(self)
	end

	return frame
end

return frame_mod
