local skill_mod = {}

local vec_mod = require('viewmath/vec')
local rect_mod = require('viewmath/rect')
require('misc')

local listify_function = function(obj, name)
	if type(obj[name]) == 'function' then
		obj[name .. "_list"] = {obj[name]}
		obj[name] = function (self, ...)
			for _, f in pairs(obj[name .. '_list']) do
				f(self, ...)
			end
		end
	end
end

local fold_listified = function(obj, name, lambda, start)
	if type(obj[name] == "nil") then
		return start
	elseif type(obj[name] == "function") then
		return obj[name]()
	elseif type(obj[name]) == 'table' then
		return fold(lambda, obj[name], start)
	else
		assert(false)
	end

end

local fold = function(lambda, list, start)
	local out = start
	for _, x in pairs(list) do
		out = lambda(out, x)
	end
	return out
end

function skill_mod.append_function(obj, name, new_function)
	if type(obj[name]) == 'nil' then
		obj[name] = new_function
	elseif type(obj[name]) == 'function' then
		listify_function(obj, name)
		table.insert(obj[name .. "_list"], new_function)
	else
		assert(false, "can't append to obj[name] of type " .. type(obj[name]))
	end
end

-- basics

function skill_mod.make_blank_skill(player, num)
	assert(type(player) == "table", "wrong player argument in make_blank_skill")
	assert(type(num) == "number", "wrong num argument in make_blank_skill")

	local skill = {}
	skill.task = {}
	skill.task.skill = skill
	skill.owner = player
	skill.num = num
	skill.task.class = skill.owner.char .. "_s" .. tostring(skill.num)

	function skill:render_rect()
		-- TODO Make this function work with > 4 skills

		local wrapper = self.owner.shape:wrapper()
		local rect = rect_mod.by_left_top_and_size(
			wrapper:left_top() + vec_mod((self.num-1) * (1/3) * wrapper:width() - (self.num-1), -5),
			vec_mod(3, 3)
		)
		return rect
	end

	function skill:is_pressed()
		return isPressed('S' .. tostring(self.num) .. '_KEY')
	end

	function skill:go()
		local task = clone(self.task)
		self.owner:add_task(task)
	end

	skill.go_condition = skill.is_pressed

	function skill:tick()
		local and_lambda = function(a, b) return a and b end
		if fold_listified(self, "go_condition", and_lambda, true) then
			self:go()
		end
	end

	return skill
end

-- add ons

function skill_mod.with_fresh_key(skill)
	skill.fresh = true
	append_function(skill, "tick", function(self)
		if not self.fresh and not self:is_pressed() then
			self.fresh = true
		end
	end)

	append_function(skill.task, "init", function(self)
		self.skill.fresh = false
	end)

	function skill:is_fresh_pressed()
		return self.fresh and self:is_pressed()
	end

	append_function(skill, "go_condition", skill.is_fresh_pressed)
end

function skill_mod.with_cooldown(skill, cooldown)
	skill.max_cooldown = cooldown
	skill.cooldown = 0

	function skill:tick_cooldown()
		self.cooldown = math.max(0, self.cooldown - FRAME_DURATION)
	end

	append_function(skill, "go_condition", function(self) return self.cooldown == 0 end)
	append_function(skill, "tick", self.tick_cooldown)

	function skill:draw_cooldown(viewport)
		local rect = self:render_rect()

		if self.cooldown == 0 then
			viewport:draw_world_rect(rect, 0, 255, 0)
		else
			viewport:draw_world_rect(rect, 255, 0, 0)

			local height = rect:height() * (self.cooldown / self.max_cooldown)
			local blue_rect = rect_mod.by_left_top_and_size(
				rect:left_top():add_y(rect:height() - height),
				vec_mod(rect:width(), height)
			)
			viewport:draw_world_rect(rect, 0, 0, 255)
		end
	end

	self.draw = self.draw_cooldown -- This way, self.draw can be overwritten, yet self.draw_cooldown can still be used

	return skill
end

return skill_mod
