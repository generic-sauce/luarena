function love.load()
	master = require("lobbymaster/mod").create_lobby_master()
end

function love.update(dt)
	master:update(dt)
end

function love.draw()
	master:draw()
end
