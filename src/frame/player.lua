local circle_mod = require('shape/circle')
local rect_mod = require("viewmath/rect")
local vec_mod = require('viewmath/vec')

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

function new_player(char)
	local player = {}

	player.shape = circle_mod.by_center_and_radius(
		vec_mod(200, 200),
		15
	)
	player.health = 100
	player.inputs = { w = false, a = false, s = false, d = false, h = false, j = false, k = false, l = false }
	player.direction_vec = vec_mod(1, 0)

	function player:damage(dmg)
		self.health = math.max(0, self.health - dmg)
	end

	function player:tick(frame)
		local d = self:move_direction()

		if d:length() ~= 0 then
			self.direction_vec = d -- for the case that :direction() is not called
			self:add_task(generate_walk_task(d))
		end

		if self.char_tick then
			self:char_tick(frame)
		end
	end

	function player:move_direction()
		local d = vec_mod(0, 0)
		if self.inputs.w then
			d = d + vec_mod(0, -1)
		end

		if self.inputs.a then
			d = d + vec_mod(-1, 0)
		end

		if self.inputs.s then
			d = d + vec_mod(0, 1)
		end

		if self.inputs.d then
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
		viewport:draw_shape(self.shape, 100, 100, 100)

		local bar_offset = 10
		local bar_height = 3

		local wrapper = self.shape:wrapper()
		viewport:draw_world_rect(rect_mod.by_left_top_and_size(
			wrapper:left_top() - vec_mod(0, bar_offset),
			vec_mod(wrapper:width() * self.health/100, bar_height)
		), 255, 0, 0)
	end

	return require("characters/" .. char)(player)
end

return new_player
