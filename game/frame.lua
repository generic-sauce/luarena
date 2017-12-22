local map_mod = require('map')

local frame_mod = {}
require("misc")

local entities_meta = {
	__index = {
		remove = function(self, entity)
			for key, e in pairs(self) do
				if entity == e then
					table.remove(self, key)
				end
			end
		end
	}
}

function frame_mod.initial(chars)
	local frame = {}
	frame.map = map_mod.new()
	frame.entities = setmetatable({}, entities_meta)

	for _, char in pairs(chars) do
		table.insert(frame.entities, require('game/player')(char))
	end

	function frame:tick()
		for _, entity in pairs(self.entities) do
			entity:tick(self)
		end
	end

	function frame:draw(cam)
		self.map:draw(cam)
		for _, entity in pairs(self.entities) do
			entity:draw(cam)
		end
	end

	function frame:clone()
		return clone(self)
	end

	return frame
end

return frame_mod
