include "constants.lua"

--pieces
local base, turret, sleeve, barrel, flare = piece("base", "turret", "sleeve", "barrel", "flare")
local wake1, wake2, wake3, wake4, wake5, wake6, wake7, wake8, ground = piece("wake1", "wake2", "wake3", "wake4", "wake5", "wake6", "wake7", "wake8", "ground1")

local smokePiece = { base, turret }

--constants
local restoreDelay = 6000
local turretSpeed = math.rad(160)
local sleeveSpeed = math.rad(80)
local tiltSpeed = math.rad(3)
local barrelSpeed = 5
local bounceSpeed = 3
local bounceHeight = 30

--variables
local wobbleDir = false
local terrain = 4
local tiltX, tiltZ = 0, 0

--signals
local SIG_Aim  = 1
local SIG_Move = 2

local function Bounce()
	while true do
		if wobbleDir then Move(base, y_axis, bounceHeight, bounceSpeed)
		else Move(base, y_axis, 0, bounceSpeed) end
		wobbleDir = not wobbleDir
		Sleep(1500)
	end
end

local function Wobble()
	while true do
		tiltX = math.rad(math.random(0,5))
		tiltZ = math.rad(math.random(0,5))
		Turn(base, x_axis, tiltX, tiltSpeed)
		Turn(base, z_axis, tiltZ, tiltSpeed)
		WaitForTurn(base, x_axis)
		Sleep(200)
		Turn(base, x_axis, -tiltX, tiltSpeed)
		Turn(base, z_axis, -tiltZ, tiltSpeed)
		WaitForTurn(base, x_axis)
		Sleep(200)		
	end
end

local function HoverFX()
	while true do
		if terrain <= 2 then
			if math.random() < 0.5 then
				EmitSfx(wake1, 5)
				EmitSfx(wake3, 5)
				EmitSfx(wake5, 5)
				EmitSfx(wake7, 5)
				EmitSfx(wake1, 3)
				EmitSfx(wake3, 3)
				EmitSfx(wake5, 3)
				EmitSfx(wake7, 3)
			else
				EmitSfx(wake2, 5)
				EmitSfx(wake4, 5)
				EmitSfx(wake6, 5)
				EmitSfx(wake8, 5)
				EmitSfx(wake2, 3)
				EmitSfx(wake4, 3)
				EmitSfx(wake6, 3)
				EmitSfx(wake8, 3)
			end
		else
			EmitSfx(ground,1024)
		end
		Sleep(150)
	end
end

function script.Create()
	StartThread(Bounce)
	StartThread(Wobble)
	StartThread(HoverFX)
	StartThread(SmokeUnit,smokePiece, smokePiece)
end

function script.setSFXoccupy(curTerrainType)
	terrain = curTerrainType
end

function script.StartMoving()
	--Signal(SIG_Move)
	--SetSignalMask(SIG_Move)
end

function script.StopMoving()
end

local function RestoreAfterDelay()
	Sleep(restoreDelay)
	Turn( turret, y_axis, 0, turretSpeed/4)
	Turn( sleeve,  x_axis, 0, sleeveSpeed/4)
end

function script.QueryWeapon(weaponNum) return flare end

function script.AimFromWeapon(weaponNum) return turret end

function script.AimWeapon(weaponNum, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(turret, y_axis, heading, turretSpeed)
	Turn(sleeve,  x_axis, -pitch, sleeveSpeed)
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(weaponNum)
	EmitSfx(flare, 1024+1)
	Move(barrel, z_axis, -3)
	Sleep(150)
	Move(barrel, z_axis, 0, barrelSpeed)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(sleeve, sfxNone)
		Explode(barrel, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, sfxFall + sfxSmoke + sfxFire)
		Explode(turret, sfxFall + sfxSmoke + sfxFire)
		Explode(sleeve, sfxFall + sfxSmoke)
		Explode(barrel, sfxFall + sfxSmoke)
		return 2
	else		
		Explode(base, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(sleeve, sfxFall + sfxSmoke + sfxFire)
		Explode(barrel, sfxFall + sfxSmoke + sfxFire)
		return 3 -- corpsetype
	end
end
