local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local circle_mod = require('shape/circle')

local S1_COOLDOWN = 3
local S1_RANGE = 200

local S2_COOLDOWN = 3
local S2_DAMAGE = 25
local S2_RADIUS = 40
local S2_DURATION = 1

return function (rogue)

	rogue.s1_cooldown = 0
	rogue.s2_cooldown = 0

	function rogue:new_aoe()
		local aoe = {}

		aoe.owner = self
		aoe.shape = circle_mod.by_center_and_radius(self.shape:center(), S2_RADIUS)
		aoe.life_counter = S2_DURATION

		function aoe:initial_damage()
			for _, entity in pairs(frame():find_colliders(self.shape)) do
				if entity ~= self
					and entity ~= self.owner
					and entity.damage then
						entity:damage(S2_DAMAGE)
				end
			end
		end

		function aoe:tick()
			self.life_counter = self.life_counter - FRAME_DURATION
			if self.life_counter <= 0 then
				frame():remove(self)
			end
		end

		function aoe:draw(viewport)
			viewport:draw_shape(self.shape, 100, 100, 100, 100)
		end

		aoe:initial_damage()

		return aoe
	end


	function rogue:char_tick()
		self.s1_cooldown = math.max(0, self.s1_cooldown - FRAME_DURATION)
		self.s2_cooldown = math.max(0, self.s2_cooldown - FRAME_DURATION)

		if self.inputs[S1_KEY] and self.s1_cooldown <= 0 then
			self.s1_cooldown = S1_COOLDOWN

			local jump = self:direction():with_length(S1_RANGE)

			self.shape = self.shape:move_center(jump)
		end

		if self.inputs[S2_KEY] and self.s2_cooldown <= 0 then
			self.s2_cooldown = S2_COOLDOWN
			frame():add(self:new_aoe())
		end
	end

	return rogue
end
