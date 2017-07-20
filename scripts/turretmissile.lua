local base = piece 'base'
local turret = piece 'turret'
local lever = piece 'lever'
local pod = piece 'pod'
local l_poddoor = piece 'l_poddoor'
local r_poddoor = piece 'r_poddoor'
local base2 = piece 'base2'
local door = piece 'door'
local doorpist = piece 'doorpist'
local arm = piece 'arm'
local hand = piece 'hand'

local bay = {
	[0] = {
		missile = piece 'm_1',
		exhaust = piece 'ex_1',
		backDoor = piece 'd_1',
		greenLight = piece 'lt_1g',
		redLight = piece 'lt_1r',
		fire = piece 'fire1',
	},
	[1] = {
		missile = piece 'm_2',
		exhaust = piece 'ex_2',
		backDoor = piece 'd_2',
		greenLight = piece 'lt_2g',
		redLight = piece 'lt_2r',
		fire = piece 'fire2',
	},
	[2] = {
		missile = piece 'm_3',
		exhaust = piece 'ex_3',
		backDoor = piece 'd_3',
		greenLight = piece 'lt_3g',
		redLight = piece 'lt_3r',
		fire = piece 'fire3',
	},
}

include "constants.lua"

local scriptReload = include("scriptReload.lua")

local ammo, missile, missilespeed, mfront

local SIG_AIM = 1
local SIG_RESTORE = 2

local ammo = 3
local lights = 3
local shotNum = 0

local gameSpeed = Game.gameSpeed

function script.Create()
	scriptReload.SetupScriptReload(3, 12.5 * gameSpeed)
	StartThread(SmokeUnit, {turret})

	Turn(bay[0].exhaust, x_axis, math.rad(170))
	Turn(bay[1].exhaust, x_axis, math.rad(170))
	Turn(bay[2].exhaust, x_axis, math.rad(170))

	Move(bay[0].fire, x_axis, -0.7)
	Move(bay[1].fire, x_axis, -0.7)
	Move(bay[2].fire, x_axis, -0.7)

	Hide(door)
	Hide(doorpist)
	Hide(arm)
	Hide(hand)
	Hide(base2)
	Move(l_poddoor, x_axis, 4, 5)
	Move(r_poddoor, x_axis, -4, 5)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn(turret, y_axis, 0, math.rad(150))
	Turn(pod, x_axis, 0, math.rad(150))
end

local SleepAndUpdateReload = scriptReload.SleepAndUpdateReload

local function FireAndReload(num)
	Hide(bay[num].missile)
	--Move(bay[num].missile, z_axis, 22, 500)
	Hide(bay[num].greenLight)
	EmitSfx(bay[num].exhaust, UNIT_SFX2)
	Turn(bay[num].backDoor, x_axis, math.rad(100), math.rad(1000))
	Turn(lever, x_axis, math.rad(-5), math.rad(80))
	Turn(pod, x_axis, math.rad(7), math.rad(70))

	Sleep(40)

	shotNum = (shotNum + 1)%3

	scriptReload.GunStartReload(num)

	Turn(lever, x_axis, 0, math.rad(50))
	Turn(pod, x_axis, 0, math.rad(50))
	Turn(bay[num].backDoor, x_axis, 0, math.rad(100))

	SleepAndUpdateReload(num, 8.5 * gameSpeed)

	Move(bay[num].missile, z_axis, -2.2)

	Move(l_poddoor, x_axis, 0, 5)
	Move(r_poddoor, x_axis, 0, 5)
	SleepAndUpdateReload(num, 0.5 * gameSpeed)

	Show(bay[num].missile)
	Move(bay[num].missile, z_axis, 0, 1)
	SleepAndUpdateReload(num, 0.5 * gameSpeed)

	lights = lights + 1
	if lights == 3 then
		Move(l_poddoor, x_axis, 4, 5)
		Move(r_poddoor, x_axis, -4, 5)
		StartThread(RestoreAfterDelay)
	end

	SleepAndUpdateReload(num, 3 * gameSpeed) --8.5 + 0.5 + 0.5 + 3.0 = 12.5 sec reload time as per definition

	Show(bay[num].greenLight)

	if scriptReload.GunLoaded(num) then
		shotNum = 0
	end
	
	ammo = ammo + 1
end

function script.AimFromWeapon()
	return pod
end

function script.QueryWeapon()
	return bay[shotNum].fire
end

function script.AimWeapon(num, heading, pitch)
	if ammo >= 1 then
		Signal(SIG_RESTORE)
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		Turn(turret, y_axis, heading, math.rad(450)) -- left-right
		Turn(pod, x_axis, -pitch, math.rad(450)) --up-down
		WaitForTurn(turret, y_axis)
		WaitForTurn(pod, x_axis)
		return true
	end
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 103, 30)
end

function script.FireWeapon()
	ammo = ammo - 1
	lights = lights - 1
	StartThread(FireAndReload, shotNum)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(base, sfxShatter)
		Explode(lever, sfxNone)
		--Explode(door, sfxNone)
		Explode(pod, sfxNone)
		Explode(bay[0].missile, sfxExplodeOnHit + sfxSmoke)
		Explode(bay[1].missile, sfxExplodeOnHit + sfxSmoke)
		Explode(bay[2].missile, sfxExplodeOnHit + sfxSmoke)
		Explode(bay[0].backDoor, sfxNone)
		Explode(bay[1].backDoor, sfxNone)
		Explode(bay[2].backDoor, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif severity <= 0.50 then
		Explode(base, sfxShatter)
		Explode(lever, sfxFall)
		--Explode(door, sfxFall)
		Explode(pod, sfxShatter)
		Explode(bay[0].missile, sfxFall + sfxExplodeOnHit + sfxSmoke)
		Explode(bay[1].missile, sfxFall + sfxExplodeOnHit + sfxSmoke)
		Explode(bay[2].missile, sfxFall + sfxExplodeOnHit + sfxSmoke)
		Explode(bay[0].backDoor, sfxNone)
		Explode(bay[1].backDoor, sfxNone)
		Explode(bay[2].backDoor, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif severity <= 0.99 then
		Explode(base, sfxShatter)
		Explode(lever, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		--Explode(door, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(pod, sfxFall)
		Explode(bay[0].missile, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(bay[1].missile, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(bay[2].missile, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(bay[0].backDoor, sfxNone + sfxExplodeOnHit)
		Explode(bay[1].backDoor, sfxNone + sfxExplodeOnHit)
		Explode(bay[2].backDoor, sfxNone + sfxExplodeOnHit)
		Explode(turret, sfxNone)
		return 2
	end
	Explode(base, sfxShatter)
	Explode(lever, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	--Explode(door, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(pod, sfxShatter + sfxExplodeOnHit)
	Explode(bay[0].missile, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(bay[1].missile, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(bay[2].missile, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(turret, sfxNone)
	return 2
end