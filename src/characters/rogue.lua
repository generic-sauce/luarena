local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local circle_mod = require('shape/circle')
local skill_mod = require('frame/skill')

local S1_COOLDOWN = 3
local S1_RANGE = 200

local S2_COOLDOWN = 3
local S2_DAMAGE = 25
local S2_RADIUS = 40
local S2_DURATION = 1

return function (rogue)

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

	rogue.skills = {
		(function(skill)
			local skill = skill_mod.make_blank_skill(rogue, 1)
			skill_mod.with_cooldown(skill, S1_COOLDOWN)
			skill_mod.with_fresh_key(skill)
			skill_mod.with_instant(skill, function(self)
				local jump = self.owner:direction():with_length(S1_RANGE)
				self.owner.shape = self.owner.shape:move_center(jump)
			end)

			return skill
		end)(),
		(function(skill)
			local skill = skill_mod.make_blank_skill(rogue, 2)
			skill_mod.with_cooldown(skill, S2_COOLDOWN)
			skill_mod.with_fresh_key(skill)
			skill_mod.with_instant(skill, function(self)
				frame():add(self.owner:new_aoe())
			end)

			return skill
		end)()
	}

	return rogue
end
