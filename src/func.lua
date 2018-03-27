local func_mod = {}

require('misc')

-- this object should contain self.list, self.obj attributes
func_mod.append_func_meta = {
	__call = function(self, ...)
			for _, f in pairs(self.list) do
				f(self.obj, ...)
			end
		end
}

local function make_append_func(obj)
	assert(type(obj) == "table")
	return setmetatable({list = {}, obj = obj}, func_mod.append_func_meta)
end

local function is_append_func(t)
	return type(t) == "table" and type(t.list) ~= nil and type(t.obj) ~= nil
end

local listify_function = function(obj, name)
	assert(type(obj) == 'table')
	assert(type(name) == 'string')

	if type(obj[name]) == 'function' then
		local f = make_append_func(obj)
		table.insert(f.list, obj[name])
		obj[name] = f
	elseif type(obj[name]) == "nil" then
		obj[name] = make_append_func(obj)
	else
		assert(false)
	end
end

function func_mod.eval_and_function(obj, name)
	assert(type(obj) == 'table')
	assert(type(name) == 'string')

	if type(obj[name]) == "nil" then
		return true
	elseif is_append_func(obj[name]) then
		for _, f in pairs(obj[name].list) do
			if not f(obj) then
				return false
			end
		end
		return true
	elseif type(obj[name]) == 'function' then
		return obj[name](obj)
	else
		assert(false, "can't call eval_and_function to obj[\"" .. name .. "\"] of type " .. type(obj[name]))
	end

end

function func_mod.append_function(obj, name, new_function)
	assert(type(obj) == 'table')
	assert(type(name) == 'string')
	assert(type(new_function) == 'function')

	if type(obj[name]) == 'nil' then
		obj[name] = new_function
	elseif type(obj[name]) == 'function' then
		listify_function(obj, name)
		table.insert(obj[name].list, new_function)
	elseif is_append_func(obj[name]) then
		table.insert(obj[name].list, new_function)
	else
		assert(false, "can't append to obj[name] of type " .. type(obj[name]))
	end
end

return func_mod
