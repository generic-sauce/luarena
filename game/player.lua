local rect_mod = require("space/rect")
local vec_mod = require('space/vec')

function new_player(char)
	local player = {}

	player.shape = rect_mod.by_center_and_size(
		vec_mod(0, 0),
		vec_mod(10, 10)
	)
	player.health = 100
	player.walk_target = nil
	player.inputs = { q = false, w = false, e = false, r = false, mouse_x = 0, mouse_y = 0, click = false, rclick = false }

	function player:damage(dmg)
		self.health = math.max(0, self.health - dmg)
	end

	function player:tick(frame)
		if self.inputs.rclick then
			self.walk_target = vec_mod(self.inputs.mouse_x, self.inputs.mouse_y)
		end

		if self.walk_target ~= nil then
			local move_vec = self.walk_target - self.shape:center()
			if move_vec:length() < 1 then
				self.shape = self.shape:with_center_keep_size(self.walk_target)
				self.walk_target = nil
			else
				self.shape.center_vec = self.shape:center() + move_vec:normalized()
			end
		end

		if self.char_tick ~= nil then
			self:char_tick(frame)
		end
	end

	function player:draw(cam)
		cam:draw_world_rect(self.shape, 100, 100, 100)

		local bar_offset = 10
		local bar_height = 3
		cam:draw_world_rect(rect_mod.by_left_top_and_size(
			self.shape:left_top() - vec_mod(0, bar_offset),
			vec_mod(self.shape:size().x * self.health/100, bar_height)
		), 255, 0, 0)
	end

	return require("characters/" .. char)(player)
end

return new_player
