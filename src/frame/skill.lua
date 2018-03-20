local skill_mod = {}

local vec_mod = require('viewmath/vec')
local rect_mod = require('viewmath/rect')

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

function skill_mod.make_blank_skill(player, num)
	local skill = {}
	skill.task = {}
	skill.player = player
	skill.num = num
	skill.task.class = self.player.char .. "_s" .. tostring(self.num)

	function skill:render_rect()
		-- TODO Make this function work with > 4 skills

		local wrapper = self.player.shape:wrapper()
		local rect = rect_mod.by_left_top_and_size(
			wrapper:left_top() + vec_mod((self.num-1) * (1/3) * wrapper:width() - (self.num-1), -5),
			vec_mod(3, 3)
		)
		return rect
	end

	function skill:is_pressed()
		return isPressed('S' .. tostring(self.num) .. '_KEY')
	end

	return skill
end

function skill_mod.make_default_skill(player, num)
	local skill = skill_mod.make_blank_skill(player, num)
	skill = skill_mod.with_cooldown(skill, nil) -- to be set by the user

	return skill
end

-- TODO key-press stuff

function skill_mod.with_cooldown(skill, cooldown)
	skill.max_cooldown = cooldown
	skill.cooldown = 0

	function skill:tick_cooldown()
		self.cooldown = math.max(0, self.cooldown - FRAME_DURATION)
	end

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
