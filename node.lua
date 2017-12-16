-- create a network node (either server or client) by parsing the CLI args

return function()
	if arg[2] == "server" then
		return require("server")(arg[3])
	elseif arg[2] == "client" then
		return require("client")(arg[3], arg[4])
	else
		print("invalid command-line arguments!")
		os.exit(1)
	end
end
