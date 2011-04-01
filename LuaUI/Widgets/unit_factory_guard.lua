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

function widget:GetInfo()
  return {
    name      = "Constructor Auto Assist",
    desc      = "Assigns new builders to assist their source factory",
    author    = "trepan & GoogleFrog", -- trepan origional code has been lost to the iterations
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
	handler   = true,
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local CMD_GUARD            = CMD.GUARD
local CMD_MOVE             = CMD.MOVE
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetUnitBuildFacing = Spring.GetUnitBuildFacing
local spGetUnitGroup       = Spring.GetUnitGroup
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitRadius      = Spring.GetUnitRadius
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spSetUnitGroup       = Spring.SetUnitGroup
local spGetUnitDefID	   = Spring.GetUnitDefID
local spGetTeamUnits	   = Spring.GetTeamUnits

local CMD_FACTORY_GUARD = 13921

local factoryDefs = {
	[UnitDefNames["factorycloak"].id] = 0,
	[UnitDefNames["factoryshield"].id] = 0,
	[UnitDefNames["factoryspider"].id] = 0,
	[UnitDefNames["factoryjump"].id] = 0,
	[UnitDefNames["factoryveh"].id] = 0,
	[UnitDefNames["factoryhover"].id] = 0,
	[UnitDefNames["factorytank"].id] = 0,
	[UnitDefNames["factoryplane"].id] = 0,
	[UnitDefNames["factorygunship"].id] = 0,
	[UnitDefNames["corsy"].id] = 0,
}

local factories = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Unit AI/Auto Assist'
options_order = { 'inheritcontrol', 'label'}
options = {
	inheritcontrol = {name = "Inherit Factory Control Group", type = 'bool', value = false},
	label = {name = "label", type = 'label', value = "Set the default Auto Assist for each type\n of factory"}
}

for id,value in pairs(factoryDefs) do
	options[UnitDefs[id].name] = {name = UnitDefs[id].humanName, type = 'bool', value = (value ~= 0) }
	options_order[#options_order+1] = UnitDefs[id].name
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ClearGroup(unitID, factID)
	-- clear the unit's group if it's the same as the factory's
	local unitGroup = spGetUnitGroup(unitID)
	if (not unitGroup) then
		return
	end
	local factGroup = spGetUnitGroup(factID)
	if (not factGroup) then
		return
	end
	if (unitGroup == factGroup) then
		spSetUnitGroup(unitID, -1)
	end
end


local function GuardFactory(unitID, unitDefID, factID, factDefID)
	-- is this a factory?
	local fd = UnitDefs[factDefID]
	if (not (fd and fd.isFactory)) then
		return 
	end

	-- can this unit assist?
	local ud = UnitDefs[unitDefID]
	if (not (ud and ud.builder and ud.canAssist)) then
		return
	end
  
	-- the unit will move itself if it can fly
	if ud.canFly then
		spGiveOrderToUnit(unitID, CMD_GUARD, { factID }, { "" })
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

	local facing = spGetUnitBuildFacing(factID)
	if (not facing) then
		return
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
  
	local OrderUnit = spGiveOrderToUnit

	OrderUnit(unitID, CMD_MOVE,  { x + dx, y, z + dz }, { "" })
	OrderUnit(unitID, CMD_MOVE,  { x + rx, y, z + rz }, { "shift" })
	OrderUnit(unitID, CMD_GUARD, { factID },            { "shift" })
end


--------------------------------------------------------------------------------

function widget:UnitCreated( unitID,  unitDefID,  unitTeam)
	if factoryDefs[unitDefID] and unitTeam == spGetMyTeamID() then
		factories[unitID] = {assist = options[unitDefID].value}
	end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	widget:UnitCreated( unitID,  unitDefID,  unitTeam)
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam,
                                factID, factDefID, userOrders)

	if (unitTeam ~= spGetMyTeamID()) then
		return -- not my unit
	end
	if not options.inheritcontrol.value then
		ClearGroup(unitID, factID)
	end
	if (userOrders) then
		return -- already has user assigned orders
	end
	if factories[factID] and factories[factID].assist then
		GuardFactory(unitID, unitDefID, factID, factDefID)
	end
end

function widget:Initialize() 
	initFrame = Spring.GetGameFrame()+1 -- init units after epic menu loads, it might have the massive negative layer for a good reason
end

function widget:GameFrame(frame)
	if frame == initFrame then
		local units = spGetTeamUnits(spGetMyTeamID())
		for i, id in ipairs(units) do 
			widget:UnitCreated(id, spGetUnitDefID(id),spGetMyTeamID())
		end
	end
end 

function widget:UnitDestroyed( unitID,  unitDefID,  unitTeam)
	if factories[unitID] then
		factories[unitID] = nil
	end
end

--------------------
-- interface stuff to add command

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_FACTORY_GUARD then 
		local selectedUnits = Spring.GetSelectedUnits()
		local newState = nil
		for _, unitID in ipairs(selectedUnits) do
			if factories[unitID] then
				if newState == nil then
					newState = not factories[unitID].assist
				end
				factories[unitID].assist = newState
			end
		end
		return true
	end
end

local CMD_CLOAK         = CMD.CLOAK
local CMD_ONOFF         = CMD.ONOFF
local CMD_REPEAT        = CMD.REPEAT
local CMD_MOVE_STATE    = CMD.MOVE_STATE
local CMD_FIRE_STATE    = CMD.FIRE_STATE

function widget:CommandsChanged()

	local units = Spring.GetSelectedUnits()
	for i, id in pairs(units) do 
		if factories[id] then
			local customCommands = widgetHandler.customCommands
			local order = 0
			if factories[id].assist then
				order = 1
			end
			table.insert(customCommands, {
				id      = CMD_FACTORY_GUARD,
				type    = CMDTYPE.ICON_MODE,
				tooltip = 'Newly built constructors automatically assist their factory',
				name    = 'Auto Assist',
				cursor  = 'Repair',
				action  = 'autoassist',
				params  = {order, 'off', 'on'}, 
				
				pos = {CMD_CLOAK,CMD_ONOFF,CMD_REPEAT,CMD_MOVE_STATE,CMD_FIRE_STATE, CMD_RETREAT},
			})
			break
		end
	end
	
end


--------------------------------------------------------------------------------
