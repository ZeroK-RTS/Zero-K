function widget:GetInfo() return {
	name = "Misc default command replacements",
	desc = "Implements some right-click behaviour options",
	license = "Public Domain",
	layer = 0,
	enabled = Script.IsEngineMinVersion(104, 0, 53), -- 53 on maintenance branch, 211 on develob
} end

VFS.Include("LuaRules/Configs/customcmds.h.lua") -- for CMD_RAW_MOVE

i18nPrefix = 'miscdefaultcommandreplacements_'
options_path = 'Settings/Unit Behaviour'
options = {
	guard_facs = {
		type = "bool",
		value = true,
		noHotkey = true,
	},
	guard_cons = {
		type = "bool",
		value = true,
		noHotkey = true,
	},
	set_target_instead_of_attack = {
		type = "bool",
		value = false,
		noHotkey = true,
	},
}

local cons, facs = {}, {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isMobileBuilder then
		cons[unitDefID] = true
	end
	if unitDef.isFactory then
		facs[unitDefID] = true
	end
end

local handlers = {
	[CMD.RECLAIM] = function (unitID)
		if (select(5, Spring.GetUnitHealth(unitID)) or 1) < 1 then
			return
		end

		return CMD_RAW_MOVE
	end,

	[CMD.REPAIR] = function (unitID)
		if select(5, Spring.GetUnitHealth(unitID)) < 1 then
			return
		end

		local unitDefID = Spring.GetUnitDefID(unitID)
		if cons[unitDefID] and options.guard_cons.value
		or facs[unitDefID] and options.guard_facs.value
		then
			return CMD.GUARD
		end
	end,

	[CMD.ATTACK] = function (unitID)
		if options.set_target_instead_of_attack.value then
			return CMD_UNIT_SET_TARGET
		end
	end,
}

function widget:DefaultCommand(targetType, targetID, engineCmd)
	if targetType ~= "unit" then
		return
	end

	if handlers[engineCmd] then
		return handlers[engineCmd](targetID)
	end
end
