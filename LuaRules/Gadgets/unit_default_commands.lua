if gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name = "Misc default command replacements",
	license = "Public Domain",
	layer = 0,
	enabled = Script.IsEngineMinVersion(104, 0, 53), -- 53 on maintenance branch, 211 on develob
} end

VFS.Include("LuaRules/Configs/customcmds.h.lua") -- for CMD_RAW_MOVE

local preferAssistOverRepair = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isMobileBuilder or unitDef.isFactory then
		preferAssistOverRepair[unitDefID] = true
	end
end

local handlers = {
	[CMD.RECLAIM] = function (unitID)
		if select(5, Spring.GetUnitHealth(unitID)) < 1 then
			return
		end

		return CMD_RAW_MOVE
	end,

	[CMD.REPAIR] = function (unitID)
		if not preferAssistOverRepair[Spring.GetUnitDefID(unitID)]
		or select(5, Spring.GetUnitHealth(unitID)) < 1 then
			return
		end

		return CMD.GUARD
	end,
}

function gadget:DefaultCommand(targetType, targetID, engineCmd)
	if targetType ~= "unit" then
		return
	end

	if handlers[engineCmd] then
		return handlers[engineCmd](targetID)
	end
end