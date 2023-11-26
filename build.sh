function req {
	lua -e "print(select(2, require('$1')))"
}

function spesstools {
	ls spesstools | lua -e "for line in io.stdin:lines() do print(string.format('spesstools.%s=spesstools/%s', line:gsub('%.lua$', ''), line)) end"
}

luaroll -o dmiextract.lua -m dmiextract.init dmiextract $(spesstools) zzlib=zzlib/zzlib.lua inflate-bwo=zzlib/inflate-bwo.lua argparse=$(req "argparse")