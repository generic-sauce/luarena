local polygon_mod = require('shape/polygon')
local rect_mod = require("viewmath/rect")
local vec_mod = require('viewmath/vec')

WALKSPEED = 0.7

local function generate_walk_task(walk_target)
	assert(walk_target)

	local task = {walk_target = walk_target, class = "walk"}

	function task:tick(entity, frame)
		local move_vec = self.walk_target - entity.shape:center()
		if move_vec:length() < WALKSPEED then
			entity.shape = entity.shape:with_center(self.walk_target)
			entity:remove_task(self)
		else
			entity.shape = entity.shape:move_center(move_vec:with_length(WALKSPEED))
		end
	end

	return task
end

function new_player(char)
	local player = {}

	player.shape = polygon_mod.by_rect(
		rect_mod.by_center_and_size(
			vec_mod(200, 200),
			vec_mod(20, 20)
		)
	)
	player.health = 100
	player.inputs = { q = false, w = false, e = false, r = false, mouse = vec_mod(-2, -2), click = false, rclick = false }

	function player:damage(dmg)
		self.health = math.max(0, self.health - dmg)
	end

	function player:tick(frame)
		if self.inputs.rclick then
			self:add_task(generate_walk_task(self.inputs.mouse))
		end

		if self.char_tick then
			self:char_tick(frame)
		end
	end

	function player:draw(viewport)
		viewport:draw_world_shape(self.shape, 100, 100, 100)

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
