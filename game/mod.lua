local game_mod = {}
local frame_mod = require("game/frame")
local calendar_mod = require("game/calendar")

function game_mod:new()
	local game = {}
	game.frame_history = {}
	game.current_frame = frame_mod.initial()
	game.calendar = calendar_mod.new()

	function game:update(dt)
		table.insert(game.frame_history, game.current_frame.clone())

		game.calendar:handle_user_inputs()
		game.current_frame:update(dt)
	end

	function game:draw()
		game.current_frame:draw()
	end

	return game
end

return game_mod
