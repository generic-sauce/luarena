function love.load()
	node = require("node/mod")()
end

function love.update(dt)
	node:update(dt)
end

function love.draw()
	node:draw()
end
