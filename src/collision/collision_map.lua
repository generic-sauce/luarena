local vec_mod = require('viewmath/vec')

local collision_map_mod = {
	TILE_NONE = 0,
	TILE_SOLID = 1,
	TILE_KILL = 2,
}

function collision_map_mod.new(size)
	local collision_map = {
		size_tiles = size,
		tiles = {}
	}

	for y = 0, size.y - 1, 1 do
		for x = 0, size.y - 1, 1 do
			if x % 4 == 0 and y % 4 == 0 then
				collision_map.tiles[y * size.x + x + 1] = collision_map_mod.TILE_SOLID
			elseif x % 3 == 0 and y % 3 == 0 then
				collision_map.tiles[y * size.x + x + 1] = collision_map_mod.TILE_KILL
			else
				collision_map.tiles[y * size.x + x + 1] = collision_map_mod.TILE_NONE
			end
		end
	end

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
		return not self:is_inside(pos) and TILE_SOLID or self.tiles[pos.y * self.size_tiles.x + pos.x + 1]
	end

	return collision_map
end

return collision_map_mod
