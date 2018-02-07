local backtrack_balancer_mod = {}

function backtrack_balancer_mod.new()
	local backtrack_balancer = {}

	backtrack_balancer.count = 0
	backtrack_balancer.value = 0

	function backtrack_balancer:push_value(depth)
		self.value = (self.value * self.count + depth) / (self.count + 1)
		self.count = self.count + 1
	end

	function backtrack_balancer:pop_avg()
		if self.count == 0 then
			return nil
		else
			local ret = self.value
			self.value = 0
			self.count = 0
			return ret
		end
	end

	return backtrack_balancer
end

return backtrack_balancer_mod
