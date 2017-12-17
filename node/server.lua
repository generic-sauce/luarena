local enet = require "enet"

return function(server, port)
	if port == nil then
		port = "3842"
	end

	print("opening server at " .. port)

	server.host = enet.host_create("localhost:" .. port)
	if server.host == nil then
		print("Failed to open server")
		os.exit(1)
	end

	function server:update(dt)
		local event = server.host:service(100)

		if event == nil then return end

		if event.type == "connect" then
			print("connected!")
		elseif event.type == "receive" then
			print("received: " .. event.data)
		end
	end

	return server
end
