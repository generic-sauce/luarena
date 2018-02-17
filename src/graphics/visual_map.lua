local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local graphics_mod = require('graphics/mod')
local visual_map_mod = {}

local TILE_SIZE = 64
local TEXTURE_PIXEL_SIZE = TILE_SIZE / 8

local function generate_bottom_sprite(size, collision_map)
	local texture = graphics_mod.generate_texture_by_pixels(
		size,
		function(x, y)
			math.randomseed(y * size.x + x)
			local tile_pos = (vec_mod(x, y) / TEXTURE_PIXEL_SIZE):floor()

			if collision_map:is_kill(tile_pos) then
				return 0, 0, math.random() * 16 + 64, 255
			elseif collision_map:is_none(tile_pos) then
				return 0, math.random() * 16 + 64, 0, 255
			else
					assert(collision_map:get_tile(tile_pos))
					return 0, 0, 0, 0
			end
		end)
	return graphics_mod.generate_sprite(texture)
end

local function generate_top_sprite(size, collision_map)
	local texture = graphics_mod.generate_texture_by_pixels(
		size,
		function(x, y)
			math.randomseed(y * size.x + x)
			local tile_pos = (vec_mod(x, y) / TEXTURE_PIXEL_SIZE):floor()
			--print(tile_pos)

			if collision_map:is_solid(tile_pos) then
				return math.random() * 16 + 64, 0, 0, 255
			else
					assert(collision_map:get_tile(tile_pos))
					return 0, 0, 0, 0
			end
		end)
	return graphics_mod.generate_sprite(texture)
end

function visual_map_mod.init_collision_map(collision_map)
	local visual_map = collision_map

	function visual_map:visual_size()
		return self.size_tiles * TILE_SIZE
	end

	function visual_map:rect()
		return rect_mod.by_left_top_and_size(
			vec_mod(0, 0),
			self:size()
		)
	end

	function visual_map:draw(viewport)
		viewport:draw_world_sprite(self.bottom_sprite, vec_mod(0, 0), self:visual_size())
		viewport:draw_world_sprite(self.top_sprite, vec_mod(0, 0), self:visual_size())

		--[[local r = self:rect()

		local ground_pos = viewport:world_to_screen_pos(r:center())
		love.graphics.draw(self.ground_texture, ground_pos.x, ground_pos.y)

		local minx = math.floor(r:left() / PIXEL_SIZE) * PIXEL_SIZE
		local maxx = (math.ceil(r:right() / PIXEL_SIZE) - 1) * PIXEL_SIZE
		local miny = math.floor(r:top() / PIXEL_SIZE) * PIXEL_SIZE
		local maxy = (math.ceil(r:bottom() / PIXEL_SIZE) - 1) * PIXEL_SIZE

		for x=minx, maxx, PIXEL_SIZE do
			for y=miny, maxy, PIXEL_SIZE do
			end
		end]]
	end

	do
		local texture_size = (visual_map:visual_size() / TEXTURE_PIXEL_SIZE):floor()

		visual_map.bottom_sprite = generate_bottom_sprite(texture_size, collision_map)
		visual_map.top_sprite = generate_top_sprite(texture_size, collision_map)
	end
	
	return visual_map
end

return visual_map_mod
