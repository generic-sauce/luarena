FRAME_DURATION = 0.005 -- in seconds

local game_mod = {}
local frame_mod = require("game/frame")
local calendar_mod = require("game/calendar")

function game_mod:new(player_count, local_id)
	local game = {}
	game.frame_history = {}
	game.current_frame = frame_mod.initial(player_count)
	game.calendar = calendar_mod.new(player_count, local_id)
	game.local_id = local_id
	game.start_time = love.timer.getTime()

	function game:frame_update()
		table.insert(game.frame_history, game.current_frame.clone())

		-- game.calendar:apply_to_frame(game.current_frame)
		game.current_frame:tick()
	end

	function game:update(dt)
		-- game:update_calendar()

		local current_time = love.timer.getTime()
		while #game.frame_history * FRAME_DURATION < current_time - game.start_time do
			-- game:update_calendar()
			game:frame_update()
		end
	end

	function game:draw()
		game.current_frame:draw()
	end

	return game
end

return game_mod
