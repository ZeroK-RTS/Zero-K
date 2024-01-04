function widget:GetInfo()
	return {
		name      = "Send one exclude pad",
		desc      = "Causes only one exclude pad order to be issued in a selection of multiple aircraft. Sending an even number causes the command to do nothing, but sending more than one is redundant.",
		author    = "Helwor",
		date      = "Dec 2023",
		license   = "PD",
		layer     = 1, 
		enabled   = true,  --  loaded by default?
		handler   = true,
	}
end

local spGiveOrderToUnit 		= Spring.GiveOrderToUnit
local spGetSelectedUnitsSorted 		= Spring.GetSelectedUnitsSorted

local airUnitDefID = {}
for defID, def in pairs(UnitDefs) do
	if def.canFly then
		airUnitDefID[defID] = true
	end
end

local CMD_EXCLUDE_PAD
do
	local customCmds = VFS.Include("LuaRules/Configs/customcmds.lua")
	CMD_EXCLUDE_PAD = customCmds.EXCLUDE_PAD
end

function widget:CommandNotify(cmd, params, opts)
	if cmd ~= CMD_EXCLUDE_PAD then
		return false
	end
	local selTypes = WG.selectionDefID or spGetSelectedUnitsSorted()
	for defID, units in pairs(selTypes) do
		if airUnitDefID[defID] then
			spGiveOrderToUnit(units[1], cmd, params, opts)
			return true
		end
	end
end
