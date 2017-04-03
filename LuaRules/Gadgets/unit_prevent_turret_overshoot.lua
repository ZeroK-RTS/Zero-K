if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name = "Prevent turret overshoot",
	layer = 0,
	enabled = true,
} end

local fudgeNames = {
	corrl  = 20,
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


local CMD_INSERT = CMD.INSERT
local CMD_ATTACK = CMD.ATTACK


function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)

	if not allowedRangeSq[unitDefID] then
		return true
	end

	local paramCount = #cmdParams
	if not ((cmdID == CMD_ATTACK and paramCount == 3) or (cmdID == CMD_INSERT and paramCount == 6)) then
		return true
	end

	local tx, ty, tz
	if cmdID == CMD_ATTACK then
		tx = cmdParams[1]
		ty = cmdParams[2]
		tz = cmdParams[3]
	else
		tx = cmdParams[4]
		ty = cmdParams[5]
		tz = cmdParams[6]
	end

	local ux, uy, uz = Spring.GetUnitPosition(unitID)
	local dx, dy, dz = ux-tx, uy-ty, uz-tz

	local distSq = dx*dx + dz*dz
	if isSpherical[unitDefID] then
		distSq = distSq + dy*dy
	end

	if distSq < allowedRangeSq then
		return true
	end

	return false
end
