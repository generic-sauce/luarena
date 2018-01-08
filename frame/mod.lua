local map_mod = require('map')
local task_mod = require('frame/task')
local collision_mod = require('frame/collision')

local frame_mod = {}
require("misc")

function frame_mod.initial(chars)
	local frame = task_mod(collision_mod({}))
	frame.map = map_mod.new()
	frame.entities = {}

	function frame:init(chars)
		for _, char in pairs(chars) do
			self:add(require('frame/player')(char))
		end
	end

	function frame:add(entity)
		assert(entity.colliders == nil)
		entity.colliders = {}

		assert(entity.tasks == nil)
		entity.tasks = {}
		assert(entity.inactive_tasks == nil)
		entity.inactive_tasks = {}

		function entity:add_task(task)
			table.insert(self.inactive_tasks, {task=task, status="delay"})
		end

		function entity:remove_task(task) -- only works for active tasks
			table.remove_val(self.tasks, task)
		end

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
