local staticUnits = {}
local movetypeDefID = {}

local movetypes = {
	{name = "bot", movedef = "kbot3"},
	{name = "amph", movedef = "akbot4"},
	{name = "spider", movedef = "tkbot4"},
	{name = "veh", movedef = "tank4"},
	{name = "hover", movedef = "hover3"},
	{name = "air", movedef = false},
	{name = "sea", movedef = "uboat3"},
	{name = "static", movedef = false},
}

local movedefMap = {
	["kbot1"] = "bot",
	["kbot2"] = "bot",
	["kbot3"] = "bot",
	["kbot4"] = "bot",
	["akbot2"] = "amph",
	["akbot3"] = "amph",
	["akbot4"] = "amph",
	["akbot6"] = "amph",
	["tkbot1"] = "spider",
	["tkbot3"] = "spider",
	["tkbot4"] = "spider",
	["atkbot3"] = "air",
	["tank2"] = "veh",
	["tank3"] = "veh",
	["tank4"] = "veh",
	["hover3"] = "hover",
	["bhover3"] = "amph",
	["boat3"] = "sea",
	["boat4"] = "sea",
	["boat6"] = "sea",
	["uboat3"] = "sea",
}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isImmobile then
		staticUnits[i] = true
		movetypeDefID[i] = "static"
	else
		if ud.moveDef then
			if ud.moveDef.name and movedefMap[ud.moveDef.name] then
				movetypeDefID[i] = movedefMap[ud.moveDef.name]
			else
				movetypeDefID[i] = "air"
			end
		end
	end
end

return staticUnits, movetypeDefID, movetypes
