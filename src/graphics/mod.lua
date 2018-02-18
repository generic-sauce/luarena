local vec_mod = require('viewmath/vec')
require('misc')

local graphics_mod = {}

function graphics_mod.generate_texture_by_pixels(size, pixel_fn)
	pixel_size = pixel_size or 1

	local image_data = love.image.newImageData(size.x, size.y)
	image_data:mapPixel(pixel_fn)

	local image = love.graphics.newImage(image_data)
	image:setFilter("nearest", "nearest")

	return image
end

function graphics_mod.generate_sprite(texture, tile_size, tile_pos)
	local texture_size = vec_mod(texture:getWidth(), texture:getHeight())
	tile_size = tile_size or texture_size
	tile_pos = tile_pos or vec_mod(0, 0)

	local sprite = {}
	sprite.quad = love.graphics.newQuad(tile_pos.x, tile_pos.y, texture_size.x, texture_size.y, tile_size.x, tile_size.y)

	sprite.texture = texture
	return sprite
end

function graphics_mod.init_viewport(viewport)
	function viewport:draw_world_rect(world_rect, r, g, b, a)
		local screen_rect = self:world_to_screen_rect(world_rect)
		love.graphics.setColor(r, g, b, a)
		love.graphics.rectangle("fill", screen_rect:left(), screen_rect:top(), screen_rect:width(), screen_rect:height())
	end

	function viewport:draw_world_sprite(sprite, pos, size)
		pos = viewport:world_to_screen_pos(pos)
		size = viewport:world_to_screen_size(size)
		local texture_size = vec_mod(sprite.texture:getWidth(), sprite.texture:getHeight())
		local scale = size / texture_size
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(sprite.texture, sprite.quad, pos.x, pos.y, 0, scale.x, scale.y)
	end

	function viewport:draw_shape(shape, r, g, b, a)
		love.graphics.setColor(r, g, b, a)
		if shape.shape_type == "polygon" then
			local vertices = {}
			for _, p in pairs(shape:abs_points()) do
				local v = self:world_to_screen_pos(p)
				table.insert(vertices, v.x)
				table.insert(vertices, v.y)
			end
			love.graphics.polygon("fill", vertices)
		elseif shape.shape_type == "circle" then
			local pos = self:world_to_screen_pos(shape:center())
			local radius = shape.radius * self.zoom
			love.graphics.circle("fill", pos.x, pos.y, radius)
		else
			assert(false)
		end
	end

	return viewport
end

return graphics_mod
