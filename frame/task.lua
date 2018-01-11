require('misc')

local task_mod = {}

local TASK_CLASSMAP = {
	skill = {},
	move = {},
	walk = {"move"},
	dash = {"move"},
	channel = {"skill"},

	riven_q = {"skill"},
	riven_q_dash = {"dash"},

	u1_q = {"skill"},
	u1_w = {"skill"},
	u1_e_walk = {"skill", "walk"},
	u1_e_dash = {"skill", "dash"},
	u1_r = {"skill"}
}

local function find_superclasses(class)
	assert(type(class) == "string", "find_superclasses(): class is not string!")

	local superclasses = {class}
	for _, super in pairs(TASK_CLASSMAP[class]) do
		for _, nested_super in pairs(find_superclasses(super)) do
			if not table.contains(superclasses, nested_super) then -- necessary? -- I guess so, you wouldn't like having the same class in `superclasses` multiple times
				table.insert(superclasses, nested_super)
			end
		end
	end
	return superclasses
end

local function find_subclasses(class)
	local subs = {class}
	for sub, sub_supers in pairs(TASK_CLASSMAP) do
		if table.contains(sub_supers, class) then
			for _, subsub in pairs(find_subclasses(sub)) do
				if not table.contains(subs, subsub) then
					table.insert(subs, subsub)
				end
			end
		end
	end
	return subs
end

local function build_task_relation(syntaxed_task_relation)
	local out = {}

	for k, _ in pairs(TASK_CLASSMAP) do
		out[k] = {}
		for k2, _ in pairs(TASK_CLASSMAP) do
			out[k][k2] = "none"
		end
	end

	for _, entry in pairs(syntaxed_task_relation) do
		for _, old in pairs(entry.old) do
			for _, new in pairs(entry.new) do
				for _, oldsub in pairs(find_subclasses(old)) do
					for _, newsub in pairs(find_subclasses(new)) do
						assert(out[oldsub][newsub] == "none") -- or out[oldsub][newsub] == entry.relation
						out[oldsub][newsub] = entry.relation
					end
				end
			end
		end
	end

	return out
end

-- TASK_RELATION[<old>][<new>]
local TASK_RELATION = build_task_relation({
	{old = {"walk", "channel"}, new = {"walk", "channel"}, relation = "cancel"},
	{old = {"walk"}, new = {"riven_q_dash" --[[ I think not all dashes should cancel walking]]}, relation = "cancel"}
})

assert("cancel" == TASK_RELATION['walk']['walk'])

local function get_relation_partners(tasks, task, rel)
	assert(task.class ~= nil, "get_relation_partners(): task.class == nil")

	local partners = {}
	for _, active_task in pairs(tasks) do
		assert(active_task.class ~= nil, "get_relation_partners(): active_task.class == nil")
		if active_task ~= task and TASK_RELATION[active_task.class][task.class] == rel
			and not table.contains(partners, active_task) then
			table.insert(partners, active_task)
		end
	end
	return partners
end

local function is_in_relation(tasks, task, rel)
	return #get_relation_partners(tasks, task, rel) > 0
end

function task_mod.init_frame(frame)
	function frame:tick_tasks()
		for _, entity in pairs(self.entities) do
			for key, task in pairs(entity.inactive_tasks) do
				if is_in_relation(entity.tasks, task.task, "prevent") then
					table.remove(entity.inactive_tasks, key)
					if task.task.on_prevent ~= nil then
						task.task:on_prevent(entity, self)
					end
				elseif not is_in_relation(entity.tasks, task.task, "delay") then
					table.remove(entity.inactive_tasks, key)
					table.insert(entity.tasks, task.task)
					if task.task.init ~= nil and task.status == "delay" then
						task.task:init(entity, self)
					end

					for _, partner in pairs(get_relation_partners(entity.tasks, task.task, "cancel")) do
						table.remove_val(entity.tasks, partner)
						if partner.on_cancel ~= nil then
							partner:on_cancel(entity, self)
						end
					end

					for _, partner in pairs(get_relation_partners(entity.tasks, task.task, "pause")) do
						table.remove_val(entity.tasks, partner)
						table.insert(entity.inactive_tasks, {status="pause", task=partner})
						if partner.on_pause ~= nil then
							partner:on_pause(entity, self)
						end
					end
				end
			end

			for _, task in pairs(entity.tasks) do
				if task.tick ~= nil then
					task:tick(entity, self)
				end
			end
		end
	end
end

function task_mod.init_entity(entity)
	assert(entity.tasks == nil)
	entity.tasks = {}
	assert(entity.inactive_tasks == nil)
	entity.inactive_tasks = {}

	function entity:add_task(task)
		table.insert(self.inactive_tasks, {task=task, status="delay"})
	end

	function entity:remove_task(task) -- only works for active tasks
		table.remove_val(self.tasks, task)
	end

	function entity:get_tasks_by_class(class)
		local superclasses = find_superclasses(class)

		local tasks = {}
		for _, task in pairs(self.tasks) do
			for _, task_super_class in pairs(find_superclasses(task.class)) do
				for _, super_class in pairs(superclasses) do
					if super_class == task_super_class then
						if not table.contains(tasks, task) then
							table.insert(tasks, task)
						end
					end
				end
			end
		end
		return tasks
	end

	function entity:has_tasks_by_class(class)
		return #self:get_tasks_by_class(class) > 0
	end
end

return task_mod
