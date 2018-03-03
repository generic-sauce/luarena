local circle_mod = require('shape/circle')
local rect_mod = require("viewmath/rect")
local polygon_mod = require('shape/polygon')
local vec_mod = require('viewmath/vec')
local collision_map_mod = require('collision/collision_map')
local collision_detection_mod = require('collision/detection')

RIGHT_KEY = 'd'
UP_KEY = 'w'
LEFT_KEY = 'a'
DOWN_KEY = 's'

S1_KEY = 'j'
S2_KEY = 'i'
S3_KEY = 'k'
S4_KEY = 'l'

WALKSPEED = 0.7

local function generate_walk_task(direction)
	assert(direction)

	local task = {direction = direction, class = "walk"}

	function task:init(entity, frame)
		entity.shape = entity.shape:move_center(self.direction:with_length(WALKSPEED))
		entity:remove_task(self)
	end

	return task
end

function new_player(char, map)
	assert(map)

	local player = {}

	player.shape = circle_mod.by_center_and_radius(
		vec_mod(200, 200),
		15,
		map
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

	function player:tick(frame)
		if not self:has_tasks_by_class("dead") then
			local d = self:move_direction()

			if d:length() ~= 0 then
				self.direction_vec = d -- for the case that :direction() is not called
				self:add_task(generate_walk_task(d))
			end

			self:consider_drowning()

			if self.char_tick then
				self:char_tick(frame)
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

	function player:draw(viewport)
		if not self:has_tasks_by_class("dead") then
			viewport:draw_shape(self.shape, 100, 100, 100)

			local bar_offset = 10
			local bar_height = 3

			local wrapper = self.shape:wrapper()
			viewport:draw_world_rect(rect_mod.by_left_top_and_size(
				wrapper:left_top() - vec_mod(0, bar_offset),
				vec_mod(wrapper:width() * self.health/100, bar_height)
			), 255, 0, 0)
		end
	end

	-- effectively checks, whether you collide with a TILE_NONE
	function player:is_drowning()
		if self:has_tasks_by_class("dash") then
			return false
		end

		assert(self.shape)
		assert(self.shape.map)

		local TILE_SIZE = 64
		local MAP_WIDTH = 16

		local rect = self.shape:wrapper()
		for x=math.floor(rect:left() / TILE_SIZE) + 1, math.ceil(rect:right() / TILE_SIZE) + 1 do
			for y=math.floor(rect:top() / TILE_SIZE) + 1, math.ceil(rect:bottom() / TILE_SIZE) + 1 do
				local tile_kind = self.shape.map.tiles[(y-1) * MAP_WIDTH + x]

				if tile_kind == collision_map_mod.TILE_NONE then
					local tile_rect = rect_mod.by_left_top_and_size(
						vec_mod((x-1) * TILE_SIZE, (y-1) * TILE_SIZE),
						vec_mod(TILE_SIZE, TILE_SIZE)
					)
					local tile_shape = polygon_mod.by_rect(
						tile_rect,
						self.shape.map
					)
					if collision_detection_mod(tile_shape, self.shape) then
						return false
					end
				end
			end
		end
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
