local base = piece 'base'
local body = piece 'body'
local rfx = piece 'rfx'
local rjet = piece 'rjet'
local lfx = piece 'lfx'
local ljet = piece 'ljet'
local emit = piece 'emit'
local gun = piece 'gun'

local smokePiece = {base}

include "constants.lua"

local SIG_RESTORE = 1

local spGetUnitVelocity = Spring.GetUnitVelocity

local function TiltWings()
	while true do
		local vx,_,vz = spGetUnitVelocity(unitID)
		local speed = vx*vx + vz*vz
		Turn (rjet, x_axis, math.rad(2 * speed), math.rad(60))
		Turn (ljet, x_axis, math.rad(2 * speed), math.rad(60))
		Sleep(100)
	end
end

local function RestoreAfterDelay ()
	Signal (SIG_RESTORE)
	SetSignalMask (SIG_RESTORE)
	Sleep (3000)
	Turn (gun, y_axis, 0, math.rad(20))
	Turn (gun, x_axis, 0, math.rad(20))
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, smokePiece)
	StartThread (TiltWings)
	Hide (lfx)
	Hide (rfx)
	Hide (emit)
	Turn (rfx, x_axis, math.rad(90))
	Turn (lfx, x_axis, math.rad(90))
end

function script.QueryWeapon(num)
	return emit
end

function script.AimFromWeapon(num)
	return gun
end

function script.AimWeapon(num, heading, pitch)
	Turn (gun, y_axis, heading, math.rad(360))
	Turn (gun, x_axis, -pitch, math.rad(360))
	StartThread (RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	Turn (rjet, x_axis, 0, math.rad(70))
	Turn (ljet, x_axis, 0, math.rad(70))
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if (severity <= .50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing")) then
		Explode (body, SFX.SHATTER)
		Explode (rjet, SFX.FALL)
		return 1
	else
		Explode (gun, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (ljet, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (rjet, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode (body, SFX.SHATTER)
		return 2
	end
end
