local map_mod = require('map')
local collision_mod = require('frame/collision')
local task_mod = require('frame/task')

local frame_mod = {}
require("misc")

function frame_mod.initial(chars)
	local frame = {}
	frame.map = map_mod.new()
	frame.entities = {}

	function frame:init(chars)
		collision_mod.init_frame(self)
		task_mod.init_frame(self)

		for _, char in pairs(chars) do
			self:add(require('frame/player')(char))
		end
	end

	function frame:add(entity)
		assert(entity ~= nil)

		collision_mod.init_entity(entity)
		task_mod.init_entity(entity)

		table.insert(self.entities, entity)
	end

	function frame:remove(entity)
		for _, e in pairs(self.entities) do
			if table.contains(e.colliders, entity) then
				if e.on_exit_collider ~= nil then e:on_exit_collider(self, entity) end
				table.remove_val(e.colliders, entity)
			end
		end
		table.remove_val(self.entities, entity)
	end

	function frame:tick()
		self:tick_tasks()
		self:tick_collision()
	end

	function frame:draw(viewport)
		assert(viewport ~= nil)

		self.map:draw(viewport)
		for _, entity in pairs(self.entities) do
			entity:draw(viewport)
		end
	end

	function frame:clone()
		return clone(self)
	end

	frame:init(chars)

	return frame
end

return frame_mod
