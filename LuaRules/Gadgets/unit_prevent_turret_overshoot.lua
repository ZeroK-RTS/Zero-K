if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Prevent turret overshoot",
	author  = "Sprung",
	date    = "3rd April 2017",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
} end

local allowedRangeSqByWeapon = {}
local isSphericalByWeapon = {}

for weaponDefID = 1, #WeaponDefs do
	local wd = WeaponDefs[weaponDefID]
	local fudge = tonumber(wd.customParams.prevent_overshoot_fudge)

	if (fudge and fudge ~= 0) then
		local allowedRange = wd.range - fudge

		allowedRangeSqByWeapon[weaponDefID] = allowedRange*allowedRange
		isSphericalByWeapon[weaponDefID] = (wd.cylinderTargeting == 0)
	end
end

local isSpherical = {}
local allowedRangeSq = {}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	local weapons = ud.weapons

	if (weapons) then
        for i = 1, #weapons do
			local weaponDefID = weapons[i].weaponDef

			if (allowedRangeSqByWeapon[weaponDefID]) then
				allowedRangeSq[unitDefID] = allowedRangeSqByWeapon[weaponDefID]
				isSpherical[unitDefID] = isSphericalByWeapon[weaponDefID]
				break
			end
        end
    end
end

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
