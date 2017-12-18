FRAME_DURATION = 0.005 -- in seconds

local game_mod = {}
local frame_mod = require("game/frame")
local calendar_mod = require("game/calendar")
local packetizer_mod = require("packetizer")
require("misc")

function game_mod.new(player_count, local_id)
	local game = {}
	game.frame_history = {}
	game.current_frame = frame_mod.initial(player_count)
	game.calendar = calendar_mod.new(player_count, local_id)
	game.local_id = local_id
	game.start_time = love.timer.getTime()

	-- frame_id is the oldest frame to be re-calculated
	function game:backtrack(frame_id)
		while frame_id <= #self.frame_history do
			self.frame_history[#self.frame_history] = nil
		end

		if frame_id == 1 then
			self.current_frame = frame_mod.initial(player_count)
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

		self.calendar:apply_input_changes(changed_inputs, self.local_id, #self.frame_history + 1)

		local p = packetizer_mod.inputs_to_packet(changed_inputs, self.local_id, #self.frame_history + 1)
		self:send(p)
	end

	function game:frame_update()
		table.insert(self.frame_history, self.current_frame:clone())

		self.calendar:apply_to_frame(self.current_frame)
		self.current_frame:tick()
	end

	function game:update(dt)
		print("calendar-hash = " .. tostring(hash(self.calendar)) .. ";\tframe-hash = " .. tostring(hash(self.current_frame)))
		self.networker:handle_events()
		self:update_local_calendar()

		local current_time = love.timer.getTime()
		while #self.frame_history * FRAME_DURATION < current_time - self.start_time do
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
