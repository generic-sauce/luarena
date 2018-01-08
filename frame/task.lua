require('misc')

local TASK_TYPEMAP = {
	move = {},
	walk = {"move"},
	dash = {"move"}
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
	local submeta = { __index = function () return "none" end }

	local out = setmetatable({}, { __index = function () return setmetatable({}, submeta) end })
	for _, entry in pairs(syntaxed_task_relation) do
		if out[entry.old] == nil then
			out[entry.old] = setmetatable({}, submeta)
		end

		for _, oldsub in pairs(find_subclasses(entry.old)) do
			for _, newsub in pairs(find_subclasses(entry.new)) do
				assert(out[oldsub][newsub] == "none") -- or out[oldsub][newsub] == entry.relation
				out[oldsub][newsub] = entry.relation
			end
		end
	end

	return out
end

-- TASK_RELATION[<old>][<new>]
local TASK_RELATION = build_task_relation({
	{old = "dash", new = "dash", relation = "delay"},
	{old = "walk", new = "walk", relation = "cancel"}
})

local function is_in_relation(tasks, task, rel)
	return #get_relation_partners(tasks, task, rel) > 0
end

local function get_relation_partners(tasks, task, rel)
	local partners = {}
	for _, active_task in pairs(tasks) do
		if TASK_RELATION[active_task.type][task.type] == rel then
			table.insert(partners, active_task)
		end
	end
	return partners
end


return function(frame)
	function frame:tick_tasks()
		for _, entity in pairs(self.entities) do
			for key, task in pairs(entity.inactive_tasks) do
				if is_in_relation(entity.tasks, task.task, "prevent") then
					table.remove(entity.inactive_tasks, key)
					if task.task.on_prevent ~= nil then
						task.task:on_prevent(self)
					end
				elseif not is_in_relation(entity.tasks, task, "delay") then
					table.remove(entity.inactive_tasks, key)
					table.insert(entity.tasks, task.task)
					if task.task.init ~= nil then
						task.task:init(self)
					end

					for _, partner in pairs(get_relation_partners("cancel")) do
						table.remove_val(entity.tasks, partner)
						if partner.on_cancel ~= nil then
							partner:on_cancel(self)
						end
					end

					for _, partner in pairs(get_relation_partners("pause")) do
						table.remove_val(entity.tasks, partner)
						table.insert(entity.inactive_tasks, {status="pause", task=partner})
						if partner.on_pause ~= nil then
							partner:on_pause(self)
						end
					end
				end
			end

			for _, task in pairs(entity.tasks) do
				task:tick(self)
			end
		end
	end

	return frame
end
