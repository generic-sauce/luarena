FRAME_DURATION = 0.005 -- in seconds
INPUT_DELAY = 10
AVG_BACKTRACK_UPDATE_FREQUENCY = 1000

local game_mod = {}
local frame_mod = require("game/frame")
local calendar_mod = require("game/calendar")
require("misc")

function game_mod.new(chars, local_id)
	local game = {}
	game.frame_history = {}
	game.chars = chars
	game.current_frame = frame_mod.initial(chars)
	game.calendar = calendar_mod.new(#chars, local_id)
	game.local_id = local_id
	game.start_time = love.timer.getTime()

	-- frame_id is the oldest frame to be re-calculated
	function game:backtrack(frame_id)
		while frame_id <= #self.frame_history do
			self.frame_history[#self.frame_history] = nil
		end

		if frame_id == 1 then
			self.current_frame = frame_mod.initial(game.chars)
		else
			self.current_frame = self.frame_history[#self.frame_history]:clone()
		end

		local current_time = love.timer.getTime()
		while #self.frame_history * FRAME_DURATION < current_time - self.start_time do
			self:frame_update()
		end
	end

	-- will do calendar:apply_input_changes and backtrack
	function game:apply_input_changes(changed_inputs, player_id, frame_id)
		self.calendar:apply_input_changes(changed_inputs, player_id, frame_id)

		if frame_id <= #self.frame_history then
			self:backtrack(frame_id)
		end
		
	end

	function game:update_local_calendar()
		local changed_inputs = self.calendar:detect_changed_local_inputs()

		if next(changed_inputs) == nil then return end

		self.calendar:apply_input_changes(changed_inputs, self.local_id, #self.frame_history + 1 + INPUT_DELAY)

		self:send({
			tag = "inputs",
			inputs = changed_inputs,
			player_id = self.local_id,
			frame_id = #self.frame_history + 1 + INPUT_DELAY
		})
	end

	function game:frame_update()
		if #self.frame_history % 200 == 0 then
			-- os.execute("paplay beep.wav &")
		end

		self.calendar:apply_to_frame(self.current_frame, #self.frame_history + 1)
		self.current_frame:tick()
		table.insert(self.frame_history, self.current_frame:clone())
	end

	function game:update(dt)
		if love.keyboard.isDown('b') then
			print("backtracking to frame 2")
			self:backtrack(2)
		end

		self.networker:handle_events()
		self:update_local_calendar()

		local current_time = love.timer.getTime()
		while #self.frame_history * FRAME_DURATION < current_time - self.start_time do
			if #self.frame_history % AVG_BACKTRACK_UPDATE_FREQUENCY and self.send_avg_update_packet ~= nil then
					self:send_avg_update_packet() -- Just happens on the server (this is mega hacky!)
			end

			self:update_local_calendar()
			self:frame_update()
		end
	end

	function game:draw()
		self.current_frame:draw()
	end

	return game
end

return game_mod
