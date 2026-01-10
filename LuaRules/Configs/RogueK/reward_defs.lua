
local unitUnlocks = {}
local function MakeUnitUnlock(name)
	if unitUnlocks[name] then
		return unitUnlocks[name]
	end
	local ud = UnitDefNames[name]
	if not ud then
		Spring.Echo("REWARD_DEF_ERROR", name, "not found")
		return false
	end
	local moveType = Spring.Utilities.getMovetype(ud)
	local def = {
		name = name,
		humanName = ud.humanName,
		unitDefName = name,
		structure = not moveType,
		factory = moveType and ((moveType == 2 and 1) or 3),
	}
	unitUnlocks[name] = def
	return def
end

local function ProcessUnitList(unitList)
	local out = {}
	for i = 1, #unitList do
		out[#out + 1] = MakeUnitUnlock(unitList[i])
	end
	return out
end

local categories = {
	constructor = {
		humanName = "Constructor",
		options = ProcessUnitList({
			"cloakcon",
			"shieldcon",
			"amphcon",
			"jumpcon",
			"spidercon",
			"vehcon",
			"hovercon",
			"tankcon",
			"planecon",
			"gunshipcon",
		}),
	},
	light_combat = {
		humanName = "Light Combat Unit",
		options = ProcessUnitList({
			"cloakraid",
			"shieldraid",
			"amphraid",
			"jumpraid",
			"vehraid",
			"hoverraid",
		}),
	},
	light_turret = {
		humanName = "Turret",
		options = ProcessUnitList({
			"turretlaser",
			"turretmissile",
			"turretimpulse",
			"turretgauss",
			"turretheavy",
			"turretriot",
			"turretemp",
		}),
	},
}

local flatRewards = {}
local alreadyIn = {}
for reward, data in pairs(categories) do
	for i = 1, #data.options do
		local name = data.options[i].name
		if not alreadyIn[name] then
			flatRewards[name] = data.options[i]
			alreadyIn[name] = true
		end
	end
end

local def = {
	categories = categories,
	flatRewards = flatRewards,
}

return def
