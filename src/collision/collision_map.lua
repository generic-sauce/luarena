local vec_mod = require('viewmath/vec')

local collision_map_mod = {
	TILE_NONE = 0,
	TILE_SOLID = 1,
	TILE_KILL = 2,
}

function generate_map(size)
	local tiles = {}

	for y = 0, size.y - 1, 1 do
		for x = 0, size.y - 1, 1 do
			tiles[y * size.x + x + 1] = collision_map_mod.TILE_NONE
		end
	end

	do --river
		math.randomseed(love.timer.getTime())
		local posx = math.floor(math.random() * size.x / 2) + size.x / 4
		local width = math.floor(math.random() * 4)

		for y = 0, size.y, 1 do
			if math.random() < .1 then
				width = width + 1
			end
			if math.random() < .1 then
				width = width - 1
			end

			if math.random() < .2 then
				posx = posx + 1
			end
			if math.random() < .2 then
				posx = posx - 1
			end

			width = math.max(1, width)

			for x = posx, posx + width, 1 do
				tiles[math.floor(y * size.x + x)] = collision_map_mod.TILE_KILL
			end
		end
	end

	--local x, y = math.floor(math.random() * size.x), math.floor(math.random() * size.y)

	return tiles
end

function collision_map_mod.new(size)
	local collision_map = {
		size_tiles = size,
		tiles = generate_map(size)
	}

	function collision_map:size()
		return self.size_tiles
	end

	function collision_map:is_inside(pos)
		return pos.x >= 0 and pos.y >= 0 and pos.x < self.size_tiles.x and pos.y < self.size_tiles.y
	end

	function collision_map:is_none(pos)
		return self:is_inside(pos) and self.tiles[pos.y * self.size_tiles.x + pos.x + 1] == collision_map_mod.TILE_NONE
	end

	function collision_map:is_solid(pos)
		return not self:is_inside(pos) or self.tiles[pos.y * self.size_tiles.x + pos.x + 1] == collision_map_mod.TILE_SOLID
	end

	function collision_map:is_kill(pos)
		return self:is_inside(pos) and self.tiles[pos.y * self.size_tiles.x + pos.x + 1] == collision_map_mod.TILE_KILL
	end

	function collision_map:get_tile(pos)
		-- TODO: test this
		return not self:is_inside(pos) and TILE_SOLID or self.tiles[pos.y * self.size_tiles.x + pos.x + 1]
	end

	return collision_map
end

return collision_map_mod
