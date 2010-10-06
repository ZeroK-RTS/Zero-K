-- $Id: planetwars.lua 3404 2008-12-10 12:20:46Z lurker $
function gadget:GetInfo()
	return {
		name = "Controlled Desync",
		desc = "Alpha testing for a controlled desync gadget.",
		author = "lurker",
		date = "2008-12-11",
		license = "Public Domain",
		layer = 10,
		enabled = false
	}
end

if (gadgetHandler:IsSyncedCode()) then

local UNSAFE = {
	mykey = '',
	--myname = '',
	keys = {},
	--names = {},
}

function gadget:GameFrame(f)
	if f%30 == 11 and f < 30 then
		local mykey = ''
		for i=1,5 do
			local t = {} for i = 10,99 do t[{}]=i end
			local _,digit = next(t)
			mykey = mykey .. digit
		end
		UNSAFE.mykey = mykey
		Spring.SendLuaRulesMsg('synckey:'..mykey);
	end
end

--function gadget:RecvLuaMsg(msg, playerID)
	


end
