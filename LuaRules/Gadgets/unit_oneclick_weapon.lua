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

local reloadFrame = {}
local scheduledReload = {}
local scheduledReloadByUnitID = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:Initialize()
	--gadgetHandler:RegisterCMDID(CMD_ONECLICK_WEAPON)	-- donut work
	--Spring.AssignMouseCursor("oneclickwep", "cursordgun", true, true)
	local unitList = Spring.GetAllUnits()
	for i=1,#(unitList) do
		local ud = spGetUnitDefID(unitList[i])
		local team = spGetUnitTeam(unitList[i])
		gadget:UnitCreated(unitList[i], ud, team)
	end	
end

function gadget:UnitCreated(unitID, unitDefID, team)
	if defs[unitDefID] then
		reloadFrame[unitID] = {}
		-- add oneclick weapon commands
		for i=1, #defs[unitDefID] do
			local desc = Spring.Utilities.CopyTable(oneClickWepCMD)
			desc.name = defs[unitDefID][i].name
			desc.tooltip = defs[unitDefID][i].tooltip
			desc.texture = defs[unitDefID][i].texture
			
			Spring.InsertUnitCmdDesc(unitID, INITIAL_CMD_DESC_ID + (i-1), desc)
			reloadFrame[unitID][i] = -1000
		end		
	end
end

function gadget:UnitDestroyed(unitID)
	reloadFrame[unitID] = nil
	--scheduledReload[scheduledReloadByUnitID[unitID]][unitID] = nil
	--scheduledReloadByUnitID[unitID] = nil
end

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

-- process command
function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_ONECLICK_WEAPON then
		local num = cmdParams[1] or 1
		local frame = Spring.GetGameFrame()
		if not (spGetUnitIsDead(unitID) or (reloadFrame[unitID][num] > frame)) then
			local env = Spring.UnitScript.GetScriptEnv(unitID)
			local func = env[defs[unitDefID][(cmdParams[1] or 1)].functionToCall]
			Spring.UnitScript.CallAsUnit(unitID, func)
			
			-- reload
			local reloadFrameVal = frame + defs[unitDefID][num].reloadTime
			reloadFrame[unitID][num] = reloadFrameVal
			scheduledReloadByUnitID[unitID] = math.max(reloadFrameVal, scheduledReloadByUnitID[unitID] or 0)
			Spring.SetUnitRulesParam(unitID, "specialReloadFrame", scheduledReloadByUnitID[unitID], {inlos = true})	-- for healthbar
			return true, true	-- command used, remove
		end
		return true, false	-- command used, don't remove (hasn't executed yet)
	end
	return false -- command not used
end


else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

end