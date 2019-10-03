--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_factory_guard.lua
--  brief:   assigns new builder units to guard their source factory
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Constructor Auto Assist",
    desc      = "Assigns new builders to assist their source factory",
    author    = "trepan & GoogleFrog", -- trepan origional code has been lost to the iterations
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

-- Automatically generated local definitions

local CMD_GUARD            = CMD.GUARD
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetUnitBuildFacing = Spring.GetUnitBuildFacing
local spGetUnitGroup       = Spring.GetUnitGroup
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitRadius      = Spring.GetUnitRadius
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spFindUnitCmdDesc    = Spring.FindUnitCmdDesc
local spInsertUnitCmdDesc  = Spring.InsertUnitCmdDesc
local spEditUnitCmdDesc    = Spring.EditUnitCmdDesc

VFS.Include("LuaRules/Utilities/ClampPosition.lua")
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit


local factoryDefs = {
	[UnitDefNames["factorycloak"].id] = 0,
	[UnitDefNames["factoryshield"].id] = 0,
	[UnitDefNames["factoryspider"].id] = 0,
	[UnitDefNames["factoryjump"].id] = 0,
	[UnitDefNames["factoryveh"].id] = 0,
	[UnitDefNames["factoryhover"].id] = 0,
	[UnitDefNames["factoryamph"].id] = 0,
	[UnitDefNames["factorytank"].id] = 0,
	[UnitDefNames["factoryplane"].id] = 0,
	[UnitDefNames["factorygunship"].id] = 0,
	[UnitDefNames["factoryship"].id] = 0,
}

local factories = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local commandDesc = {
	id      = CMD_FACTORY_GUARD,
	type    = CMDTYPE.ICON_MODE,
	tooltip = 'Newly built constructors automatically assist their factory',
	name    = 'Auto Assist',
	cursor  = 'Repair',
	action  = 'autoassist',
	params  = {0, 'off', 'on'},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GuardFactory(unitID, unitDefID, factID, factDefID)
	-- is this a factory?
	local fd = UnitDefs[factDefID]
	if (not (fd and fd.isFactory)) then
		return
	end

	-- can this unit assist?
	local ud = UnitDefs[unitDefID]
	if (not (ud and ud.isBuilder and ud.canAssist)) then
		return
	end
  
	-- the unit will move itself if it can fly
	if ud.canFly then
		spGiveOrderToUnit(unitID, CMD_GUARD, { factID }, 0)
		return
	end

	local x, y, z = spGetUnitPosition(factID)
	if (not x) then
		return
	end


	local facing = spGetUnitBuildFacing(factID)
	if (not facing) then
		return
	end
	
	local radius = spGetUnitRadius(factID)
	if (not radius) then
		return
	end
	local dist = radius * 2
	
	local frontDis = fd.xsize*4+32 -- 4 to edge
	local sideDis = (fd.zsize or fd.ysize)*4+32
	
	if frontDis > dist then
		dist = frontDis
	end
	
	if sideDis > dist then
		dist = sideDis
	end

	-- facing values { S = 0, E = 1, N = 2, W = 3 }
	local dx, dz -- down vector
	local rx, rz -- right vector
	if (facing == 0) then
		-- south
		dx, dz =  0,  dist
		rx, rz =  dist,  0
	elseif (facing == 1) then
		-- east
		dx, dz =  dist,  0
		rx, rz =  0, -dist
	elseif (facing == 2) then
		-- north
		dx, dz =  0, -dist
		rx, rz = -dist,  0
	else
		-- west
		dx, dz = -dist,  0
		rx, rz =  0,  dist
	end
	
	GiveClampedOrderToUnit(unitID, CMD_RAW_MOVE,  { x + dx, y, z + dz }, 0)
	if not GiveClampedOrderToUnit(unitID, CMD_RAW_MOVE,  { x + rx, y, z + rz }, CMD.OPT_SHIFT, true) then
		GiveClampedOrderToUnit(unitID, CMD_RAW_MOVE,  { x - rx, y, z - rz }, CMD.OPT_SHIFT)
	end
	spGiveOrderToUnit(unitID, CMD_GUARD, { factID }, CMD.OPT_SHIFT)
end

--------------------
-- interface stuff to add command

local function SetAssistState(unitID, state)
	if not (unitID and factories[unitID]) then
		return
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_FACTORY_GUARD)
	if cmdDescID then
		commandDesc.params[1] = state
		spEditUnitCmdDesc(unitID, cmdDescID, {params = commandDesc.params})
		factories[unitID].assist = (state == 1)
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_FACTORY_GUARD] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID,
                             cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_FACTORY_GUARD and factoryDefs[unitDefID] then
		SetAssistState(unitID, cmdParams[1])
		return false  -- command was used
	end
	return true  -- command was not used
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID,  unitTeam)
	if factoryDefs[unitDefID] then
		factories[unitID] = {assist = false}
		commandDesc.params[1] = 0
		spInsertUnitCmdDesc(unitID, commandDesc)
	end
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam,
                                factID, factDefID, userOrders)

	if (userOrders) then
		return -- already has user assigned orders
	end
	if factories[factID] and factories[factID].assist then
		GuardFactory(unitID, unitDefID, factID, factDefID)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

function gadget:UnitDestroyed( unitID,  unitDefID,  unitTeam)
	if factories[unitID] then
		factories[unitID] = nil
	end
end

--------------------------------------------------------------------------------
