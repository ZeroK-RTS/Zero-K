if not Script.GetSynced() then return end

function gadget:GetInfo() return {
	name    = "Fire Once command",
	author  = "Sprung",
	license = "PD",
	layer   = 0,
	enabled = true,
} end

VFS.Include ("LuaRules/Configs/customcmds.h.lua", nil, VFS.GAME)

--[[ Note, the command exists just because we're out of available modifiers for CMD.ATTACK,
     the actual fire-onciness is implemented through the META (ie. spacebar) modifier for ATTACK
     which is inaccessible otherwise due to it being taken up by command front-insertion already.
     See unit_script.lua for the actual logic involving the command.
]]

local fireOnceCmd = {
	id      = CMD_FIRE_ONCE,
	name    = "Fire Once",
	action  = "fire_once",
	cursor  = 'Attack',
	type    = CMDTYPE.ICON_UNIT_OR_MAP,
	tooltip = "x", -- overridden by integral menu
}

local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
function gadget:UnitCreated(unitID)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD.ATTACK)
	if not cmdDescID then
		return
	end

	--[[ The command exists purely in LuaUI but I am unsure how to make Integral Menu show it
	     if the unit doesn't actually have the command in synced space. Ideally it would be
	     entirely unsynced. ]]
	spInsertUnitCmdDesc(unitID, 510, fireOnceCmd) -- I chose 510 mostly arbitarily
end

local CMD_INSERT = CMD.INSERT
function gadget:AllowCommand(_, _, _, cmdID, cmdParams)

	--[[ The command is supposed to be captured by LuaUI, don't let it actually be given.
	     It shouldn't do much harm if it gets through though (unrecognized commands get
	     dropped anyway). ]]

	if cmdID == CMD_INSERT then
		cmdID = cmdParams[2]
	end
	return cmdID ~= CMD_FIRE_ONCE
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_FIRE_ONCE)

	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		gadget:UnitCreated(allUnits[i])
	end
end
