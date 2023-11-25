local zz = require("zzlib")

local signature = "\x89PNG\r\n\x1a\n"
local chdr = ">Ic4"
local ihdr = ">IIBBBB"
local file = {}

function file:chunks()
	self.h:seek("set", #signature)
	local have_ihdr
	return function()
		local len, cnk = chdr:unpack(self.h:read(chdr:packsize()))
		local dat = self.h:read(len)
		local crc = string.unpack(">I", self.h:read(4))
		if not have_ihdr and cnk ~= "IHDR" then
			error("bad file (expected IHDR, got `"..cnk.."`)")
		end
		have_ihdr = true
		if cnk == "IEND" then
			return
		end
		return cnk, dat
	end
end

local filters = {
	-- None
	[0] = function(img, str, x)
		return str.raw(x)
	end,
	-- Sub
	function(img, str, x)
		return str.raw(x)+str.raw2(x-img.bpp)
	end,
	-- Up
	function(img, str, x)
		return str.raw(x)+str.prior2(x)
	end,
	-- Average
	function(img, str, x)
		return str.raw(x)+((str.raw2(x-img.bpp)+str.prior2(x))//2)
	end,
	-- Paeth
	function(img, str, x)
		return str.raw(x)+str.paeth_predictor(
			str.raw2(x-img.bpp),
			str.prior2(x),
			str.prior2(x-img.bpp)
		)
	end
}

function file:imagedata()
	local dat = ""
	for cnk, cdt in self:chunks() do
		if cnk == "IDAT" then
			dat = dat .. cdt
		end
	end
	local rawdat = zz.inflate(dat)
	local rd = rawdat
	local scanlines = {}
	local decoded = {}
	local str = {}
	local line = 0
	local tmp = ""
	function str.raw(x)
		if (x < 0) then return 0 end
		return scanlines[line]:byte(x+1)
	end

	function str.raw2(x)
		if (x < 0) then return 0 end
		return tmp:byte(x+1)
	end

	function str.sub(x)
		return str.raw(x)-str.raw(x-self.bpp)
	end

	function str.prior(x)
		if x < 0 then return 0 end
		if line < 2 then
			return 0
		end
		return scanlines[line-1]:byte(x+1)
	end

	function str.prior2(x)
		if x < 0 then return 0 end
		if line < 2 then
			return 0
		end
		return decoded[line-1]:byte(x+1)
	end

	function str.up(x)
		return str.raw(x)-str.prior(x)
	end

	function str.average(x)
		return str.raw(x)-((str.raw(x-self.bpp)+str.prior(x))/2)
	end

	function str.paeth_predictor(a, b, c)
		local p = a + b - c
		local pa = math.abs(p - a)
		local pb = math.abs(p - b)
		local pc = math.abs(p - c)
		if pa <= pb and pa <= pc then return a
		elseif pb <= pc then return b
		else return c end
	end

	function str.paeth(x)
		return str.raw(x)-str.paeth_predictor(
			str.raw(x-self.bpp),
			str.prior(x),
			str.prior(x-self.bpp)
		)
	end
	for i=1, self.height do
		tmp = ""
		local ldat = rawdat:sub(2, (self.width*self.bpp)+1)
		local filter = rawdat:byte(1)
		line = line + 1
		table.insert(scanlines, ldat)
		--io.stderr:write(filter,"\n")
		rawdat = rawdat:sub((self.width*self.bpp)+2)
		for j=1, self.width*self.bpp do
			--print(filter)
			local res = filters[filter](self, str, j-1)
			tmp = tmp .. string.char(res % 256)
		end
		table.insert(decoded, tmp)
	end
	return table.concat(decoded), rd
end

local samples = {
	[0] = 1,
	[2] = 3,
	[3] = 1,
	[4] = 2,
	[6] = 4
}

return function(h)
	if h:read(#signature) ~= signature then
		error("bad png")
	end
	local img = setmetatable({h=h}, {__index=file})
	for cnk, dat in img:chunks() do
		if cnk == "IHDR" then
			img.width, img.height, img.depth, img.ctype, img.comp, img.filter, img.interlace = ihdr:unpack(dat)
			img.bpp = img.depth/8
			if img.bpp//1 ~= img.bpp then error("i cannot be assed to support this") end
			img.bpp = img.bpp * samples[img.ctype]
			break
		end
	end
	return img
end