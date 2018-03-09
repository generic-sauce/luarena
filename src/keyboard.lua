keys = {}

function isPressed(key)
	return keys[key] == true
end

function love.keypressed(_, unicode)
	keys[unicode] = true
end

function love.keyreleased(_, unicode)
	keys[unicode] = false
end
