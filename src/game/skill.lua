local skill_mod = {}

local vec_mod = require('viewmath/vec')
local rect_mod = require('viewmath/rect')
local func_mod = require('func')
require('misc')

local BORDER_R, BORDER_G, BORDER_B = 20, 20, 20

function skill_mod.make_blank_skill(player, num)
	assert(type(player) == "table", "wrong player argument in make_blank_skill")
	assert(type(num) == "number", "wrong num argument in make_blank_skill")

	local skill = {}
	skill.task = {}
	skill.owner = player
	skill.num = num
	skill.task.class = skill.owner.char .. "_s" .. tostring(skill.num)

	function skill:icon_rect()
		-- TODO Make this function work with > 4 skills

		local wrapper = self.owner.shape:wrapper()
		local rect = rect_mod.by_left_top_and_size(
			wrapper:left_top() + vec_mod((self.num-1) * (1/3) * wrapper:width() - (self.num-1), -5),
			vec_mod(5, 5)
		)
		return rect
	end

	function skill:is_pressed()
		return self.owner.inputs["skill" .. tostring(self.num)]
	end

	function skill:go()
		local task = clone(self.task)
		task.skill = self
		task.owner = self.owner

		self.owner:add_task(task)
	end

	skill.go_condition = skill.is_pressed

	function skill:tick()
		if func_mod.eval_and_function(self, "go_condition") then
			self:go()
		end
	end

	return skill
end

-- add ons

-- draws the border, and returns the smaller inner rect
function skill_mod.icon_rect_border(rect, viewport)
	assert(rect)
	assert(viewport)

	viewport:draw_world_rect(rect, BORDER_R, BORDER_G, BORDER_B)
	return rect_mod.by_center_and_size(rect:center(), rect:size() - vec_mod(2, 2))
end

function skill_mod.with_fresh_key(skill)
	skill.fresh = true
	func_mod.append_function(skill, "tick", function(self)
		if not self.fresh and not self:is_pressed() then
			self.fresh = true
		end
	end)

	func_mod.append_function(skill.task, "init", function(self)
		self.skill.fresh = false
	end)

	function skill:is_fresh_pressed()
		return self.fresh and self:is_pressed()
	end

	func_mod.append_function(skill, "go_condition", skill.is_fresh_pressed)

	return skill
end

function skill_mod.with_cooldown(skill, cooldown)
	skill.max_cooldown = cooldown
	skill.cooldown = 0

	function skill:tick_cooldown()
		self.cooldown = math.max(0, self.cooldown - FRAME_DURATION)
	end

	func_mod.append_function(skill, "go_condition", function(self) return self.cooldown == 0 end)
	func_mod.append_function(skill, "go", function(self) self.cooldown = self.max_cooldown end)

	func_mod.append_function(skill, "tick", skill.tick_cooldown)

	function skill:draw_cooldown(viewport)
		local rect = skill_mod.icon_rect_border(self:icon_rect(), viewport)

		if self.cooldown == 0 then
			viewport:draw_world_rect(rect, 0, 200, 0)
		else
			viewport:draw_world_rect(rect, 70, 70, 255)

			local red_rect = rect:scale_keep_left_top(vec_mod(1, self.cooldown / self.max_cooldown))
			viewport:draw_world_rect(red_rect, 200, 0, 0)
		end
	end

	skill.draw = skill.draw_cooldown -- This way, self.draw can be overwritten, yet self.draw_cooldown can still be used

	return skill
end

function skill_mod.with_instant(skill, init)
	func_mod.append_function(skill.task, "init", init)
	func_mod.append_function(skill.task, "init", function(self) self.owner:remove_task(self) end)

	return skill
end

function skill_mod.with_dash(skill, range)
	skill.task.dash_traveled_distance = 0
	skill.task.dash_range = range

	func_mod.append_function(skill.task, "tick", function(self)
		assert(self.dash_speed ~= nil, "dash_speed has not been set")

		if self.dash_traveled_distance >= self.dash_range then
			self.owner:remove_task(self)
		else
			local speed = self.dash_speed * FRAME_DURATION
			self.owner.shape = self.owner.shape:move_center(speed)
			self.dash_traveled_distance = self.dash_traveled_distance + speed:length()
		end
	end)

	return task
end



return skill_mod
