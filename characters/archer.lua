return function (archer)
	function archer:char_tick()
		if self.inputs.q then
			print("calling q!")
		end
	end

	return archer
end
