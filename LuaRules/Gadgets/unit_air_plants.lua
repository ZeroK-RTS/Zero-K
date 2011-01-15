-- $Id$
function gadget:GetInfo()
  return {
    name      = "AirPlantParents",
    desc      = "Allows you to set some options on airplants for aircrafts",
    author    = "TheFatController",
    date      = "15 Dec 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return
end

local EditUnitCmdDesc = Spring.EditUnitCmdDesc
local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local InsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local GiveOrderToUnit = Spring.GiveOrderToUnit

local AIRPLANT = {
  [UnitDefNames["factoryplane"].id] = true,
  [UnitDefNames["factorygunship"].id] = true,
}

local plantList = {}

local landCmd = {
      id      = 34569,
      name    = "apLandAt",
      action  = "apLandAt",
      type    = CMDTYPE.ICON_MODE,
      tooltip = "Plant Land Mode: settings for Aircraft leaving the plant",
      params  = { '1', ' Fly ', 'Land'}
}

local airCmd = {
      id      = 34570,
      name    = "apAirRepair",
      action  = "apAirRepair",
      type    = CMDTYPE.ICON_MODE,
      tooltip = "Plant Repair Level: settings for Aircraft leaving the plant",
      params  = { '1', 'LandAt 0', 'LandAt 30', 'LandAt 50', 'LandAt 80'}
}

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
  if AIRPLANT[unitDefID] then
    InsertUnitCmdDesc(unitID, 500, landCmd)
    --InsertUnitCmdDesc(unitID, 500, airCmd)
    plantList[unitID] = {landAt=1, repairAt=1}
  elseif plantList[builderID] then
    --GiveOrderToUnit(unitID, CMD.AUTOREPAIRLEVEL, { plantList[builderID].repairAt }, { })
    GiveOrderToUnit(unitID, CMD.IDLEMODE, { plantList[builderID].landAt }, { })
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  plantList[unitID] = nil
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if AIRPLANT[unitDefID] then
    if (cmdID == 34569) then 
      local cmdDescID = FindUnitCmdDesc(unitID, 34569)
      landCmd.params[1] = cmdParams[1]
      EditUnitCmdDesc(unitID, cmdDescID, landCmd)
      plantList[unitID].landAt = cmdParams[1]
      landCmd.params[1] = 1
	--[[
    elseif (cmdID == 34570) then
      local cmdDescID = FindUnitCmdDesc(unitID, 34570)
      airCmd.params[1] = cmdParams[1]
      EditUnitCmdDesc(unitID, cmdDescID, airCmd)
      plantList[unitID].repairAt = cmdParams[1]
      airCmd.params[1] = 1
	]]--
    end
  end
  return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------