local frame_mod = {}
require("misc")

function frame_mod.initial(chars)
	local frame = {}
	frame.entities = {}

	for _, char in pairs(chars) do
		table.insert(frame.entities, require('game/player')(char))
	end

	function frame:tick()
		for _, entity in pairs(self.entities) do
			entity:tick()
		end
	end

	function frame:draw()
		for _, entity in pairs(self.entities) do
			entity:draw()
		end
	end

	function frame:clone()
		return clone(self)
	end

	return frame
end

return frame_mod
