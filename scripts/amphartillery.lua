--linear constant 65536

include "constants.lua"

local ground, pelvis, turret, gun1, gun2, lleg, rleg, lfoot, rfoot, firept1, firept2 = piece('ground', 'pelvis', 'turret', 'gun1', 'gun2', 'lleg', 'rleg', 'lfoot', 'rfoot', 'firept1', 'firept2')
local SIG_AIM = {}
local firepoints = {[0] = firept1, [1] = firept2}
local barrels = {[0] = gun1, [1] = gun2}

local gun_1 = 0
local firing = 0

local SIG_WALK = 1
local SIG_AIM = {2, 4}
local SIG_RESTORE = 8

local PERIOD = 500
local INTERMISSION = 100

local LEG_FRONT_DISPLACEMENT = 4.2
local LEG_BACK_DISPLACEMENT = -4.2
local LEG_Z_SPEED = 1100 * 8/PERIOD
local LEG_RAISE_DISPLACEMENT = 2
local LEG_Y_SPEED = 1100 * LEG_RAISE_DISPLACEMENT/PERIOD * 2

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 30
local torpRange = 440
local shotRange = 680
local longRange = true

local smokePiece = {pelvis, turret}

local function WeaponRangeUpdate()
	while true do
		local height = select(2, Spring.GetUnitPosition(unitID))
		if height < -32 then
			if longRange then
				Spring.SetUnitWeaponState(unitID, 1, {range = torpRange})
				longRange = false
			end
		elseif not longRange then
			Spring.SetUnitWeaponState(unitID, 1, {range = shotRange})
			longRange = true
		end
		Sleep(200)
	end
end

function script.Create()
	StartThread(WeaponRangeUpdate)
	StartThread(SmokeUnit, smokePiece)	
end

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		-- left leg up and forward, right leg down and back
		Move(lleg, y_axis, LEG_RAISE_DISPLACEMENT, LEG_Y_SPEED)
		Move(lfoot, z_axis, LEG_FRONT_DISPLACEMENT, LEG_Z_SPEED)
		
		Move(rfoot, z_axis, LEG_BACK_DISPLACEMENT, LEG_Z_SPEED)
		Sleep(PERIOD)
		Move(lleg, y_axis, 0, LEG_Y_SPEED)
		Sleep(INTERMISSION)
		
		-- right leg up and forward, left leg down and back
		Move(rleg, y_axis, LEG_RAISE_DISPLACEMENT, LEG_Y_SPEED)
		Move(rfoot, z_axis, LEG_FRONT_DISPLACEMENT, LEG_Z_SPEED)
		
		Move(lfoot, z_axis, LEG_BACK_DISPLACEMENT, LEG_Z_SPEED)
		Sleep(PERIOD)
		Move(rleg, y_axis, 0, LEG_Y_SPEED)
		Sleep(INTERMISSION)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Move(lleg, y_axis, 0, LEG_Y_SPEED)
	Move(lfoot, z_axis, 0, LEG_Z_SPEED)
	Move(rleg, y_axis, 0, LEG_Y_SPEED)
	Move(rfoot, z_axis, 0, LEG_Z_SPEED)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(Stopping)
end

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(6000)
	
	Turn(turret, y_axis, 0, 2)
	Turn(turret, x_axis, 0, 2)
	Turn(gun1, z_axis, 0, 2)
	Turn(gun2, z_axis, 0, 2)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, 1.9)
	Turn(gun1, x_axis, -pitch, 1.75)
	Turn(gun2, x_axis, -pitch, 1.75)
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun1, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	local toChange = 3 - num
	local reloadSpeedMult = Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
	if reloadSpeedMult <= 0 then
		-- Safety for div0. In theory a unit with reloadSpeedMult = 0 cannot fire because it never reloads.
		reloadSpeedMult = 1
	end
	local reloadTimeMult = 1/reloadSpeedMult
	Spring.SetUnitWeaponState(unitID, toChange, "reloadFrame", Spring.GetGameFrame() + reloadTime*reloadTimeMult)
	if num == 2 then
		local px, py, pz = Spring.GetUnitPosition(unitID)
		if py < -8 then
		else
			Spring.PlaySoundFile("sounds/weapon/torp_land.wav", 5, px, py, pz)
		end
	end
	Sleep(150)
	Move(gun1, z_axis, 0, 3)
	Move(gun2, z_axis, 0, 3)
end

function script.Shot(num)
	gun_1 = 1 - gun_1
	Move(barrels[gun_1], z_axis, -2.4)
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return firepoints[gun_1]
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(lfoot, sfxNone)
		Explode(lleg, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rleg, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(lfoot, sfxFall)
		Explode(lleg, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rleg, sfxFall)
		Explode(pelvis, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(lleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(rleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(pelvis, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(lleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(rleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode)
		Explode(pelvis, sfxShatter + sfxExplode)
		return 2
	end
end
