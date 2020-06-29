--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
local spGetUnitPosition     = Spring.GetUnitPosition

local floor = math.floor

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
	tooltip	= 'Fire at radar dots: Disable to prevent firing at radar dots.',
	params 	= {0, 'Fire at radar',"Don't fire at radar"}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local canHandleUnit = {} -- unitIDs that CAN be handled

local units = {}

local wantGoodTarget = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function canShootAtUnit(targetID, allyTeam)
	local raw = spGetUnitLosState(targetID,allyTeam,true)

	if not raw then
		return false
	end
	if raw % 2 == 1 then -- in LoS
		return true
	end
	if floor(raw / 4) % 4 == 3 then -- typed
		local unitDefID = spGetUnitDefID(targetID)
		if unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].isImmobile then
			return true
		end
	end
	return false
end

local function isTheRightSortOfCommand(cmdID, cmdOpts, cp_1, cp_2)
	return cmdID and Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL) and cmdID == CMD_ATTACK and cp_1 and (not cp_2)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	if units[unitID] then
		local data = units[unitID]
		--Spring.Echo("AllowWeaponTarget frame " .. Spring.GetGameFrame())
		if spValidUnitID(targetID) and canShootAtUnit(targetID, spGetUnitAllyTeam(unitID)) then
			--GG.unitEcho(targetID, "target")
			if (not GG.recursion_GiveOrderToUnit) and wantGoodTarget[unitID] then
				wantGoodTarget[unitID] = nil
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_ATTACK, CMD_OPT_INTERNAL, targetID }, CMD.OPT_ALT )
				local cmdID, cmdOpts, cmdTag, cp_1, cp_2 = Spring.GetUnitCurrentCommand(unitID, 2)
				if isTheRightSortOfCommand(cmdID, cmdOpts, cp_1, cp_2) then
					spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
				end
			end
			return true, defPriority
		else
			--GG.unitEcho(targetID, "No")
			return false, defPriority
		end
	else
		return true, defPriority
	end
end

function GG.DontFireRadar_CheckAim(unitID)
	if units[unitID] then
		local cmdID, cmdOpts, cmdTag, cp_1, cp_2 = Spring.GetUnitCurrentCommand(unitID)
		local data = units[unitID]
		if isTheRightSortOfCommand(cmdID, cmdOpts, cp_1, cp_2) and not canShootAtUnit(cp_1, spGetUnitAllyTeam(unitID)) then
			local firestate = Spring.Utilities.GetUnitFireState(unitID)
			spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, 0 )
			spGiveOrderToUnit(unitID, CMD_REMOVE, {cmdTag}, 0 )
			spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {firestate}, 0 )
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

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_DONT_FIRE_AT_RADAR] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
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
	local manageKey = UnitDefs[unitDefID].customParams.dontfireatradarcommand
	if manageKey then
		--Spring.SetUnitSensorRadius(unitID,"los",0)
		--Spring.SetUnitSensorRadius(unitID,"airLos",0)
		
		spInsertUnitCmdDesc(unitID, dontFireAtRadarCmdDesc)
		canHandleUnit[unitID] = true
		
		DontFireAtRadarToggleCommand(unitID, {((manageKey == "1") and 1) or 0})
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
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
