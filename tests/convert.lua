package.path = package.path .. ";zzlib/?.lua"
local png = require("dmiextract.png")
local targa = require("dmiextract.targa")

local h = io.open(arg[1], "rb")
local i = png(h)
local dat, rd = i:imagedata()
--io.stdout:write(rd)
io.stderr:write(string.format("%dx%d@%dBpp\n", i.width, i.height, i.bpp))
io.stdout:write(targa(i.width, i.height, dat))