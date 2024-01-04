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
local Echo 				= Spring.Echo
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
local GetOptionsCode
do
	local code={meta=CMD.OPT_META, internal=CMD.OPT_INTERNAL, right=CMD.OPT_RIGHT, shift=CMD.OPT_SHIFT, ctrl=CMD.OPT_CTRL, alt=CMD.OPT_ALT} -- 4, 8, 16, 32, 64, 128
	GetOptionsCode = function(options)
		local coded = 0
		for opt, isTrue in pairs(options) do
		    if isTrue then 
			coded = coded + (code[opt] or 0)
		    end
		end
		options.coded = coded
		return coded
	end
end

function widget:CommandNotify(cmd, params, opts)
	if cmd ~= CMD_EXCLUDE_PAD then
		return false
	end
	local selTypes = WG.selectionDefID or spGetSelectedUnitsSorted()
	for defID, units in pairs(selTypes) do
		if airUnitDefID[defID] then
			spGiveOrderToUnit(units[1], cmd, params, opts.coded or GetOptionsCode(opts))
			return true
		end
	end
end
