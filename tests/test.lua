local targa = require("spesstools.targa")
local function solve(w, h, func)
	local res = {}
	for y=1, h do
		for x=1, w do
			table.insert(res, func(x, y))
		end
	end
	return table.concat(res)
end

local w, h = 256, 256

io.stdout:write(targa(w, h, solve(w, h, function(x, y)
	local r = math.floor((x/w)*255)
	local b = math.floor((y/h)*255)
	local g = math.floor(math.sin(((x+y)/(w+h))*(math.pi))*255)
	--io.stderr:write(r, "\t", g, "\t", b, "\n")
	return string.char(r,g,b,255)
end)))