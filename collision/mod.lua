local collision_mod = {}

local collision_detection_mod = require("collision/detection")

function collision_mod.call_on_exit_collider(entity, frame, collider)
	if entity.on_exit_collider then
		entity:on_exit_collider(frame, collider)
	end

	for _, task in pairs(entity.tasks) do
		if task.on_exit_collider then
			task:on_exit_collider(entity, frame, collider)
		end
	end
end

function collision_mod.call_on_enter_collider(entity, frame, collider)
	if entity.on_enter_collider then
		entity:on_enter_collider(frame, collider)
	end

	for _, task in pairs(entity.tasks) do
		if task.on_enter_collider then
			task:on_enter_collider(entity, frame, collider)
		end
	end
end

function collision_mod.init_frame(frame)
	function frame:find_colliders(shape)
		local colliders = {}
		for _, e in pairs(self.entities) do
			if collision_detection_mod(e.shape, shape) then
				table.insert(colliders, e)
			end
		end
		return colliders
	end

	function frame:tick_collision()
		require('profiler')("tick_collision", function (frame)
			for i, e1 in pairs(self.entities) do
				for j = i+1, #self.entities do
					local e2 = self.entities[j]
					if e1.shape and e2.shape then
						local colliding = collision_detection_mod(e1.shape, e2.shape)
						if table.contains(e1.colliders, e2) and not colliding then
							table.remove_val(e1.colliders, e2)
							table.remove_val(e2.colliders, e1)
							collision_mod.call_on_exit_collider(e1, self, e2)
							collision_mod.call_on_exit_collider(e2, self, e1)
						elseif not table.contains(e1.colliders, e2) and colliding then
							table.insert(e1.colliders, e2)
							table.insert(e2.colliders, e1)
							collision_mod.call_on_enter_collider(e1, self, e2)
							collision_mod.call_on_enter_collider(e2, self, e1)
						end
					end
				end
			end
		end, self)
	end
end

function collision_mod.init_entity(entity)
	assert(entity.colliders == nil)
	entity.colliders = {}
end

return collision_mod
