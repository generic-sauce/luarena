function table.remove_val(t, val)
	for k, v in pairs(t) do
		if v == val then
			table.remove(t, k)
		end
	end
end

function table.contains(t, val)
	for k, v in pairs(t) do
		if v == val then
			return true
		end
	end
	return false
end

function table.insert_once(t, val)
	if not table.contains(t, val) then
		table.insert(t, val)
	end
end

function table.intersection(t1, t2) -- only call with arrays
	local out = {}
	for _, v in pairs(t1) do
		if table.contains(t2, v) then
			table.insert(out, v)
		end
	end
	return out
end

function table.union(t1, t2) -- only call with arrays
	local out = {}
	for _, v in pairs(t1) do
		table.insert(out, v)
	end
	for _, v in pairs(t2) do
		table.insert_once(out, v)
	end
	return out
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function stringify(t, depth)
	if type(t) == "function" then
		return "<function>"
	end

	if type(t) ~= "table" then
		return "" .. tostring(t)
	end

	if depth == 0 then
		return "<table>"
	end

	local out = "{"
	for k, v in pairs(t)
	do
		if depth then
			out = out .. stringify(k, depth-1) .. "=" .. stringify(v, depth-1) .. ","
		else
			out = out .. stringify(k) .. "=" .. stringify(v) .. ","
		end
	end
	return out .. "}"
end

function clone(state)
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

HASH_SPACE = 2^16

function hash(t)
	if type(t) == "nil" then
		return 1
	elseif type(t) == "boolean" then
		if t then
			return 1
		else
			return 2
		end
	elseif type(t) == "number" then
		return t % HASH_SPACE
	elseif type(t) == "string" then
		if t == "" then
			return 4
		else 
			return (string.byte(t:sub(1,1)) + hash(t:sub(2)) * 2) % HASH_SPACE
		end
	elseif type(t) == "table" then
		local val = 1 + hash(getmetatable(t))
		for x, y in pairs(t) do
			val = val + (hash(x) % (HASH_SPACE/2 + 1)) + hash(y)
		end
		return val % HASH_SPACE
	elseif type(t) == "function" then
		return 2
	elseif type(t) == "userdata" then
		return 5
	else
		print("can't hash type " .. type(t))
	end
end
