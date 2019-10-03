if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Prevent turret overshoot",
	author  = "Sprung",
	date    = "3rd April 2017",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
} end

local fudgeNames = {
	turretmissile  = 45, -- projectile speed is 25 elmo/frame
	turretheavylaser = 15,
	turretlaser = 15,
}
local sphericals = { -- spherical weapons; rest assumed cylindrical
	"turretheavylaser",
	"turretlaser",
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

-------------------------------------------------------------------------------

local trackedWeaponDefNames = {"turretgauss_gauss"}
local trackedWeaponDefIDs = {}
for i = 1, #trackedWeaponDefNames do
	local wd = WeaponDefNames[trackedWeaponDefNames[i]]
	trackedWeaponDefIDs[wd.id] = wd.range * wd.range
end
trackedWeaponDefNames = nil

local projectiles = {}
local projectileByID = {}
local projCount = 0
function gadget:ProjectileCreated(proID, unitID, weaponID)
	if not unitID then
		return
	end
	local rangeSq = trackedWeaponDefIDs[weaponID]
	if not rangeSq then
		return
	end

	if projCount == 0 then
		gadgetHandler:UpdateCallIn("GameFrame")
	end

	local x, y, z = Spring.GetUnitPosition(unitID)
	if z then
		projCount = projCount + 1
		projectiles[projCount] = {proID, rangeSq, x, y, z}
		projectileByID[proID] = projCount
	end
end

function gadget:ProjectileDestroyed(proID)
	if not projectileByID[proID] then
		return
	end

	local index = projectileByID[proID]

	local lastData = projectiles[projCount]
	projectiles[index] = lastData
	projectiles[projCount] = nil

	local lastProID = lastData[1]
	projectileByID[lastProID] = index
	projectileByID[proID] = nil

	projCount = projCount - 1
	if projCount == 0 then
		gadgetHandler:RemoveCallIn("GameFrame")
	end
end

local spGetProjectilePosition = Spring.GetProjectilePosition
local spDeleteProjectile = Spring.DeleteProjectile
function gadget:GameFrame()
	local i = 0
	while i < projCount do
		i = i + 1
		local projData = projectiles[i]
		local proID, rangeSq = projData[1], projData[2]
		local ux, uy, uz = projData[3], projData[4], projData[5]
		local tx, ty, tz = spGetProjectilePosition(proID)
		local dx, dy, dz = ux-tx, uy-ty, uz-tz
		local distSq = dx*dx + dy*dy + dz*dz
		if distSq > rangeSq then
			local prc = projCount
			spDeleteProjectile(proID)
			if prc == projCount then gadget:ProjectileDestroyed(proID) end -- ugly workaround because it isnt always called
			i = i - 1
		end
	end
end

function gadget:Initialize()
	if projCount == 0 then
		gadgetHandler:RemoveCallIn("GameFrame")
	end
end
