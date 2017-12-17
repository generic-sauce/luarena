local calendar_mod = {} -- keeps track of the history of pressed keys for all players

function initial_inputstate()
	return { q = false, w = false, e = false, r = false }
end

function calendar_mod.new()
	local calendar = {}

	calendar.playertable = {}
	-- TODO init playertable using initial_inputstate()

	function calendar:detect_user_inputs()
		local inputs = {}
		-- TODO detect inputs, which have been pressed/released (on the local computer)
		return inputs
	end

	function calendar:handle_user_inputs()
		local inputs = calendar:detect_user_inputs()
		-- TODO
	end

	return calendar
end

return calendar_mod
