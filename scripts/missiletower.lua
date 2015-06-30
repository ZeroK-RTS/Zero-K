include "constants.lua"

-- Pieces
local base = piece 'base' 
local body = piece 'body' 
local turret = piece 'turret' 
local launcher1 = piece 'launcher1' 
local launcher2 = piece 'launcher2' 
local firepoint1 = piece 'firepoint1' 
local firepoint2 = piece 'firepoint2' 

local shotNum = 1
local firepoint = {firepoint1, firepoint2}

local SIG_AIM = 1
local SIG_SPIN = 2

local RESTORE_DELAY = 2000

local function Spinner()
	Signal(SIG_SPIN)
	SetSignalMask(SIG_SPIN)
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do
		Sleep(1000) 
	end
	while not aiming do
		Turn(turret, y_axis, math.rad(45), math.rad(20))
		WaitForTurn(turret, y_axis)
		Sleep(1000)
		Turn(turret, y_axis, math.rad(-45), math.rad(20))
		WaitForTurn(turret, y_axis)
		Sleep(1000)
	end
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(launcher1, x_axis, math.rad(-30), math.rad(50))
	Turn(launcher2, x_axis, math.rad(-30), math.rad(50))
	aiming = false
	StartThread(Spinner)
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	aiming = true
	
	Turn(turret, y_axis, heading, math.rad(200))
	Turn(launcher1, x_axis, -pitch, math.rad(100))
	Turn(launcher2, x_axis, -pitch, math.rad(100))
	
	--local _, curHeading = Spring.GetUnitPieceDirection(unitID, turret)
	--local curPitch = Spring.GetUnitPieceDirection(unitID, launcher1)
	--
	--local diffHeading = pi - math.abs((curHeading - heading)%tau - pi)
	--local diffPitch = pi - math.abs((curPitch + pitch)%tau - pi)
	--
	--local sleepTime = (diffHeading/math.rad(200))*1000 - 300
	--Spring.Echo(sleepTime)
	--if sleepTime > 0 then
	--	Sleep(sleepTime)
	--end
	WaitForTurn(turret, y_axis)
	WaitForTurn(launcher1, x_axis)
	
	StartThread(RestoreAfterDelay)
	
	return true
end

function script.Shot()
	EmitSfx(firepoint[shotNum], UNIT_SFX1)
	shotNum = 3 - shotNum
end


function script.AimFromWeapon()
	return turret
end

function script.QueryWeapon(piecenum)
	return firepoint[shotNum]
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 1050.2, 40)
end

function script.Create()
	StartThread(SmokeUnit, {base})
	StartThread(RestoreAfterDelay)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(launcher1, sfxNone)
		Explode(launcher2, sfxNone)
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		return 1
	end
	if severity <= 0.50 then
		Explode(launcher1, sfxNone)
		Explode(launcher2, sfxNone)
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		return 1
	end
	if severity <= 0.99 then
		Explode(launcher1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(launcher2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(base, sfxNone)
		Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
	end
	Explode(launcher1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(launcher2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(base, sfxNone)
	Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	return 2
end
