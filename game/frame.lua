local frame_mod = {}
local clone_mod = require("game/clone")

function frame_mod.initial()
	local frame = {}
	frame.entities = {}

	function frame:update(dt)
		for _, entity in pairs(frame.entities) do
			entity:update(dt)
		end
	end

	function frame:draw()
		for _, entity in pairs(frame.entities) do
			entity:draw()
		end
	end

	function frame:clone()
		return clone_mod.clone(frame)
	end

	return frame
end

return frame_mod
