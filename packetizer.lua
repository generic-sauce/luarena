local packetizer_mod = {}

-- returns inputs, player_id, frame_id
function packetizer_mod.packet_to_inputs(p)
	local inputs = {}
	local player_id, frame_id

	if p:sub(1, 1) ~= "i" then
		print("malformed packet! (doesn't start with 'i')")
		os.exit(1)
	end

	local index = p:find(",")
	if index == nil then
		print("malformed packet! (contains no ',')")
		os.exit(1)
	end

	player_id = tonumber(p:sub(2, index - 1))
	p = p:sub(index + 1)

	index = p:find(",")
	if index == nil then
		print("malformed packet! (contains no second ',')")
		os.exit(1)
	end

	frame_id = tonumber(p:sub(1, index - 1))
	p = p:sub(index + 1)

	while true do
		local index0, index1 = p:find("0"), p:find("1")
		local index
		if index0 ~= nil and index1 ~= nill then
			index = math.min(index0, index1)
		elseif index0 ~= nil then
			index = index0
		elseif index1 ~= nil then
			index = index1
		else
			break
		end

		inputs[p:sub(1, index - 1)] = tonumber(p:sub(index, index))
		p = p:sub(index + 1)
	end

	return inputs, player_id, frame_id
end

function packetizer_mod.inputs_to_packet(inputs, player_id, frame_id)
	local p = "i" .. tostring(player_id) .. "," .. tostring(frame_id) .. ","
	for key, value in pairs(inputs) do
		if value == true then
			p = p .. key .. "1"
		else
			p = p .. key .. "0"
		end
	end
	return p
end

return packetizer_mod
