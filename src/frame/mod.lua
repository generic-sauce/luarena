local visual_map_mod = require('graphics/visual_map')
local collision_mod = require('collision/mod')
local collision_map_mod = require('collision/collision_map')
local task_mod = require('frame/task')
local vec_mod = require('viewmath/vec')

local frame_mod = {}
require("misc")

function frame_mod.initial(chars)
	local frame = {}
	frame.map = visual_map_mod.init_collision_map(collision_map_mod.new(vec_mod(16, 16)))
	frame.entities = {}
	frame.chars = chars

	function frame:init()
		collision_mod.init_frame(self)
		task_mod.init_frame(self)

		for _, char in pairs(self.chars) do
			self:add(require('frame/player')(char))
		end
	end

	function frame:add(entity)
		assert(entity)

		collision_mod.init_entity(entity)
		task_mod.init_entity(entity)

		table.insert(self.entities, entity)
	end

	function frame:remove(entity)
		for _, e in pairs(self.entities) do
			if table.contains(e.colliders, entity) then
				table.remove_val(e.colliders, entity)
				collision_mod.call_on_exit_collider(e, self, entity)
			end
		end
		table.remove_val(self.entities, entity)
	end

	function frame:tick()
		self:tick_tasks()
		self:tick_collision()
		for _, entity in pairs(self.entities) do
			entity:tick(self)
		end


		if love.keyboard.isDown('x') then
			if self.dummy then
				self:remove(self.dummy)
			end
			self.dummy = require('frame/player')('dummy')
			self:add(self.dummy)
		end

		self:consider_respawn()
	end

	-- draw

	function frame:draw(viewport)
		assert(viewport)

		self.map:draw(viewport)
		for _, entity in pairs(self.entities) do
			entity:draw(viewport)
		end
	end

	function frame:clone()
		return clone(self)
	end

	-- respawn

	function frame:consider_respawn()
		local players_alive = 0
		for i = 1, #self.chars, 1 do
			if not self.entities[i]:has_tasks_by_class("dead") then
				players_alive = players_alive + 1
			end
		end

		if players_alive <= 1 then
			self:respawn()
		end
	end

	function frame:respawn()
		for i = 1, #self.chars do
			local player = self.entities[i]
			for _, task in pairs(player:get_tasks_by_class("dead")) do
				player:remove_task(task)
			end
			player.health = 100
		end
	end

	frame:init()

	return frame
end

return frame_mod
