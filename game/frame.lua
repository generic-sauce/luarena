local frame_mod = {}
local clone_mod = require("game/clone")

function new_player()
	local player = {}

	player.x = 0
	player.y = 0

	function player:update(dt) end
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

	function frame:update(dt)
		for _, entity in pairs(frame.entities) do
			entity:update(dt)
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
