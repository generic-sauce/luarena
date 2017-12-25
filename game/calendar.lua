local vec_mod = require('space/vec')

local calendar_mod = {} -- keeps track of the history of pressed keys for all players

function calendar_mod.new(player_count, local_id)
	local calendar = {}

	calendar.player_count = player_count
	calendar.local_id = local_id

	calendar.playertable = {} -- Map<PlayerId, Map<Key, List<{value=<bool>, frame_id=<frame_id> }>>>
	for i=1, player_count do
		table.insert(calendar.playertable, {
			q={{value=false, frame_id=1}},
			w={{value=false, frame_id=1}},
			e={{value=false, frame_id=1}},
			r={{value=false, frame_id=1}},
			mouse_x={{value=0, frame_id=1}}, -- in world-coordinates
			mouse_y={{value=0, frame_id=1}}, -- in world-coordinates
			click={{value=false, frame_id=1}},
			rclick={{value=false, frame_id=1}},
		})
	end

	function calendar:read_inputs(player_id, frame_id) -- frame_id == nil searches for newest
		local inputs = {}
		for key, hist in pairs(self.playertable[player_id]) do
			for i=1, #hist do
				local hist_entry = hist[#hist - i + 1]
				if frame_id == nil or hist_entry.frame_id <= frame_id then
					inputs[key] = hist_entry.value
					break
				end
			end
		end

		return inputs
	end

	function calendar:apply_to_frame(f, frame_id)
		for i=1, player_count do
			f.entities[i].inputs.mouse = vec_mod(-1, -1)

			local inputs = self:read_inputs(i, frame_id)
			for key, value in pairs(inputs) do
				if key == "mouse_x" then
					f.entities[i].inputs.mouse = f.entities[i].inputs.mouse:with_x(value)
				elseif key == "mouse_y" then
					f.entities[i].inputs.mouse = f.entities[i].inputs.mouse:with_y(value)
				else
					f.entities[i].inputs[key] = value
				end
			end
		end
	end

	function calendar:detect_changed_local_inputs(viewport)
		local inputs = {}
		inputs.q = love.keyboard.isDown('q')
		inputs.w = love.keyboard.isDown('w')
		inputs.e = love.keyboard.isDown('e')
		inputs.r = love.keyboard.isDown('r')

		local mouse = vec_mod(love.mouse.getPosition())
		mouse = viewport:screen_to_world_vec(mouse)

		inputs.mouse_x, inputs.mouse_y = mouse.x, mouse.y
		local major, minor = love.getVersion()
		if major == 0 and minor < 10 then
			inputs.click = love.mouse.isDown("l")
			inputs.rclick = love.mouse.isDown("r")
		else
			inputs.click = love.mouse.isDown(1)
			inputs.rclick = love.mouse.isDown(2)
		end

		local old_inputs = self:read_inputs(self.local_id, nil)
		local changed_inputs = {}

		for key, is_pressed in pairs(inputs) do
			if old_inputs[key] ~= is_pressed then
				changed_inputs[key] = is_pressed
			end
		end

		return changed_inputs
	end

	function calendar:apply_input_changes(inputs, player_id, frame_id)
		for key, is_pressed in pairs(inputs) do
			table.insert(self.playertable[player_id][key], {value=is_pressed, frame_id=frame_id})
		end
	end

	return calendar
end

return calendar_mod
