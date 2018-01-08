return function(frame)

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
						if e1.on_exit_collider ~= nil then e1:on_exit_collider(self, e2) end
						if e2.on_exit_collider ~= nil then e2:on_exit_collider(self, e1) end
						table.remove_val(e1.colliders, e2)
						table.remove_val(e2.colliders, e1)
					elseif not table.contains(e1.colliders, e2) and colliding then
						if e1.on_enter_collider ~= nil then e1:on_enter_collider(self, e2) end
						if e2.on_enter_collider ~= nil then e2:on_enter_collider(self, e1) end
						table.insert(e1.colliders, e2)
						table.insert(e2.colliders, e1)
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

	return frame
end
