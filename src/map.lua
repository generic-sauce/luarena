local rect_mod = require('viewmath/rect')
local vec_mod = require('viewmath/vec')
local graphics_mod = require('graphics/mod')
local map_mod = {}

local MAP_TILES = vec_mod(8, 8)
local TILE_SIZE = 128
local TEXTURE_PIXEL_SIZE = TILE_SIZE / 8

local function generate_bottom_sprite(size)
	local ground_texture = graphics_mod.generate_texture_by_pixels(
		size,
		function(x, y)
			math.randomseed(y * size.x + x)
			return 0, math.random() * 16 + 64, 0, 255
		end)
	return graphics_mod.generate_sprite(ground_texture)
end

function map_mod.new()
	local map = {}

	function map:size()
		return MAP_TILES * TILE_SIZE
	end

	function map:rect()
		return rect_mod.by_left_top_and_size(
			vec_mod(0, 0),
			self:size()
		)
	end

	function map:draw(viewport)
		viewport:draw_world_sprite(self.bottom_sprite, vec_mod(0, 0), self:size())

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
		local texture_size = (map:size() / TEXTURE_PIXEL_SIZE):floor()

		map.bottom_sprite = generate_bottom_sprite(texture_size)
	end
	
	return map
end

return map_mod
