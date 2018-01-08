require('misc')

local task_mod = {}

local TASK_TYPEMAP = {
	skill = {},
	move = {},
	walk = {"move"},
	dash = {"move"},
	channel = {"skill"}
}

local function find_subclasses(type)
	local subs = {type}
	for sub, sub_supers in pairs(TASK_TYPEMAP) do
		if table.contains(sub_supers, type) then
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

	for k, _ in pairs(TASK_TYPEMAP) do
		out[k] = {}
		for k2, _ in pairs(TASK_TYPEMAP) do
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
	{old = {"walk", "channel"}, new = {"walk", "channel"}, relation = "cancel"}
})

assert("cancel" == TASK_RELATION['walk']['walk'])

local function get_relation_partners(tasks, task, rel)
	assert(task.types ~= nil, "get_relation_partners(): task.types == nil")

	local partners = {}
	for _, active_task in pairs(tasks) do
		assert(active_task.types ~= nil, "get_relation_partners(): active_task.types == nil")
		for _, t in pairs(task.types) do
			for _, active_t in pairs(active_task.types) do
				if active_task ~= task and TASK_RELATION[active_t][t] == rel
					and not table.contains(partners, active_task) then
					table.insert(partners, active_task)
				end
			end
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

	function entity:get_tasks_by_types(types)
		assert(false, "TODO")
	end

	function entity:has_tasks_by_types(types)
		return #self:get_tasks_by_types(types) > 0
	end
end

return task_mod
