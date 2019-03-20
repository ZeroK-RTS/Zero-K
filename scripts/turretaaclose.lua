include "constants.lua"

local scriptReload = include("scriptReload.lua")

-- Pieces
local base = piece 'base'
local body = piece 'body'
local turret = piece 'turret'
local launcher1 = piece 'launcher1'
local launcher2 = piece 'launcher2'
local firepoint1 = piece 'firepoint1'
local firepoint2 = piece 'firepoint2'

local shot = 0
local gun = {
	[0] = {firepoint = firepoint1, loaded = true},
	[1] = {firepoint = firepoint2, loaded = true},
}

local SIG_AIM = 1
local SIG_SPIN = 2

local RESTORE_DELAY = 2000

local gameSpeed = Game.gameSpeed

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
	Turn(launcher1, x_axis, -pitch, math.rad(200))
	Turn(launcher2, x_axis, -pitch, math.rad(200))

	--local _, curHeading = Spring.GetUnitPieceDirection(unitID, turret)
	--local curPitch = Spring.GetUnitPieceDirection(unitID, launcher1)
	--
	--local diffHeading = math.pi - math.abs((curHeading - heading)%GG.Script.tau - math.pi)
	--local diffPitch = math.pi - math.abs((curPitch + pitch)%GG.Script.tau - math.pi)
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

local SleepAndUpdateReload = scriptReload.SleepAndUpdateReload

local function reload(num)
	scriptReload.GunStartReload(num)
	gun[num].loaded = false

	SleepAndUpdateReload(num, 15 * gameSpeed)

	if scriptReload.GunLoaded(num) then
		shot = 0
	end
	gun[num].loaded = true
end

function script.Shot()
	EmitSfx(gun[shot].firepoint, GG.Script.UNIT_SFX1)
	StartThread(reload,shot)
	shot = (shot + 1)%2
end


function script.AimFromWeapon()
	return turret
end

function script.QueryWeapon(piecenum)
	return gun[shot].firepoint
end

function script.BlockShot(num, targetID)
	if gun[shot].loaded then
		local distMult = (Spring.ValidUnitID(targetID) and Spring.GetUnitSeparation(unitID, targetID) or 0)/430
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 600.1, 25 * distMult)
	end
	return true
end

function script.Create()
	scriptReload.SetupScriptReload(2, 15 * gameSpeed)
	StartThread(GG.Script.SmokeUnit, {base})
	StartThread(RestoreAfterDelay)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(launcher1, SFX.NONE)
		Explode(launcher2, SFX.NONE)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	end
	if severity <= 0.50 then
		Explode(launcher1, SFX.NONE)
		Explode(launcher2, SFX.NONE)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	end
	if severity <= 0.99 then
		Explode(launcher1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(launcher2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.NONE)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
	Explode(launcher1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(launcher2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(base, SFX.NONE)
	Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	return 2
end
