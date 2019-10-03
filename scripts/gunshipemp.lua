local base = piece 'base'
local cap = piece 'cap'
local boosters = piece 'boosters'
local rjet = piece 'rjet'
local jets = piece 'jets'
local ljet = piece 'ljet'
local firepoint = piece 'firepoint'
local weapon = piece 'weapon'
local housing = piece 'housing'
local hinge = piece 'hinge'
local cover1 = piece 'cover1'
local cover2 = piece 'cover2'

local smokePiece = {base}

include "constants.lua"

local SIG_RESTORE = 1

local attacking = false
local spGetUnitVelocity = Spring.GetUnitVelocity

local function TiltWings()
	while true do
		if attacking then
			Turn (base, x_axis, 0, math.rad(100))
			Turn (boosters, x_axis, 0, math.rad(140))
		else
			local vx,_,vz = spGetUnitVelocity(unitID)
			local speed = vx*vx + vz*vz
			Turn (base, x_axis, math.rad (speed * 0.75), math.rad(100))
			Turn (boosters, x_axis, math.rad (speed * 0.75), math.rad(140))
		end
		Sleep (100)
	end
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread (TiltWings)
end

function script.QueryWeapon(num)
	return firepoint
end

function script.AimFromWeapon(num)
	return housing
end

local function RestoreAfterDelay ()
	Signal (SIG_RESTORE)
	SetSignalMask (SIG_RESTORE)
	Sleep (1000)
	Turn (base, y_axis, 0, math.rad(30))
	Turn (cap, x_axis, 0, math.rad(55))
	Turn (boosters, x_axis, 0, math.rad(30))
	Turn (cover1, x_axis, 0, math.rad(25))
	Turn (cover2, x_axis, 0, math.rad(25))
	Move (weapon, y_axis, 0, 7.5)
	attacking = false
end

function script.AimWeapon(num, heading, pitch)
	attacking = true
	Turn (base, y_axis, heading, math.rad(100))
	Turn (cap, x_axis, math.rad(-90) - pitch)
	Turn (cover1, x_axis, math.rad(-25), math.rad(70))
	Turn (cover2, x_axis, math.rad (25), math.rad(70))
	Move (weapon, y_axis, -6.25, 12.5)
	StartThread (RestoreAfterDelay)
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if (severity <= .50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing")) then
		Explode (base, SFX.SHATTER)
		Explode (weapon, SFX.FALL)
		return 1
	else
		Explode (base, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (weapon, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (hinge, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (cap, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (cover1, SFX.SHATTER)
		Explode (cover2, SFX.SHATTER)
		return 2
	end
end
