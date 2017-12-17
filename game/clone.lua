local clone_mod = {}

function stringify(t)
	if type(t) == "function" then
		return "<function>"
	end

	if type(t) ~= "table" then
		return "" .. tostring(t)
	end

	local out = "{"
	for k, v in pairs(t)
	do
		out = out .. stringify(k) .. "=" .. stringify(v) .. ","
	end
	return out .. "}"
end

function clone_mod.clone(state)
	function pipe_through_map(obj, map)
		if type(obj) ~= "table" then
			return obj
		end

		if map[obj] == nil then
			map[obj] = {}
			clone_state_r(obj, map[obj], map)
		end
		return map[obj]
	end

	function clone_state_r(old, new, map)
		setmetatable(new, pipe_through_map(getmetatable(old), map))

		for k, v in pairs(old) do
			local new_k = pipe_through_map(k, map)
			local new_v = pipe_through_map(v, map)
			new[new_k] = new_v
		end
	end

	return pipe_through_map(state, {})
end

return clone_mod
