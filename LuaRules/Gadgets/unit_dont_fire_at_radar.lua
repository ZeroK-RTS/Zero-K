
function gadget:GetInfo()
  return {
    name      = "Dont fire at radar",
    desc      = "Adds state toggle for units to not fire at radar dots.",
    author    = "Google Frog",
    date      = "8 April 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitTeam         = Spring.GetUnitTeam
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitLosState     = Spring.GetUnitLosState
local spGetCommandQueue     = Spring.GetCommandQueue
local spSetUnitTarget       = Spring.SetUnitTarget
local spGetUnitDefID        = Spring.GetUnitDefID

local CMD_ATTACK		= CMD.ATTACK
local CMD_OPT_INTERNAL 	= CMD.OPT_INTERNAL
local CMD_FIRE_STATE 	= CMD.FIRE_STATE
local CMD_INSERT 		= CMD.INSERT
local CMD_REMOVE 		= CMD.REMOVE

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local dontFireAtRadarCmdDesc = {
	id      = CMD_DONT_FIRE_AT_RADAR,
	type    = CMDTYPE.ICON_MODE,
	name    = "Don't fire at radar",
	action  = 'dontfireatradar',
	tooltip	= 'When enabled the unit will not fire at radar dots',
	params 	= {0, 'Fire at radar',"Don't fire at radar"}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local handleDefID = {
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["armmanni"].id] = true,
	[UnitDefNames["armanni"].id] = true,
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local canHandleUnit = {} -- unitIDs that CAN be handled

local units = {}

local wantGoodTarget = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function canShootAtUnit(targetID, allyTeam)
	local see = spGetUnitLosState(targetID,allyTeam,false)
	local raw = spGetUnitLosState(targetID,allyTeam,true)
	--GG.tableEcho(see)
	if see and see.los then
		return true
	elseif raw > 2 then
		local unitDefID = spGetUnitDefID(targetID)
		if unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].speed == 0 then
			return true
		end
	end
	return false
end

local function isTheRightSortOfCommand(cQueue, index)
	return #cQueue >= index and cQueue[index].options.internal and cQueue[index].id == CMD_ATTACK and #cQueue[index].params == 1
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID)
	if units[unitID] then
		local data = units[unitID]
		--Spring.Echo("AllowWeaponTarget frame " .. Spring.GetGameFrame())
		if spValidUnitID(targetID) and canShootAtUnit(targetID, spGetUnitAllyTeam(unitID)) then
			--GG.unitEcho(targetID, "target")
			if wantGoodTarget[unitID] then
				wantGoodTarget[unitID] = nil
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_ATTACK, CMD_OPT_INTERNAL, targetID }, {"alt"} )
				local cQueue = spGetCommandQueue(unitID)
				if isTheRightSortOfCommand(cQueue, 2)  then
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[2].tag}, {} )
				end
			end
			return true, 1
		else
			--GG.unitEcho(targetID, "No")
			return false, 1
		end
	else
		return true, 1
	end
end

function GG.DontFireRadar_CheckAim(unitID)
	if units[unitID] then
		local cQueue = spGetCommandQueue(unitID)
		local data = units[unitID]
		if isTheRightSortOfCommand(cQueue, 1) and not canShootAtUnit(cQueue[1].params[1], spGetUnitAllyTeam(unitID)) then
			local firestate = Spring.GetUnitStates(unitID).firestate
			
			spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {} )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cQueue[1].tag}, {} )
			spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {firestate}, {} )
			wantGoodTarget[unitID] = {command = true}
			spSetUnitTarget(unitID,0)
		end
	end
end

function GG.DontFireRadar_CheckBlock(unitID, targetID)
	if units[unitID] and spValidUnitID(targetID) then
		local data = units[unitID]
		if canShootAtUnit(targetID, spGetUnitAllyTeam(unitID)) then
			return false
		else
			spSetUnitTarget(unitID,0)
			return true 
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Command Handling
local function DontFireAtRadarToggleCommand(unitID, cmdParams, cmdOptions)
	if canHandleUnit[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_DONT_FIRE_AT_RADAR)
		
		if (cmdDescID) then
			dontFireAtRadarCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = dontFireAtRadarCmdDesc.params})
		end
		if state == 1 then
			if not units[unitID] then
				units[unitID] = true
			end
		else
			if units[unitID] then
				units[unitID] = nil
			end
		end
	end
	
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_DONT_FIRE_AT_RADAR) then
		return true  -- command was not used
	end
	DontFireAtRadarToggleCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if handleDefID[unitDefID] then
		--Spring.SetUnitSensorRadius(unitID,"los",0)
		--Spring.SetUnitSensorRadius(unitID,"airLos",0)
		
		spInsertUnitCmdDesc(unitID, dontFireAtRadarCmdDesc)
		canHandleUnit[unitID] = true
		
		DontFireAtRadarToggleCommand(unitID, {1})
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_DONT_FIRE_AT_RADAR)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end