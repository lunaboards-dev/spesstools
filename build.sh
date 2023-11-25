function req {
	lua -e "print(select(2, require('$1')))"
}

luaroll -o dmiextract.lua -m dmiextract.init dmiextract zzlib=zzlib/zzlib.lua inflate-bwo=zzlib/inflate-bwo.lua argparse=$(req "argparse")