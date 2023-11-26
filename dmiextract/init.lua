package.path = package.path .. ";zzlib/?.lua"
local dmi = require("spesstools.dmi")
local utils = require("spesstools.utils")
local parser = require("argparse")(
	"dmiextract",
	"A tool to extract or compare BYOND .dmi files."
)

parser:mutex(
	parser:flag("--raw-diff", "Extracts the IMD from both files and runs the diff command on them."),
	parser:flag("--diff -d", "Compares the two DMI files metadata and outputs the differences."),
	--parser:flag("--deep-diff -D", "Compares the two DMI files metadata and sprite data and outputs the differences."),
	--parser:flag("--full-extract -X", "Extacts the IMD and sprite data from the DMI"),
	parser:flag("--extract-imd -x", "Extracts just the IMD from a DMI file"),
	--parser:flag("--extract-sprites", "Extracts just the sprites from a DMI file"),
	parser:flag("--json", "Extracts the IMD data in JSON form.")
)

parser:argument("files"):args("1-2")

local args = parser:parse()

local dmis = {}
local fnames = {}
for i=1, #args.files do
	dmis[i] = dmi(args.files[i])
	fnames[i] = args.files[i]:gsub("/", "_"):gsub("[^%._%w]+", "")
end

if args.extract_imd then
	for i=1, #dmis do
		print(dmis[i]:raw())
		dmis[i].img:imagedata()
	end
elseif args.json then
	for i=1, #dmis do
		print(dmis[i]:json())
	end
elseif args.raw_diff then
	local tmp = os.tmpname()
	local file_names = {}
	os.remove(tmp)
	os.execute("mkdir "..tmp)
	for i=1, #dmis do
		local fname = fnames[i]:gsub("%.(.+)$", ".imd")
		local path = tmp.."/"..fname
		local f = io.open(path, "w")
		f:write(dmis[i]:raw())
		f:close()
		table.insert(file_names, path)
	end
	--utils.warning()
	if select(3, os.execute("diff "..table.concat(file_names, " "))) > 1 then
		utils.warning("diff failed! do you have it installed?")
	end
	os.remove(tmp)
elseif args.diff then
	if #args.files ~= 2 then
		utils.error("not enough files")
	end
	local changes = dmis[1]:diff(dmis[2])
	for i=1, #changes do
		for j=1, #changes[i] do
			print((j~=1 and "\t" or "")..changes[i][j])
		end
		print("")
	end
elseif args.extract_sprites then
	for i=1, #dmis do
		io.stdout:write(dmis[i]:__tgadump())
		--local d = dmis[i].img:imagedata()
		--print(dmis[i].img.width, dmis[i].img.height, dmis[i].img.bpp, dmis[i].img.width*dmis[i].img.height*dmis[i].img.bpp, #d, dmis[i].img.width*dmis[i].img.height)
		--io.stdout:write(d)
	end
end


--[[local f = assert(io.open(arg[1], "rb"))

local h = png(f)

for cnk, dat in h:chunks() do
	print(cnk, #dat)
	if (cnk == "zTXt") then
		local tag_end = dat:find("\0")
		local tag = dat:sub(1, tag_end-1)
		local mode = dat:byte(tag_end+1)
		if (mode ~= 0) then
			error("bad stream")
		end
		local cdat = dat:sub(tag_end+2)
		print(zz.inflate(cdat))
	end
end]]

