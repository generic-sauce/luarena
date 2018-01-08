local collision_mod = {}

local function call_on_exit_collider(entity, frame, collider)
	if entity.on_exit_collider ~= nil then
		entity:on_exit_collider(frame, collider)
	end

	for _, task in pairs(entity.tasks) do
		if task.on_exit_collider ~= nil then
			task:on_exit_collider(entity, frame, collider)
		end
	end
end

local function call_on_enter_collider(entity, frame, collider)
	if entity.on_enter_collider ~= nil then
		entity:on_enter_collider(frame, collider)
	end

	for _, task in pairs(entity.tasks) do
		if task.on_enter_collider ~= nil then
			task:on_enter_collider(entity, frame, collider)
		end
	end
end

function collision_mod.init_frame(frame)
	function frame:find_colliders(shape)
		local colliders = {}
		for _, e in pairs(self.entities) do
			if e.shape:intersects(shape) then
				table.insert(colliders, e)
			end
		end
		return colliders
	end

	function frame:update_colliders()
		for _, e1 in pairs(self.entities) do
			for _, e2 in pairs(self.entities) do
				if e1 ~= e2 and e1.shape ~= nil and e2.shape ~= nil then
					local colliding = e1.shape:intersects(e2.shape)
					if table.contains(e1.colliders, e2) and not colliding then
						table.remove_val(e1.colliders, e2)
						table.remove_val(e2.colliders, e1)
						call_on_exit_collider(e1, self, e2)
						call_on_exit_collider(e2, self, e1)
					elseif not table.contains(e1.colliders, e2) and colliding then
						table.insert(e1.colliders, e2)
						table.insert(e2.colliders, e1)
						call_on_enter_collider(e1, self, e2)
						call_on_enter_collider(e2, self, e1)
					end
				end
			end
		end
	end

	function frame:tick_collision()
		self:update_colliders()
		for _, entity in pairs(self.entities) do
			entity:tick(self)
		end
	end
end

function collision_mod.init_entity(entity)
	assert(entity.colliders == nil)
	entity.colliders = {}
end

return collision_mod
