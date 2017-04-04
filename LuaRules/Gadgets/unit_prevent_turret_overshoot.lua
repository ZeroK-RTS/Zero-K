if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name = "Prevent turret overshoot",
	layer = 0,
	enabled = true,
} end

local fudgeNames = {
	corrl  = 25, -- projectile speed is 25 elmo/frame
	corhlt = 5,
	corllt = 5,
}
local sphericals = { -- spherical weapons; rest assumed cylindrical
	"corhlt",
	"corllt",
}


local isSpherical = {}
for i = 1, #sphericals do
	isSpherical[UnitDefNames[sphericals[i]].id] = true
end
sphericals = nil

local allowedRangeSq = {}
for name, fudge in pairs(fudgeNames) do
	local udid = UnitDefNames[name].id
	local range = WeaponDefs[UnitDefs[udid].weapons[1].weaponDef].range
	local allowedRange = range - fudge
	allowedRangeSq[udid] = allowedRange*allowedRange
end
fudgeNames = nil


include "LuaRules/Configs/customcmds.h.lua"

local blockedCmds = {
	[CMD.ATTACK] = true,
	[CMD.INSERT] = true,
	[CMD_UNIT_SET_TARGET] = true,
}


function gadget:AllowCommand_GetWantedCommand()	
	return blockedCmds
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return allowedRangeSq
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)
	local paramCount = #cmdParams

	if cmdID == CMD_INSERT then
		cmdID = cmdParams[2]
		for i = 4, paramCount do
			cmdParams[i - 3] = cmdParams[i]
		end
		paramCount = paramCount - 3
	end
	if not blockedCmds[cmdID] then
		return true
	end

	-- 3 is attack ground, 4 is usually attack units in radius but becomes attack ground when R=0
	if paramCount ~= 3 and (paramCount ~= 4 or cmdParams[4] ~= 0) then
		return true
	end

	local tx, ty, tz = cmdParams[1], cmdParams[2], cmdParams[3]
	local ux, uy, uz = Spring.GetUnitPosition(unitID)
	local dx, dy, dz = ux-tx, uy-ty, uz-tz

	local distSq = dx*dx + dz*dz
	if isSpherical[unitDefID] then
		distSq = distSq + dy*dy
	end

	if distSq < allowedRangeSq[unitDefID] then
		return true
	end

	return false
end
