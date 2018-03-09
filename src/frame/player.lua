local circle_mod = require('shape/circle')
local rect_mod = require("viewmath/rect")
local polygon_mod = require('shape/polygon')
local vec_mod = require('viewmath/vec')
local collision_map_mod = require('collision/collision_map')
local collision_detection_mod = require('collision/detection')
local dev = require("dev")

RIGHT_KEY = 'd'
UP_KEY = 'w'
LEFT_KEY = 'a'
DOWN_KEY = 's'

S1_KEY = 'j'
S2_KEY = 'k'
S3_KEY = 'l'
S4_KEY = ';'

WALKSPEED = 140 -- units per second

local function generate_walk_task(direction)
	assert(direction)

	local task = {direction = direction, class = "walk"}

	function task:init(entity)
		entity.shape = entity.shape:move_center(self.direction:with_length(WALKSPEED * FRAME_DURATION))
		entity:remove_task(self)
	end

	return task
end

function new_player(char)
	local player = {}

	player.shape = circle_mod.by_center_and_radius(
		vec_mod(200, 200),
		15
	)
	player.health = 100
	player.inputs = { [UP_KEY] = false, [LEFT_KEY] = false, [DOWN_KEY] = false, [RIGHT_KEY] = false, [S1_KEY] = false, [S2_KEY] = false, [S3_KEY] = false, [S4_KEY] = false }
	player.direction_vec = vec_mod(1, 0)

	function player:damage(dmg)
		self.health = math.max(0, self.health - dmg)
		if self.health == 0 then
			self:die()
		end
	end

	function player:die()
		self:add_task({ class = "dead" })
	end

	function player:tick()
		if not self:has_tasks_by_class("dead") then
			local d = self:move_direction()

			if d:length() ~= 0 then
				self.direction_vec = d -- for the case that :direction() is not called
				self:add_task(generate_walk_task(d))
			end

			self:consider_drowning()

			if self.char_tick then
				self:char_tick()
			end
		end
	end

	function player:move_direction()
		local d = vec_mod(0, 0)
		if self.inputs[UP_KEY] then
			d = d + vec_mod(0, -1)
		end

		if self.inputs[LEFT_KEY] then
			d = d + vec_mod(-1, 0)
		end

		if self.inputs[DOWN_KEY] then
			d = d + vec_mod(0, 1)
		end

		if self.inputs[RIGHT_KEY] then
			d = d + vec_mod(1, 0)
		end

		return d
	end

	function player:direction()
		local d = self:move_direction()

		if d:length() ~= 0 then
			self.direction_vec = d -- for the case that :tick() has not yet been called, but another entity reads my :direction()
		end

		return self.direction_vec
	end

	function player:draw_body(viewport)
		viewport:draw_shape(self.shape, 100, 100, 100)
	end

	function player:draw_health(viewport)
		local bar_offset = 10
		local bar_height = 3

		local wrapper = self.shape:wrapper()
		viewport:draw_world_rect(rect_mod.by_left_top_and_size(
			wrapper:left_top() - vec_mod(0, bar_offset),
			vec_mod(wrapper:width() * self.health/100, bar_height)
		), 255, 0, 0)
	end

	function player:draw_skills(viewport)
		local wrapper = self.shape:wrapper()
		for skill=1, 4 do
			local r, g, b
			if self['s' .. tostring(skill) .. '_cooldown'] == 0 then
				r, g, b = 0, 0, 255
			else
				r, g, b = 255, 0, 0
			end

			viewport:draw_world_rect(rect_mod.by_left_top_and_size(
				wrapper:left_top() + vec_mod((skill-1) * (1/3) * wrapper:width() - (skill-1), -5),
				vec_mod(3, 3)
			), r, g, b)
		end
	end

	function player:draw(viewport)
		if not self:has_tasks_by_class("dead") then
			self:draw_body(viewport)
			self:draw_health(viewport)
			self:draw_skills(viewport)
		end
	end

	-- effectively checks, whether you collide with a TILE_NONE
	function player:is_drowning()
		dev.start_profiler("is_drowning", {"drowning"})

		if self:has_tasks_by_class("dash") then
			dev.stop_profiler("is_drowning")
			return false
		end

		assert(self.shape)

		local TILE_SIZE = 64
		local MAP_WIDTH = 16
		local MAP_HEIGHT = 16

		local rect = self.shape:wrapper()

		local min_x = math.floor(rect:left() / TILE_SIZE) + 1
		local max_x = math.ceil(rect:right() / TILE_SIZE) + 1

		local min_y = math.floor(rect:top() / TILE_SIZE) + 1
		local max_y = math.ceil(rect:bottom() / TILE_SIZE) + 1

		if max_x < 1 or
		   min_x > MAP_WIDTH or
		   max_y < 1 or
		   min_y > MAP_HEIGHT then
			dev.stop_profiler("is_drowning")
			return true
		end

		min_x = math.max(min_x, 1)
		max_x = math.min(max_x, MAP_WIDTH)
		min_y = math.max(min_y, 1)
		max_y = math.min(max_y, MAP_HEIGHT)

		for x=min_x, max_x do
			for y=min_y, max_y do
				local tile_kind = frame().map.tiles[(y-1) * MAP_WIDTH + x]

				if tile_kind == collision_map_mod.TILE_NONE then
					local tile_rect = rect_mod.by_left_top_and_size(
						vec_mod((x-1) * TILE_SIZE, (y-1) * TILE_SIZE),
						vec_mod(TILE_SIZE, TILE_SIZE)
					)
					local tile_shape = polygon_mod.by_rect(tile_rect)
					dev.start_profiler("drowning collision-check", {"drowning"})
					if collision_detection_mod(tile_shape, self.shape) then
						dev.stop_profiler("is_drowning")
						dev.stop_profiler("drowning collision-check")
						return false
					end
					dev.stop_profiler("drowning collision-check")
				end
			end
		end
		dev.stop_profiler("is_drowning")
		return true
	end

	function player:consider_drowning()
		if self:is_drowning() then
			self:die()
		end
	end

	return require("characters/" .. char)(player)
end

return new_player
