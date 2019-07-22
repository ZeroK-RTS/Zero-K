--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "AirPlantParents",
		desc      = "Allows you to set some options on airplants for aircrafts",
		author    = "TheFatController",
		date      = "15 Dec 2008",--last update 29 Jan 2014
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


VFS.Include("LuaRules/Configs/customcmds.h.lua")

local EditUnitCmdDesc = Spring.EditUnitCmdDesc
local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local InsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetUnitDefID = Spring.GetUnitDefID

local AIRPLANT = {
	[UnitDefNames["factoryplane"].id] = {land = true},
	[UnitDefNames["factorygunship"].id] = {land = false},
}

if UnitDefNames["pw_bomberfac"] then
	AIRPLANT[UnitDefNames["pw_bomberfac"].id] = {land = false}
end
if UnitDefNames["pw_dropfac"] then
	AIRPLANT[UnitDefNames["pw_dropfac"].id] = {land = false}
end

local plantList = {}

local landCmd = {
	id      = CMD_AP_FLY_STATE,
	name    = "apFlyState",
	action  = "apFlyState",
	type    = CMDTYPE.ICON_MODE,
	tooltip = "Plant Land/Fly Mode: settings for Aircraft leaving the plant",
	params  = { '1', ' Fly ', 'Land'}
}

local repairCmd = {
	id      = CMD_AP_AUTOREPAIRLEVEL,
	name    = "apAirRepair",
	action  = "apAirRepair",
	type    = CMDTYPE.ICON_MODE,
	tooltip = "Plant Repair Level: settings for Aircraft leaving the plant",
	params  = { '0', 'LandAt 0', 'LandAt 30', 'LandAt 50', 'LandAt 80'}
}

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if AIRPLANT[unitDefID] then
		landCmd.params[1] = (AIRPLANT[unitDefID].land and '1') or '0'
		InsertUnitCmdDesc(unitID, 500, landCmd)
		--InsertUnitCmdDesc(unitID, 500, repairCmd)
		plantList[unitID] = {flyState=(AIRPLANT[unitDefID].land and 1) or 0, repairAt=0}
		Spring.SetUnitRulesParam(unitID, "landFlyFactory", plantList[unitID].flyState)
	elseif plantList[builderID] then
		GiveOrderToUnit(unitID, CMD.AUTOREPAIRLEVEL, { plantList[builderID].repairAt }, 0)
		GiveOrderToUnit(unitID, CMD.IDLEMODE, { plantList[builderID].flyState }, 0)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	plantList[unitID] = nil
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_AP_FLY_STATE] = true, [CMD_AP_AUTOREPAIRLEVEL] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if AIRPLANT[unitDefID] then
		if (cmdID == CMD_AP_FLY_STATE) and unitID and plantList[unitID] then 
			local cmdDescID = FindUnitCmdDesc(unitID, CMD_AP_FLY_STATE)
			if cmdDescID then
				landCmd.params[1] = cmdParams[1]
				EditUnitCmdDesc(unitID, cmdDescID, landCmd)
				plantList[unitID].flyState = cmdParams[1]
				landCmd.params[1] = 1
				Spring.SetUnitRulesParam(unitID, "landFlyFactory", plantList[unitID].flyState)
			end
			return false
			--[[
		elseif (cmdID == CMD_AP_AUTOREPAIRLEVEL) then
			local cmdDescID = FindUnitCmdDesc(unitID, CMD_AP_AUTOREPAIRLEVEL)
			repairCmd.params[1] = cmdParams[1]
			EditUnitCmdDesc(unitID, cmdDescID, repairCmd)
			plantList[unitID].repairAt = cmdParams[1]
			repairCmd.params[1] = 1
			return false
			--]]
		end
	end
	return true
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local udid = GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid, nil, -1)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------