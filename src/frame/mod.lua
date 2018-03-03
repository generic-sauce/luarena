local visual_map_mod = require('graphics/visual_map')
local collision_mod = require('collision/mod')
local collision_map_mod = require('collision/collision_map')
local task_mod = require('frame/task')
local vec_mod = require('viewmath/vec')

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
			self:add(require('frame/player')(char, self.map))
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
		self:tick_tasks()
		self:tick_collision()
		for _, entity in pairs(self.entities) do
			entity:tick(self)
		end


		if love.keyboard.isDown('x') then
			if self.dummy then
				self:remove(self.dummy)
			end
			self.dummy = require('frame/player')('dummy', self.map)
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
		-- Don't do this in Singleplayer
		if #self.chars == 1 then
			local player = self.entities[1]
			if player:has_tasks_by_class("dead") then
				self:respawn_player(player)
			end
			return
		end

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

	function frame:respawn_player(player)
		local tasks = player:get_tasks_by_class("dead")
		if #tasks > 0 then
			for _, task in pairs(tasks) do
				player:remove_task(task)
			end
		end
		player.health = 100
		player.shape = player.shape:with_center(vec_mod(200, 200))
	end

	function frame:respawn()
		for i = 1, #self.chars do
			local player = self.entities[i]
			local tasks = player:get_tasks_by_class("dead")
			-- if you are dead
			if #tasks > 0 then
				self:respawn_player(player)
			else
				-- otherwise you get a score
				self.scores[i] = self.scores[i] + 1
			end
		end
	end

	frame:init()

	return frame
end

return frame_mod
