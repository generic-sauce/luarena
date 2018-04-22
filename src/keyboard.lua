keys = {}

function isPressed(key)
	return keys[key] == true
end

function love.keypressed(_, unicode)
	keys[unicode] = true

	if master.kind == "initmaster" then
		master:apply_key(unicode)
	end
end

function love.keyreleased(_, unicode)
	keys[unicode] = false
end
