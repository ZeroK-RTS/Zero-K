
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
		description = (ud.humanName or "???") .. " - " .. (Spring.Utilities.GetDescription(ud) or ""),
		image = 'unitpics/' .. name .. '.png',
		unitDefName = name,
		structure = not moveType,
		factory = moveType and ((moveType == 2 and 1) or 3),
	}
	unitUnlocks[name] = def
	return def
end

local commChassiOptions = {
	{
		name = "commstrike",
		humanName = "Strike Chassis",
		image = 'unitpics/commstrike.png',
		commander = true,
	},
	{
		name = "commsupport",
		humanName = "Engineer Chassis",
		image = 'unitpics/commsupport.png',
		commander = true,
	},
	{
		name = "commrecon",
		humanName = "Recon Chassis",
		image = 'unitpics/commrecon.png',
		commander = true,
	},
	{
		name = "commassault",
		humanName = "Guardian Chassis",
		image = 'unitpics/commassault.png',
		commander = true,
	},
}

local function ProcessUnitList(unitList)
	local out = {}
	for i = 1, #unitList do
		out[#out + 1] = MakeUnitUnlock(unitList[i])
	end
	return out
end

local categories = {
	comm_chassis = {
		humanName = "Commander",
		base_options = 4,
		options = commChassiOptions,
	},
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
	start_structures = {
		humanName = "Starting Structures",
		options = ProcessUnitList({
			"staticmex",
			"energywind",
			"energysolar",
			"staticradar",
		}),
	},
}

-- How many options are shown for a reward and how many extra are added with tech points.
local BASE_OPTIONS = 3
local TECH_OPTIONS = 3

local flatRewards = {}
local alreadyIn = {}
for reward, data in pairs(categories) do
	data.base_options = data.base_options or BASE_OPTIONS
	data.extra_options = data.extra_options or TECH_OPTIONS
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
