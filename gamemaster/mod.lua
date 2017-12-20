AVG_FACTOR_COUNT = 50

local gamemaster_mod = {}

function gamemaster_mod.calc_avg_backtrack(old_avg, new_val)
	if old_avg == nil then
		return new_val
	else
		return old_avg * ((AVG_FACTOR_COUNT-1)/AVG_FACTOR_COUNT) + new_val * (1/AVG_FACTOR_COUNT)
	end
end

return gamemaster_mod
