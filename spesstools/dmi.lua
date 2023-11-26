local png = require("spesstools.png")
local zz = require("zzlib")
local tga = require("spesstools.targa")
local utils = require("spesstools.utils")

local unset = {}

local frames = {}

local function find_state(o, s)
	for i=1, #o do
		if o[i].state == s then
			return o[i]
		end
	end	
end

local function compare_lists(l1, l2)
	if #l1 ~= #l2 then
		return true
	end
	for i=1, #l1 do
		if l1[i] ~= l2[i] then
			return true
		end
	end
end

local function eq_objs(o1, o2)
	for k, v in pairs(o1) do
		if not o2[k] then
			o2[k] = unset
		end
	end
	for k, v in pairs(o2) do
		if not o1[k] then
			o1[k] = unset
		end
	end
end

local function ser_list(v)
	local o = {}
	for j=1, #v do
		o[j] = string.format("%q", v[j])
	end
	return "["..table.concat(o, ", ").."]"
end

local function strval(v)
	if v == unset then return "(unset)"
	elseif type(v) == "table" then return ser_list(v)
	else return string.format("%q", v) end
end

function frames:diff(old)
	local diff_states = {}
	-- Find added/removed states
	for i=1, #self do
		local st = find_state(old, self[i].state)
		local sst = self[i]
		if not st then
			table.insert(diff_states, {
				type = "added",
				new = self[i]
			})
		else
			eq_objs(st, sst)
			local diffs = {c=0}
			local fchange
			for k, v in pairs(sst) do
				if type(v) == "table" and v ~= unset then
					if compare_lists(v, st[k]) then
						diffs.c = diffs.c + 1
						if k == "framelist" then
							fchange = true
						else
							diffs[k] = true
						end
					end
				else
					if v ~= st[k] then
						diffs.c = diffs.c + 1
						diffs[k] = true
					end
				end
			end
			if diffs.c > 0 then
				diffs.c = nil
				table.insert(diff_states, {
					type = "changed",
					frames = fchange,
					new = sst,
					old = st,
					diffs = diffs
				})
			end
		end
	end
	for i=1, #old do
		if not find_state(self, old[i].state) then
			table.insert(diff_states, {
				type = "removed",
				old = old[i]
			})
		end
	end
	return diff_states
end

function frames:frames()

end

local dmi = {}

function dmi:diff(dmi2)
	--[[local dif = {
		version = self.version ~= dmi2.version,
		width = self.width ~= dmi2.width,
		height = self.height ~= dmi2.height
	}
	local function compare_list(l1, l2)
		if #l1 ~= #l2 then return true end
		for i=1, #l1 do
			if l1[i] ~= l2[i] then return true end
		end
	end
	local function compare_state(s1)
		for i=1, #dmi2.states do
			
		end
		local ret = {}
		for k, v in pairs(s1) do end
	end]]
	local f1 = self:frames()
	local f2 = dmi2:frames()
	local diffs = f1:diff(f2)
	local changes = {}
	for i=1, #diffs do
		local d = diffs[i]
		if d.type == "added" then
			local clist = {}
			for k, v in pairs(d.new) do
				if k ~= "state" and k ~= "framelist" and v ~= unset then
					local sv
					if type(v) == "table" then
						sv = ser_list(v)
					end
					table.insert(clist, string.format("%s = %s", k, sv or string.format("%q", v)))
				end
			end
			table.insert(clist, 1, string.format("new state: %q", d.new.state))
			table.insert(changes, clist)
		elseif d.type == "removed" then
			table.insert(changes, {string.format("removed state: %q", d.old.state)})
		elseif d.type == "changed" then
			local clist = {}
			for k, v in pairs(d.diffs) do
				local ov = d.old[k]
				local nv = d.new[k]
				table.insert(clist, string.format("%s = %s -> %s", k, strval(ov), strval(nv)))
			end
			table.sort(clist)
			if d.frames then
				table.insert(clist, "frames changed")
			end
			table.insert(clist, 1, string.format("changed state: %q", d.new.state))
		end
	end
	return changes
end


function dmi:json()
	local j = "{"
	local function add_raw(k, v, indent)
		if #j ~= 1 then j = j .. "," end
		j = j .. "\n"..string.rep("\t", indent or 0)..string.format("%q: %s", k, v)
	end
	local function n_format(v)
		if (type(v) == "number" and math.type(v) == "float") then
			return string.format("%f", v)
		else
			return string.format("%q", v)
		end
	end
	local function add_val(k, v, indent)
		add_raw(k, n_format(v), indent)
	end
	local function add_table(k, t, indent)
		local o = {}
		for i=1, #t do
			o[i] = n_format(t[i])
		end
		add_raw(k, "["..table.concat(o, ", ").."]", indent)
	end
	add_val("version", self.version, 1)
	add_val("width", self.width, 1)
	add_val("height", self.height, 1)
	j = j .. '\n\t"states": ['
	for i=1, #self.states do
		if i ~= 1 then j = j .. "," end
		j = j .. "\n\t\t{"
		add_val("state", self.states[i].v, 3)
		for k, v in pairs(self.states[i]) do
			if k ~= "v" then
				if type(v) == "table" then
					add_table(k, v, 3)
				else
					add_val(k, v, 3)
				end
			end
		end
		j = j .. "\n\t\t}"
	end
	j = j .. "\n\t]\n}"
	return j
end

function dmi:raw()
	return self.imd
end

function dmi:__tgadump()
	local imgdat = self.img:imagedata()
	return tga(self.img.width, self.img.height, imgdat)
end

function dmi:frames()
	local imgdat = self.img:imagedata()
	local flist = {}
	local framelines = self.img.height/self.height
	local frames_in_line = self.img.width/self.width
	local offset = 1
	local packstr = string.rep("c"..(self.width*4), frames_in_line)
	for i=1, framelines do
		local lframes = {}
		for y=1, self.height do
			local strs = table.pack(packstr:unpack(imgdat, offset))
			offset = table.remove(strs)
			for j=1, #strs do
				lframes[j] = (lframes[j] or "") .. strs[j]
			end
		end
		for j=1, #lframes do
			table.insert(flist, lframes[j])
		end
	end
	local states = {}
	for i=1, #self.states do
		local stv = self.states[i]
		local st = {
			state = stv.v,
			delay = stv.delay,
			dirs = stv.dirs,
			frames = stv.frames,
			rewind = stv.rewind,
			framelist = {}
		}
		for c=1, st.dirs do
			st.framelist[c] = {}
			for f=1, st.frames do
				st.framelist[c] = table.remove(flist, 1)
			end
		end
		table.insert(states, st)
	end
	return setmetatable(states, {__index=frames})
end

function dmi:targadump(x, y, w, h)
	local imgdat = self.img:imagedata()
	local dat = {}
	for i=0, h-1 do
		local offset = (y+i)*self.img.width+x+1
		local line = imgdat:sub(offset, offset+w-1)
		table.insert(dat, line)
	end
	local idat = table.concat(dat)
	return tga(w, h, idat)
end


local function parse_val(v)
	if v:sub(1,1) == "\"" then
		return v:sub(2, #v-1)
	elseif v:find(",") then
		local vals = {}
		for m in v:gmatch("[^,]+") do
			table.insert(vals, parse_val(m))
		end
		return vals
	else
		return tonumber(v)
	end
end

local function dmi_parse(dat)
	local d = {states={}}
	local cval
	for line in dat:gmatch("[^\r\n]+") do
		line = line:gsub("#.+", "")
		local stripped = line:gsub("^%s+", ""):gsub("%s+$", "")
		local indent = line:match("^%s+")
		if stripped == "" then
			goto continue
		end
		--print(stripped)
		local k, v = stripped:match("(.+)%s=%s*(.+)")
		v = parse_val(v)
		if not indent then
			if cval and cval.type == "version" then
				-- metadata
				d.version = cval.v
				d.width = cval.width
				d.height = cval.height
			else
				table.insert(d.states, cval)
			end
			cval = {
				type=k,
				v=v
			}
		else
			cval[k] = v
		end
		::continue::
	end
	table.insert(d.states, cval)
	return d
end

return function(path)
	local h = utils.tryopen(path, "rb")--assert(io.open(path, "rb"))
	local img = png(h)
	for cnk, dat in img:chunks() do
		--print(cnk, #dat)
		if (cnk == "zTXt") then
			local tag_end = dat:find("\0")
			local tag = dat:sub(1, tag_end-1)
			local mode = dat:byte(tag_end+1)
			if (mode ~= 0) then
				utils.error(path..": bad stream")
			end
			if tag == "Description" then
				local cdat = dat:sub(tag_end+2)
				--print(zz.inflate(cdat))
				local imd = zz.inflate(cdat)
				local cval = dmi_parse(imd)
				cval.imd = imd
				cval.img = img
				cval.h = h
				return setmetatable(cval, {__index=dmi})
			end
		end
	end
	h:close()
	utils.error(path..": not a dmi")
end