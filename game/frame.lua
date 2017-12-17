local frame_mod = {}
local clone_mod = require("game/clone")

function new_player()
	local player = {}

	player.x = 0
	player.y = 0
	player.inputs = { q = false, w = false, e = false, r = false }

	function player:tick()
		if player.inputs.q == true then
			player.x = player.x + 1
		end
	end

	function player:draw()
		love.graphics.setColor(100, 100, 100)
		love.graphics.rectangle("fill", player.x, player.y, 10, 10)
	end

	return player
end

function frame_mod.initial(player_count)
	local frame = {}
	frame.entities = {}

	for i=0, player_count do
		table.insert(frame.entities, new_player())
	end

	function frame:tick()
		for _, entity in pairs(frame.entities) do
			entity:tick()
		end
	end

	function frame:draw()
		for _, entity in pairs(frame.entities) do
			entity:draw()
		end
	end

	function frame:clone()
		return clone_mod.clone(frame)
	end

	return frame
end

return frame_mod
