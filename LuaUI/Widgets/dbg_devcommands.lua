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

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Other

local unitSpawnIndex = 0
local spawnPos = {1300, 1700}
local speedMode = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mission Creation

local recentlyExported = false

local commandNameMap = {
	[CMD.PATROL] = "PATROL",
	[CMD_RAW_MOVE] = "RAW_MOVE",
	[CMD_JUMP] = "JUMP",
	[CMD.ATTACK] = "ATTACK",
	[CMD.MOVE] = "MOVE",
	[CMD.GUARD] = "GUARD",
	[CMD.FIGHT] = "FIGHT",
}

local function GetCommandString(index, command)
	local cmdID = command.id
	if not commandNameMap[cmdID] then
		return
	end
	if not (command.params[1] and command.params[3]) then
		return
	end
	local commandString = [[{cmdID = planetUtilities.COMMAND.]] .. commandNameMap[cmdID]
	commandString = commandString .. [[, pos = {]] .. math.floor(command.params[1]) .. ", " .. math.floor(command.params[3]) .. [[}]]
	
	if index > 1 then
		commandString = commandString .. [[, options = {"shift"}]]
	end
	return commandString .. [[},]]
end

local function ProcessUnitCommands(inTabs, commands, unitID, mobileUnit)
	if mobileUnit and commands[1] then
		if (commands[1].id == CMD.PATROL) or (commands[2] and commands[2].id == CMD.PATROL) then
			local fullCommandString
			for i = 1, #commands do
				local command = commands[i]
				if command.id == CMD.PATROL and command.params[1] and command.params[3] then
					fullCommandString = (fullCommandString or "") .. inTabs .. "\t" .. [[{]] .. math.floor(command.params[1]) .. ", " .. math.floor(command.params[3]) .. [[},]] .. "\n"
				end
			end
			
			if fullCommandString then
				return inTabs  .. [[patrolRoute = {]] .. "\n" .. fullCommandString .. inTabs .. "},\n"
			end
		end
	end

	local fullCommandString
	for i = 1, #commands do
		local commandString = GetCommandString(i, commands[i])
		if commandString then
			fullCommandString = (fullCommandString or "") .. inTabs .. "\t" .. commandString .. "\n"
		end
	end
	if fullCommandString then
		return inTabs  .. [[commands = {]] .. "\n" .. fullCommandString .. inTabs .. "},\n"
	end
end

local function GetUnitString(unitID, tabs, sendCommands)
	local unitDefID = Spring.GetUnitDefID(unitID)
	local ud = UnitDefs[unitDefID]
	local x, y, z = Spring.GetUnitPosition(unitID)
	
	local facing
	if ud.isImmobile then
		facing = Spring.GetUnitBuildFacing(unitID)
		x, y, z = Spring.Pos2BuildPos(unitDefID, x, y, z, facing)
	else
		facing = Spring.GetFacingFromHeading(Spring.GetUnitHeading(unitID))
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
	
	if ud.isImmobile then
		local origHeight = Spring.GetGroundOrigHeight(x, z)
		if ud.floatOnWater and (origHeight < 0) then
			origHeight = 0
		end
		if math.abs(origHeight - y) > 5 then
			unitString = unitString .. inTabs .. [[terraformHeight = ]] .. math.floor(y) .. [[,]] .. "\n"
		end
	end
	
	if sendCommands then
		local commands = Spring.GetUnitCommands(unitID, -1)
		if commands and #commands > 0 then
			local commandString = ProcessUnitCommands(inTabs, commands, unitID, not ud.isImmobile)
			if commandString then
				unitString = unitString .. commandString
			end
		end
	end
	return unitString .. tabs .. "\t},"
end

local function GetFeatureString(fID)
	local fx, _, fz = Spring.GetFeaturePosition(fID)
	local fd = FeatureDefs[Spring.GetFeatureDefID(fID)]
	local tabs = "\t\t\t\t"
	local inTabs = tabs .. "\t"
	local unitString = tabs .. "{\n"
	
	unitString = unitString .. inTabs .. [[name = "]] .. fd.name .. [[",]] .. "\n"
	unitString = unitString .. inTabs .. [[x = ]] .. math.floor(fx) .. [[,]] .. "\n"
	unitString = unitString .. inTabs .. [[z = ]] .. math.floor(fz) .. [[,]] .. "\n"
	unitString = unitString .. inTabs .. [[facing = ]] .. Spring.GetFacingFromHeading(Spring.GetFeatureHeading(fID)) .. [[,]] .. "\n"
	
	return unitString .. tabs.. "},"
end

local function ExportAllyTeamUnits(allyTeamID, sendCommands, selectedOnly)
	local units = Spring.GetAllUnits(teamID)
	if not (units and #units > 0) then
		return
	end
	local tabs = (teamID == 0 and "\t\t\t\t") or "\t\t\t\t\t"
	Spring.Echo("====== Unit export allyTeam " .. (allyTeamID or "??") .. " ======")
	for i = 1, 20 do
		Spring.Echo("= - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - =")
	end
	local unitsString = tabs .. "startUnits = {\n"
	for i = 1, #units do
		if Spring.GetUnitAllyTeam(units[i]) == allyTeamID then
			Spring.Echo(GetUnitString(units[i], tabs, sendCommands))
		end
	end
end

local function ExportTeamUnitsForMission(teamID, sendCommands, selectedOnly)
	local units = Spring.GetTeamUnits(teamID)
	if not (units and #units > 0) then
		return
	end
	local tabs = (teamID == 0 and "\t\t\t\t") or "\t\t\t\t\t"
	Spring.Echo("====== Unit export team " .. (teamID or "??") .. " ======")
	for i = 1, 20 do
		Spring.Echo("= - = - = - = - = - = - = - = - = - = - = - = - = - = - = - = - =")
	end
	local unitsString = tabs .. "startUnits = {\n"
	for i = 1, #units do
		if (not selectedOnly) or Spring.IsUnitSelected(units[i]) then
			Spring.Echo(GetUnitString(units[i], tabs, sendCommands))
		end
	end
end

local function ExportUnitsForMission(sendCommands, selectedOnly)
	if recentlyExported then
		return
	end
	local teamList = Spring.GetTeamList()
	Spring.Echo("================== ExportUnitsForMission ==================")
	for i = 1, #teamList do
		ExportTeamUnitsForMission(teamList[i], sendCommands, selectedOnly)
	end
	recentlyExported = 1
end

local function ExportUnitsForMission(sendCommands, selectedOnly)
	if recentlyExported then
		return
	end
	local teamList = Spring.GetTeamList()
	Spring.Echo("================== ExportUnitsForMission ==================")
	for i = 1, #teamList do
		ExportTeamUnitsForMission(teamList[i], sendCommands, selectedOnly)
	end
	recentlyExported = 1
end

local function ExportUnitsAndCommandsForMission()
	ExportUnitsForMission(true)
end

local function ExportSelectedUnitsAndCommandsForMission()
	ExportUnitsForMission(true, true)
end

local function ExportAllyTeamUnitsAndCommands()
	if recentlyExported then
		return
	end
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		ExportAllyTeamUnits(allyTeamList[i], true)
	end
end


local function ExportFeaturesForMission()
	Spring.Echo("================== ExportFeaturesForMission ==================")
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		Spring.Echo(GetFeatureString(features[i]))
	end
end

local unitToMove = 0
local recentlyMovedUnit = false
local function MoveUnitRaw(snap)
	local units = Spring.GetSelectedUnits()
	if not (units and units[1]) then
		return
	end
	
	if not recentlyMovedUnit then
		unitToMove = unitToMove + 1
		if unitToMove > #units then
			unitToMove = 1
		end
		recentlyMovedUnit = options.moveUnitDelay.value
	end
	local unitID = units[unitToMove]
	
	local unitDefID = Spring.GetUnitDefID(unitID)
	local ud = unitDefID and UnitDefs[unitDefID]
	if not ud then
		return
	end
	
	local mx, my = Spring.GetMouseState()
	local trace, pos = Spring.TraceScreenRay(mx, my, true, false, false, true)
	if not (trace == "ground" and pos) then
		return
	end
	
	local x, y, z = math.floor(pos[1]), pos[2], math.floor(pos[3])
	if snap or ud.isImmobile then
		local facing = Spring.GetUnitBuildFacing(unitID)
		x, y, z = Spring.Pos2BuildPos(unitDefID, x, y, z, facing)
	end
	
	Spring.SendCommands("luarules moveunit " .. unitID .. " " .. x .. " " .. z)
end

local function MoveUnit()
	MoveUnitRaw(false)
end

local function MoveUnitSnap()
	MoveUnitRaw(true)
end

local function DestroyUnit()
	local units = Spring.GetSelectedUnits()
	if not units then
		return
	end
	
	for i = 1, #units do
		Spring.SendCommands("luarules destroyunit " .. units[i])
	end
end

local function RotateUnit(add)
	local units = Spring.GetSelectedUnits()
	if not units then
		return
	end
	
	for i = 1, #units do
		local unitDefID = Spring.GetUnitDefID(units[i])
		local ud = unitDefID and UnitDefs[unitDefID]
		if ud then
			local facing
			if ud.isImmobile then
				facing = Spring.GetUnitBuildFacing(units[i])
			else
				facing = Spring.GetFacingFromHeading(Spring.GetUnitHeading(units[i]))
			end
			facing = (facing + add)%4
			Spring.SendCommands("luarules rotateunit " .. units[i] .. " " .. facing)
		end
	end
end

local function RotateUnitLeft()
	RotateUnit(1)
end

local function RotateUnitRight()
	RotateUnit(-1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Dev

local function CheatAll()
	if not Spring.IsCheatingEnabled() then
		Spring.SendCommands{"cheat"}
	end
	Spring.SendCommands{"spectator"}
	if not Spring.IsGodModeEnabled() then
		Spring.SendCommands{"godmode"}
	end
end

local function FullSpeed()
	speedMode = not speedMode
	if speedMode then
		Spring.SendCommands{"setmaxspeed 100"}
		Spring.SendCommands{"setminspeed 100"}
	else
		Spring.SendCommands{"setminspeed 1"}
		Spring.SendCommands{"setmaxspeed 1"}
		Spring.SendCommands{"setmaxspeed 100"}
		Spring.SendCommands{"setminspeed 0.1"}
	end
end

function widget:TextCommand(command)  
	if command == "cheatall" then
		CheatAll()
	end
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
	if recentlyMovedUnit then
		recentlyMovedUnit = recentlyMovedUnit - dt
		if recentlyMovedUnit < 0 then
			recentlyMovedUnit = false
		end
	end
end

local doCommandEcho = false
function widget:CommandNotify(cmdID, params, options)
	if doCommandEcho then
		Spring.Echo("cmdID", cmdID)
		Spring.Utilities.TableEcho(params, "params")
		Spring.Utilities.TableEcho(options, "options")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Toolbox/Dev Commands'
options_order = {'cheat', 'nocost', 'spectator', 'godmode', 'testunit', 'cheatall', 'fullspeed', 'luauireload', 'luarulesreload', 'debug', 'debugcolvol', 'debugpath', 'singlestep', 'spawn_next_unit', 'spawn_prev_unit', 'spawn_set_pos', 'printunits', 'printunitnames', 'echoCommand', 'missionexport', 'missionexportcommands', 'missionexportselectedcommands', 'exportallyteamcommands', 'missionexportfeatures', 'moveUnit', 'moveUnitSnap', 'moveUnitDelay', 'destroyUnit', 'RotateUnitLeft', 'RotateUnitRight'}
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
		action = 'give empiricaldpser 1',
	},
	cheatall = {
		name = "Full Cheat",
		type = 'button',
		OnChange = CheatAll,
	},
	fullspeed = {
		name = "Full Speed",
		type = 'button',
		OnChange = FullSpeed,
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
	
	
	spawn_next_unit = {
		name = "Spawn Next Unit",
		type = 'button',
		OnChange = function(self)
			unitSpawnIndex = unitSpawnIndex + 1
			Spring.SendCommands("luarules spawnnthunit " .. unitSpawnIndex .. " " .. spawnPos[1] .. " " .. spawnPos[2])
		end,
	},
	spawn_prev_unit = {
		name = "Spawn Prev Unit",
		type = 'button',
		OnChange = function(self)
			unitSpawnIndex = unitSpawnIndex - 1
			Spring.SendCommands("luarules spawnnthunit " .. unitSpawnIndex .. " " .. spawnPos[1] .. " " .. spawnPos[2])
		end,
	},
	spawn_set_pos = {
		name = "Set Spawn Position",
		type = 'button',
		OnChange = function(self)
			local mx, my = Spring.GetMouseState()
			local trace, pos = Spring.TraceScreenRay(mx, my, true, false, false, true)
			if not (trace == "ground" and pos) then
				return
			end
			spawnPos = pos
		end,
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
	echoCommand = {
		name = 'Echo Given Commands',
		type = 'bool',
		value = false,
		OnChange = function(self)
			doCommandEcho = self.value
		end,
	},
	missionexport = {
		name = "Mission Units Export",
		type = 'button',
		action = 'mission_units_export',
		OnChange = ExportUnitsForMission,
	},
	missionexportcommands = {
		name = "Mission Unit Export (Commands)",
		type = 'button',
		action = 'mission_unit_commands_export',
		OnChange = ExportUnitsAndCommandsForMission,
	},
	missionexportselectedcommands = {
		name = "Mission Unit Export (Selected and Commands)",
		type = 'button',
		action = 'mission_unit_commands_export',
		OnChange = ExportSelectedUnitsAndCommandsForMission,
	},
	exportallyteamcommands = {
		name = "AllyTeam Unit Export (Selected and Commands)",
		type = 'button',
		action = 'allyteam_unit_commands_export',
		OnChange = ExportAllyTeamUnitsAndCommands,
	},
	missionexportfeatures = {
		name = "Mission Feature Export",
		type = 'button',
		action = 'mission_features_export',
		OnChange = ExportFeaturesForMission,
	},
	moveUnit = {
		name = "Move Unit",
		desc = "Move selected unit to the mouse cursor.",
		type = 'button',
		action = 'debug_move_unit',
		OnChange = MoveUnit,
	},
	moveUnitSnap = {
		name = "Move Unit Snap",
		desc = "Move selected unit to the mouse cursor. Snaps to grid.",
		type = 'button',
		action = 'debug_move_unit_snap',
		OnChange = MoveUnitSnap,
	},
	moveUnitDelay = {
		name = "Move Unit Repeat Time",
		type = "number",
		value = 0.1, min = 0.01, max = 0.4, step = 0.01,
	},
	destroyUnit = {
		name = "Destroy Units",
		desc = "Destroy selected units (gentle).",
		type = 'button',
		action = 'debug_destroy_unit',
		OnChange = DestroyUnit,
	},
	RotateUnitLeft = {
		name = "Rotate Unit Anticlockwise",
		type = 'button',
		action = 'debug_rotate_unit_anticlockwise',
		OnChange = RotateUnitLeft,
	},
	RotateUnitRight = {
		name = "Rotate Unit Clockwise",
		type = 'button',
		action = 'debug_rotate_unit_clockwise',
		OnChange = RotateUnitRight,
	},
}

