local map_mod = require('map')

local frame_mod = {}
require("misc")

function frame_mod.initial(chars)
	local frame = {}
	frame.map = map_mod.new()
	frame.entities = {}

	function frame:init(chars)
		for _, char in pairs(chars) do
			self:add(require('frame/player')(char))
		end
	end

	function frame:add(entity)
		assert(entity.colliders == nil)
		entity.colliders = {}
		table.insert(self.entities, entity)
	end

	function frame:remove(entity)
		for _, e in pairs(self.entities) do
			if table.contains(e.colliders, entity) then
				if e.on_exit_collider ~= nil then e:on_exit_collider(self, entity) end
				table.remove_val(e.colliders, entity)
			end
		end
		table.remove_val(self.entities, entity)
	end

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

	function frame:tick()
		self:update_colliders()
		for _, entity in pairs(self.entities) do
			entity:tick(self)
		end
	end

	function frame:draw(viewport)
		assert(viewport ~= nil)

		self.map:draw(viewport)
		for _, entity in pairs(self.entities) do
			entity:draw(viewport)
		end
	end

	function frame:clone()
		return clone(self)
	end

	frame:init(chars)

	return frame
end

return frame_mod
