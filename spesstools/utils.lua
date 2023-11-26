local utils = {}
--[[

]]
local function printfunc(fmt, stream)
	return function(...)
		local v = table.pack(...)
		local o = {}
		for i=1, v.n do
			o[i] = tostring(v[i])
		end
		local ov = table.concat(o, "\t")
		stream:write(fmt:format(ov))
	end
end

utils.warning = printfunc("\27[1;93mWARN:\27[22m %s\27[0m\n", io.stderr)
local internal_error = printfunc("\27[1;91mERROR:\27[22m %s\27[0m\n", io.stderr)
function utils.error(...)
	internal_error(...)
	--internal_error(debug.traceback())
	os.exit(1)
end

function utils.prequire(lib, warn)
	local ok, res = pcall(require, lib)
	if not ok and warn then
		utils.warning(string.format("library \"%s\" prequired but not found.", lib))
	end
	return ok and res
end

function utils.tryopen(path, mode)
	local h, err = io.open(path, mode)
	if not h then
		utils.error(err)
	end
	return h
end

return utils