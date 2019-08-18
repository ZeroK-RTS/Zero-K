------------------------------------------------------------------------------
-- HOW IT WORKS:
-- 	Just calls a function in the unit script (to emit-sfx the weapon etc.)
--	and sets reload time for one of the unit's weapons
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
local spGetUnitHealth	= Spring.GetUnitHealth
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
    texture = "LuaUI/Images/Commands/Bold/action.png",
    type    = CMDTYPE.ICON,
    tooltip = "Activate the unit's special weapon",
}

local INITIAL_CMD_DESC_ID = 500

local defs = include "LuaRules/Configs/oneclick_weapon_defs.lua"

--local reloadFrame = {}
--local scheduledReload = {}
--local scheduledReloadByUnitID = {}
local LOS_ACCESS = {inlos = true}
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
			desc.tooltip = defs[unitDefID][i].tooltip or desc.tooltip
			desc.texture = defs[unitDefID][i].texture or desc.texture
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
	local data = defs[unitDefID] and defs[unitDefID][num]
	if not data then
		return true
	end

	local currentReload = (data.weaponToReload and Spring.GetUnitWeaponState(unitID, data.weaponToReload, "reloadState")) or
		(data.useSpecialReloadFrame and Spring.GetUnitRulesParam(unitID, "specialReloadFrame"))
	local frame = Spring.GetGameFrame()
	if (currentReload and currentReload > frame) or (not data.partBuilt and select(5, spGetUnitHealth(unitID)) < 1) or spGetUnitIsDead(unitID) then
		return true
	end

	local env = Spring.UnitScript.GetScriptEnv(unitID)
	local func = env[data.functionToCall]
	Spring.UnitScript.CallAsUnit(unitID, func)

	local baseSpeedMult = (spGetUnitRulesParam(unitID,"baseSpeedMult") or 1)

	-- reload
	if (data.reloadTime and data.weaponToReload) then
		local reloadFrameVal = frame + data.reloadTime/baseSpeedMult
		Spring.SetUnitWeaponState(unitID, data.weaponToReload, "reloadState", reloadFrameVal)
	end
	if (data.reloadTime and data.useSpecialReloadFrame) then
		local reloadFrameVal = frame + data.reloadTime
		Spring.SetUnitRulesParam(unitID, "specialReloadFrame", reloadFrameVal, LOS_ACCESS)
		Spring.SetUnitRulesParam(unitID, "specialReloadStart", frame, LOS_ACCESS)
	end
	return true
end

-- process command
function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_ONECLICK_WEAPON then
		return true, doTheCommand(unitID, unitDefID, cmdParams[1] or 1)
	end
	return false -- command not used
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_ONECLICK_WEAPON] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

local CMD_INSERT = CMD.INSERT
local CMD_OPT_ALT = CMD.OPT_ALT
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_INSERT
	and cmdParams[1] == 0
	and cmdParams[2] == CMD_ONECLICK_WEAPON
	and cmdParams[3] == CMD_OPT_ALT then
		return false
	end
	return true
end

function gadget:Load(zip)
	if not GG.SaveLoad then
		return
	end
	
	local offset = GG.SaveLoad.GetSavedGameFrame()
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local specialReload = Spring.GetUnitRulesParam(unitID, "specialReloadFrame")
		if specialReload then
			local specialReloadStart = Spring.GetUnitRulesParam(unitID, "specialReloadStart") or specialReload
			Spring.SetUnitRulesParam(unitID, "specialReloadStart", specialReloadStart - offset, LOS_ACCESS)
			Spring.SetUnitRulesParam(unitID, "specialReloadFrame", specialReload - offset, LOS_ACCESS)
		end
	end
end

else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_ONECLICK_WEAPON)
	Spring.SetCustomCommandDrawData(CMD_ONECLICK_WEAPON, "dgun", {1, 1, 1, 0.7})
	Spring.AssignMouseCursor("oneclickwep", "cursordgun", true, true)
	gadgetHandler:RemoveGadget()
end

end
