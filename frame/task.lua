require('misc')

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
			for _, subsub in find_subclasses(sub) do
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
	assert(task.type ~= nil)

	local partners = {}
	for _, active_task in pairs(tasks) do
		if active_task ~= task and TASK_RELATION[active_task.type][task.type] == rel then
			table.insert(partners, active_task)
		end
	end
	return partners
end

local function is_in_relation(tasks, task, rel)
	return #get_relation_partners(tasks, task, rel) > 0
end

return function(frame)
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

	return frame
end
