local visual_map_mod = require('graphics/visual_map')
local collision_mod = require('collision/mod')
local collision_map_mod = require('collision/collision_map')
local task_mod = require('frame/task')
local vec_mod = require('viewmath/vec')
local dev = require('dev')

local frame_mod = {}
require("misc")

local function apply_spawn_protection(player)
	local SPAWN_PROTECT_DURATION = 2

	local task = { class = "spawn_protection", remaining_duration = SPAWN_PROTECT_DURATION}

	function task:tick()
		self.remaining_duration = self.remaining_duration - FRAME_DURATION
		if self.remaining_duration <= 0 then
			self.owner:remove_task(self)
		end
	end

	player:add_task(task)
end

function frame_mod.initial(chars, map_seed)
	local frame = {}
	frame.map = visual_map_mod.init_collision_map(collision_map_mod.new(vec_mod(16, 16), map_seed))
	frame.entities = {}
	frame.chars = chars
	frame.scores = {}

	function frame:init_entities()
		self.entities = {}
		for _, char in pairs(self.chars) do
			local player = require('frame/player')(char)
			self:add(player)
			apply_spawn_protection(player)
		end
	end

	function frame:init()
		collision_mod.init_frame(self)
		task_mod.init_frame(self)

		self:init_entities()

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

	function frame:respawn()
		self:update_score()
		self:init_entities()
	end

	frame:init()

	return frame
end

return frame_mod
