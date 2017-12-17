FRAME_DURATION = 0.005 -- in seconds

local game_mod = {}
local frame_mod = require("game/frame")
local calendar_mod = require("game/calendar")
local packetizer_mod = require("packetizer")

function game_mod.new(player_count, local_id)
	local game = {}
	game.frame_history = {}
	game.current_frame = frame_mod.initial(player_count)
	game.calendar = calendar_mod.new(player_count, local_id)
	game.local_id = local_id
	game.start_time = love.timer.getTime()

	-- frame_id is the oldest frame to be re-calculated
	function game:backtrack(frame_id)
		print("recalculating since (including) " .. frame_id)

		for i=1, #game.frame_history do
			if frame_id <= #game.frame_history then
				game.frame_history[#game.frame_history] = nil
			else
				break
			end
		end

		if frame_id == 1 then
			print("wot?")
			game.current_frame = frame_mod.initial(player_count)
		else
			-- TODO this causes bad things!
			game.current_frame = game.frame_history[#game.frame_history].clone()
		end

		local current_time = love.timer.getTime()
		while #game.frame_history * FRAME_DURATION < current_time - game.start_time do
			game:frame_update()
		end
	end

	-- will do calendar:apply_input_changes and backtrack
	function game:apply_input_changes(changed_inputs, player_id, frame_id)
		game.calendar:apply_input_changes(changed_inputs, player_id, frame_id)

		if frame_id <= #game.frame_history then
			game:backtrack(frame_id)
		end
		
	end

	function game:update_local_calendar()
		local changed_inputs = game.calendar:detect_changed_local_inputs()

		if next(changed_inputs) == nil then return end

		game.calendar:apply_input_changes(changed_inputs, game.local_id, #game.frame_history + 1)

		local p = packetizer_mod.inputs_to_packet(changed_inputs, game.local_id, #game.frame_history + 1)
		game:send(p)
	end

	function game:frame_update()
		table.insert(game.frame_history, game.current_frame.clone())

		game.calendar:apply_to_frame(game.current_frame)
		game.current_frame:tick()
	end

	function game:update(dt)
		game.networker:handle_events()
		game:update_local_calendar()

		local current_time = love.timer.getTime()
		while #game.frame_history * FRAME_DURATION < current_time - game.start_time do
			game:update_local_calendar()
			game:frame_update()
		end
	end

	function game:draw()
		game.current_frame:draw()
	end

	return game
end

return game_mod
