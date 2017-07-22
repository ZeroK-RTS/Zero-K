--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Dev Commands",
    desc      = "v0.011 Dev Commands",
    author    = "CarRepairer",
    date      = "2011-11-17",
    license   = "GPLv2",
    layer     = 5,
    enabled   = false,  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mission Creation

local recentlyExported = false
local BUILD_RESOLUTION = 16

local function SanitizeBuildPositon(x, z, ud, facing)
	local oddX = (ud.xsize % 4 == 2)
	local oddZ = (ud.zsize % 4 == 2)
	
	if facing % 2 == 1 then
		oddX, oddZ = oddZ, oddX
	end
	
	if oddX then
		x = math.floor((x + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
	else
		x = math.floor(x/BUILD_RESOLUTION)*BUILD_RESOLUTION
	end
	if oddZ then
		z = math.floor((z + 8)/BUILD_RESOLUTION)*BUILD_RESOLUTION - 8
	else
		z = math.floor(z/BUILD_RESOLUTION)*BUILD_RESOLUTION
	end
	return x, z
end

local function GetUnitFacing(unitID)
	return math.floor(((Spring.GetUnitHeading(unitID) or 0)/16384 + 0.5)%4)
end

local function GetUnitString(unitID, tabs)
	local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
	local x, _, z = Spring.GetUnitPosition(unitID)
	
	local facing = 0
	
	if ud.isBuilding or ud.speed == 0 then
		facing = Spring.GetUnitBuildFacing(unitID)
		x, z = SanitizeBuildPositon(x, z, ud, facing)
	else
		facing = GetUnitFacing(unitID)
	end
	
	local build = select(5, Spring.GetUnitHealth(unitID))
	
	local inTabs = tabs .. "\t\t"
	local unitString = tabs .. "\t{\n"
	unitString = unitString .. inTabs .. [[name = "]] .. ud.name .. [[",]] .. "\n"
	unitString = unitString .. inTabs .. [[x = ]] .. math.floor(x) .. [[,]] .. "\n"
	unitString = unitString .. inTabs .. [[z = ]] .. math.floor(z) .. [[,]] .. "\n"
	unitString = unitString .. inTabs .. [[facing = ]] .. facing .. [[,]] .. "\n"
	
	if build and build < 1 then
		unitString = unitString .. inTabs .. [[buildProgress = ]] .. math.floor(build*10000)/10000 .. [[,]] .. "\n"
	end
	return unitString .. tabs .. "\t},\n"
end


local function ExportTeamUnitsForMission(teamID)
	local units = Spring.GetTeamUnits(teamID)
	if not (units and #units > 0) then
		return
	end
	local tabs = (teamID == 0 and "\t\t\t\t") or "\t\t\t\t\t"
	Spring.Echo("====== Unit export team " .. (teamID or "??") .. " ======")
	local unitsString = tabs .. "startUnits = {\n"
	for i = 1, #units do
		unitsString = unitsString .. GetUnitString(units[i], tabs)
	end
	unitsString = unitsString .. tabs .. "}"
	Spring.Echo(unitsString)
end

local function ExportUnitsForMission()
	if recentlyExported then
		return
	end
	local teamList = Spring.GetTeamList()
	Spring.Echo("================== ExportUnitsForMission ==================")
	for i = 1, #teamList do
		ExportTeamUnitsForMission(teamList[i])
	end
	recentlyExported = 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(dt)
	if recentlyExported then
		recentlyExported = recentlyExported - dt
		if recentlyExported < 0 then
			recentlyExported = false
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Toolbox/Dev Commands'
options = {
	
	cheat = {	
		name = "Cheat",
		type = 'button',
		action = 'cheat',
	},
	nocost = {
		name = "No Cost",
		type = 'button',
		action = 'nocost',
	},
	
	spectator = {
		name = "Spectator",
		type = 'button',
		action = 'spectator',
	},
	
	godmode = {
		name = "Godmode",
		type = 'button',
		action = 'godmode',
	},
	
	testunit = {
		name = "Spawn Testunit",
		type = 'button',
		action = 'give testunit',
	},
	
	luauireload = {
		name = "Reload LuaUI",
		type = 'button',
		action = 'luaui reload',
	},
	
	luarulesreload = {
		name = "Reload LuaRules",
		type = 'button',
		action = 'luarules reload',
	},
	
	debug = {
		name = "Debug",
		type = 'button',
		action = 'debug',
	},
	debugcolvol = {
		name = "Debug Colvol",
		type = 'button',
		action = 'debugcolvol',
	},
	debugpath = {
		name = "Debug Path",
		type = 'button',
		action = 'debugpath',
	},
	singlestep = {
		name = "Single Step",
		type = 'button',
		action = 'singlestep',
	},
	
	
	printunits = {
		name = "Print Units",
		type = 'button',
		OnChange = function(self)
			for i=1,#UnitDefs do
				local ud = UnitDefs[i]
				local name = ud.name
				Spring.Echo("'" .. name .. "',")
			end
		end,
	},
	printunitnames = {
		name = "Print Unit Names",
		type = 'button',
		OnChange = function(self)
			for i=1,#UnitDefs do
				local ud = UnitDefs[i]
				local name = ud.humanName
				Spring.Echo("'" .. name .. "',")
			end
		end,
	},
	missionexport = {
		name = "Mission Units Export",
		type = 'button',
		action = 'mission_units_export',
		OnChange = ExportUnitsForMission,
	},
}

