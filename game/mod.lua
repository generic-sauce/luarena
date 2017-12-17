local game_mod = {}
local frame_mod = require("game/frame")

function game_mod:new()
	local game = {}
	game.frame_history = {}
	game.current_frame = frame_mod.initial()
	game.calendar = {} -- list of user-events
	game.frame_counter = 1 -- represen

	function game:update(dt)
		table.insert(game.frame_history, game.current_frame.clone())

		game.frame_counter = game.frame_counter + 1

		game.current_frame:update(dt)
	end

	function game:draw()
		game.current_frame:draw()
	end

	return game
end

return game_mod
