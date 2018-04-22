lobby_mod = require('lobbymaster/mod')
require("misc")

local initmaster = {}

initmaster.kind = "initmaster"
initmaster.args_str = ""

local function split(text)
	local l = {}
	local word = ""
	for i=1, #text do
		if text:sub(i, i) == " " then
			table.insert(l, word)
			word = ""
		else
			word = word .. text:sub(i, i)
		end
	end
	table.insert(l, word)
	return l
end

function initmaster:draw()
	love.graphics.print(usage_text() .. "\n\n" .. initmaster.args_str)
end

function initmaster:apply_key(x)
	if x == "return" then
		local args = split(initmaster.args_str)
		master = lobby_mod.create_lobby_master_by_args(args)
	elseif x == "space" then
		initmaster.args_str = initmaster.args_str .. " "
	elseif x == "backspace" then
		initmaster.args_str = initmaster.args_str:sub(1, -2)
	else
		initmaster.args_str = initmaster.args_str .. x
	end
end

function initmaster:update() end

return initmaster
