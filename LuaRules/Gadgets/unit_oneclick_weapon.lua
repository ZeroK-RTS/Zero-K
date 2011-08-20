------------------------------------------------------------------------------
-- HOW IT WORKS:
-- 	Just calls a function in the unit script (to emit-sfx the weapon etc.)
--	and implements reload time! Simple!
--------------------------------------------------------------------------------
function gadget:GetInfo()
  return {
    name      = "One Click Weapon",
    desc      = "Handles one-click weapon attacks like hoof stomp",
    author    = "KingRaptor",
    date      = "20 Aug 2011",
    license   = "GNU LGPL, v2.1 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

--------------------------------------------------------------------------------
-- speedups
--------------------------------------------------------------------------------
local spGetUnitDefID	= Spring.GetUnitDefID
local spGetUnitTeam		= Spring.GetUnitTeam
local spGetUnitIsDead	= Spring.GetUnitIsDead
local spGetUnitRulesParam	= Spring.GetUnitRulesParam

include "LuaRules/Configs/customcmds.h.lua"

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
local spGiveOrderToUnit = Spring.GiveOrderToUnit

local oneClickWepCMD = {
    id      = CMD_ONECLICK_WEAPON,
    name    = "One-Click Weapon",
    action  = "oneclickwep",
	cursor  = 'oneclickwep',
    type    = CMDTYPE.ICON,
	tooltip = "Activate the unit's special weapon",
}

local INITIAL_CMD_DESC_ID = 500

local defs = include "LuaRules/Configs/oneclick_weapon_defs.lua"

--local reloadFrame = {}
--local scheduledReload = {}
--local scheduledReloadByUnitID = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:Initialize()
	local unitList = Spring.GetAllUnits()
	for i=1,#(unitList) do
		local ud = spGetUnitDefID(unitList[i])
		local team = spGetUnitTeam(unitList[i])
		gadget:UnitCreated(unitList[i], ud, team)
	end	
end

function gadget:UnitCreated(unitID, unitDefID, team)
	if defs[unitDefID] then
		--reloadFrame[unitID] = {}
		-- add oneclick weapon commands
		for i=1, #defs[unitDefID] do
			local desc = Spring.Utilities.CopyTable(oneClickWepCMD)
			desc.name = defs[unitDefID][i].name
			desc.tooltip = defs[unitDefID][i].tooltip
			desc.texture = defs[unitDefID][i].texture
			desc.params = {i}
			
			Spring.InsertUnitCmdDesc(unitID, INITIAL_CMD_DESC_ID + (i-1), desc)
			--reloadFrame[unitID][i] = -1000
		end		
	end
end

--[[
function gadget:UnitDestroyed(unitID)
	reloadFrame[unitID] = nil
	scheduledReload[ scheduledReloadByUnitID[unitID] ][unitID] = nil
	scheduledReloadByUnitID[unitID] = nil
end
]]--

--[[
function gadget:GameFrame(n)
	if scheduledReload[n] then
		for unitID in pairs(scheduledReload[n]) do
			if Spring.ValidUnitID(unitID) then
				Spring.SetUnitRulesParam(unitID, "specialReloadFrame", 0, {inlos = true})
			end
		end
		scheduledReload[n] = nil
	end	
end
]]--

local function doTheCommand(unitID, unitDefID, num)
	local frame = Spring.GetGameFrame()
	local currentReload = Spring.GetUnitWeaponState(unitID, defs[unitDefID][num].weaponToReload, "reloadState")
	--if not (spGetUnitIsDead(unitID) or (reloadFrame[unitID][num] > frame)) then
	if not (spGetUnitIsDead(unitID) or (currentReload > frame)) then
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		local func = env[defs[unitDefID][num].functionToCall]
		Spring.UnitScript.CallAsUnit(unitID, func)
		
		local slowState = 1 - (spGetUnitRulesParam(unitID,"slowState") or 0)
		
		-- reload
		local reloadFrameVal = frame + defs[unitDefID][num].reloadTime/slowState
		--reloadFrame[unitID][num] = reloadFrameVal
		--scheduledReloadByUnitID[unitID] = math.max(reloadFrameVal, scheduledReloadByUnitID[unitID] or 0)
		--Spring.SetUnitRulesParam(unitID, "specialReloadFrame", scheduledReloadByUnitID[unitID], {inlos = true})	-- for healthbar
		Spring.SetUnitWeaponState(unitID, defs[unitDefID][num].weaponToReload, "reloadState", reloadFrameVal)
		return true
	end
	return false
end

-- process command
function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_ONECLICK_WEAPON then
		return true, doTheCommand(unitID, unitDefID, cmdParams[1] or 1)	
	end
	return false -- command not used
end

function gadget:AllowCommand(unitID, unitDefID, teamID,cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_ONECLICK_WEAPON and not cmdOptions.shift then
		local cmd = Spring.GetUnitCommands(unitID)
		if cmd and cmd[1] and cmd[1].id and cmd[1].id == CMD_ONECLICK_WEAPON then
			Spring.GiveOrderToUnit(unitID,CMD.REMOVE,{cmd[1].tag},{})
			return false
		end
		Spring.GiveOrderToUnit(unitID,CMD.INSERT,{0,CMD_ONECLICK_WEAPON,cmdParams[1] or 1},{"alt"})
		return false
	end
	return true
end

else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_ONECLICK_WEAPON)
	Spring.SetCustomCommandDrawData(CMD_ONECLICK_WEAPON, "dgun", {1, 1, 1, 1})
	Spring.AssignMouseCursor("oneclickwep", "cursordgun", true, true)
end

end