local visual_map_mod = require('graphics/visual_map')
local collision_mod = require('collision/mod')
local collision_map_mod = require('collision/collision_map')
local task_mod = require('frame/task')
local vec_mod = require('viewmath/vec')
local dev = require('dev')

local frame_mod = {}
require("misc")

function frame_mod.initial(chars, map_seed)
	local frame = {}
	frame.map = visual_map_mod.init_collision_map(collision_map_mod.new(vec_mod(16, 16), map_seed))
	frame.entities = {}
	frame.chars = chars
	frame.scores = {}

	function frame:init()
		collision_mod.init_frame(self)
		task_mod.init_frame(self)

		for _, char in pairs(self.chars) do
			self:add(require('frame/player')(char))
		end

		for i=1, #self.chars do
			self.scores[i] = 0
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
		dev.start_profiler("frame:tick()")

		self:tick_tasks()
		self:tick_collision()

		dev.start_profiler("entities:tick()")
		for _, entity in pairs(self.entities) do
			entity:tick(self)
		end
		dev.stop_profiler("entities:tick()")


		if isPressed('x') then
			if self.dummy then
				self:remove(self.dummy)
			end
			self.dummy = require('frame/player')('dummy')
			self:add(self.dummy)
		end

		self:consider_respawn()

		dev.stop_profiler("frame:tick()")
	end

	-- draw

	function frame:draw(viewport)
		assert(viewport)

		self.map:draw(viewport)
		for _, entity in pairs(self.entities) do
			entity:draw(viewport)
		end

		-- render score
		local str = ""
		for i = 1, #self.chars do
			str = str .. tostring(self.scores[i]) .. ":"
		end
		str = str:sub(1, -2) -- remove last ":"

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.print(str)
	end

	function frame:clone()
		return clone(self)
	end

	-- respawn

	function frame:consider_respawn()
		local players_alive = 0
		for i = 1, #self.chars do
			if not self.entities[i]:has_tasks_by_class("dead") then
				players_alive = players_alive + 1
			end
		end

		if (#self.chars == 1 and players_alive == 0) or (#self.chars > 1 and players_alive <= 1) then
			self:respawn()
		end
	end

	function frame:update_score()
		if #self.chars == 1 then return end

		for i = 1, #self.chars do
			local player = self.entities[i]
			if not player:has_tasks_by_class("dead") then
				self.scores[i] = self.scores[i] + 1
			end
		end
	end

	function frame:respawn_player(player)
		player.tasks = {}
		player.inactive_tasks = {}
		player.health = 100
		player.shape = player.shape:with_center(vec_mod(200, 200))
	end

	function frame:respawn()
		self:update_score()
		for i = 1, #self.chars do
			self:respawn_player(self.entities[i])
		end

		while #self.entities > #self.chars do
			table.remove(self.entities, #self.chars + 1)
		end
	end

	frame:init()

	return frame
end

return frame_mod
