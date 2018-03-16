local ffi = require("ffi")

function read_file(file)
  lines = ""
  for line in io.lines(file) do 
    lines = lines .. "\n" .. line
  end
  return lines
end

return function(name)
	ffi.cdef(read_file("./ffi_libs/lib" .. name .. ".h"))
	return ffi.load("./ffi_libs/lib" .. name .. ".so")
end
