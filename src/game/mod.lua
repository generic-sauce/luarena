FRAME_DURATION = 0.005 -- in seconds
INPUT_DELAY = 10
BACKTRACK_BALANCE_INTERVAL = 2000
FRAME_HISTORY_LENGTH = math.ceil(5 / FRAME_DURATION)

local game_mod = {}
local frame_mod = require("frame/mod")
local calendar_mod = require("game/calendar")
local cam_mod = require("graphics/cam")
local vec_mod = require('viewmath/vec')
local dev = require('dev')

require("misc")

local NO_FRAME = {}

function game_mod.new(chars, local_id)
	local game = {}
	game.current_frame = frame_mod.initial(chars)
	game.cam = -- choose one:
			cam_mod.following(local_id)
			-- cam_mod.fixed(game.current_frame.map:rect():center())
	game.frame_history = {}
	game.frame_counter = 0 -- in the first frames the same as #frame_history
	game.chars = chars
	game.calendar = calendar_mod.new(#chars, local_id)
	game.local_id = local_id
	game.start_time = love.timer.getTime()

	for i=1, FRAME_HISTORY_LENGTH do
		game.frame_history[i] = NO_FRAME
	end

	-- frame_id is the oldest frame to be re-calculated
	function game:backtrack(frame_id)
		dev.start_profiler("backtrack", {"backtrack"})

		local c = 0
		local fh_size = self.frame_counter
		while frame_id <= self.frame_counter do
			c = c + 1
			set(self.frame_history, self.frame_counter, NO_FRAME)
			self.frame_counter = self.frame_counter - 1
		end

		if frame_id == 1 then
			self.current_frame = frame_mod.initial(game.chars)
		else
			local old_frame = get(self.frame_history, self.frame_counter)
			assert(old_frame ~= NO_FRAME, "backtracking too far!")
			self.current_frame = old_frame:clone()
		end

		local current_time = love.timer.getTime()
		while self.frame_counter * FRAME_DURATION < current_time - self.start_time do
			self:frame_update()
		end
		dev.debug("went back " .. c .. " frames (" .. fh_size .. " -> " .. frame_id-1 .. " -> " .. self.frame_counter .. ")", {"backtrack"})

		dev.stop_profiler("backtrack")
	end

	-- will do calendar:apply_input_changes and backtrack
	function game:apply_input_changes(input_packets)
		local oldest_frame_id = nil
		for _, p in pairs(input_packets) do
			self.calendar:apply_input_changes(p.inputs, p.player_id, p.frame_id)
			if oldest_frame_id == nil or oldest_frame_id > p.frame_id then
				oldest_frame_id = p.frame_id
			end
		end

		if oldest_frame_id <= self.frame_counter then
			self:backtrack(oldest_frame_id)
		end
	end

	function game:update_local_calendar()
		local viewport = self.cam:viewport(self.current_frame)
		local changed_inputs = self.calendar:detect_changed_local_inputs(viewport)

		if next(changed_inputs) == nil then return end

		self.calendar:apply_input_changes(changed_inputs, self.local_id, self.frame_counter + 1 + INPUT_DELAY)

		self:send({
			tag = "inputs",
			inputs = changed_inputs,
			player_id = self.local_id,
			frame_id = self.frame_counter + 1 + INPUT_DELAY
		})
	end

	function game:frame_update()
		dev.start_profiler("frame_update")

		self.calendar:apply_to_frame(self.current_frame, self.frame_counter + 1)
		self.current_frame:tick()
		set(self.frame_history, self.frame_counter, self.current_frame:clone())
		self.frame_counter = self.frame_counter + 1

		dev.stop_profiler("frame_update")
	end

	function game:update(dt)
		self:handle_debug_hotkeys()
		self.networker:handle_events()
		self:update_local_calendar()

		local current_time = love.timer.getTime()
		while self.frame_counter * FRAME_DURATION < current_time - self.start_time do
			if self.gamemaster_update then
				self:gamemaster_update()
			end

			self:update_local_calendar()
			self:frame_update()
		end
	end

	function game:draw()
		local viewport = self.cam:viewport(self.current_frame)
		self.current_frame:draw(viewport)
	end

	function game:handle_debug_hotkeys()
		-- b => backtrack
		if love.keyboard.isDown('b') then
			print("backtracking to frame 2")
			self:backtrack(2)
		end

		-- p => print profilers
		if love.keyboard.isDown('p') then
			if not p_pressed then
				dev.dump_profilers()
				p_pressed = true
			end
		else
			p_pressed = nil
		end

		-- c => clear profilers
		if love.keyboard.isDown('c') then
			dev.profilers = {}
		end
	end

	return game
end

return game_mod
