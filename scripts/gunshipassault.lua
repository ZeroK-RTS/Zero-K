local base = piece 'base'
local body = piece 'body'
local firep1 = piece 'firep1'
local firep2 = piece 'firep2'
local wings = piece 'wings'
local fan = piece 'fan'
local Rwingengine = piece 'Rwingengine'
local Lwingengine = piece 'Lwingengine'
local Rengine = piece 'Rengine'
local Lengine = piece 'Lengine'

local smokePiece = {base}

include "constants.lua"

local gun_1 = false
local firestate = Spring.GetUnitStates(unitID).firestate
local spGetUnitVelocity = Spring.GetUnitVelocity

local function TiltWings()
	while true do
		if attacking then
			Turn(wings, x_axis, 0, math.rad(45))
			Sleep(250)
		else
			local vx,_,vz = spGetUnitVelocity(unitID)
			local speed = vx*vx + vz*vz
			Turn(wings, x_axis, math.rad(speed*3), math.rad(45))
			Sleep(250)
		end
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(TiltWings)
	Turn(Lwingengine, x_axis, math.rad(-90), math.rad(500))
	Turn(Rwingengine, x_axis, math.rad(-90), math.rad(500))
end

function script.Activate()
	Spin(fan, y_axis, math.rad(700))
end

function script.Deactivate()
	StopSpin(fan, y_axis, math.rad(3))
end

function script.QueryWeapon(num)
	if gun_1 then return firep1
	else return firep2 end
end

function script.AimFromWeapon(num)
	return body
end

function script.AimWeapon(num, heading, pitch)
	--if num == 1 then return false end
	return true
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 700, 12)
end

function script.Shot(num)
	gun_1 = not gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= .5 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(base, SFX.NONE)
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= .75 then
		Explode(base, SFX.SHATTER)
		Explode(body, SFX.SHATTER)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(body, SFX.SHATTER)
		return 2
	end
end
