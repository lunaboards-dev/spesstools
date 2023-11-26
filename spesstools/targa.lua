local tga_hdr = "<BBBHHBHHHHBB"

return function(w, h, rgba_data)
	local res = tga_hdr:pack(
		0, --idlen
		0, --cmap type
		2, --itype
		0, --cmap spec
		0,
		0,
		0, -- ispec
		0,
		w,
		h,
		32,
		8 | (1<<5)
	)
	local n = 1
	for i=1, w*h do
		--print(n, w*h*4)
		local rgb, a, next = string.unpack(">I3B", rgba_data, n)
		res = res .. string.pack("<I3B", rgb, a)
		n = next
	end
	return res
end