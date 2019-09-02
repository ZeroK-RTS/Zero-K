--linear constant 65536

include "constants.lua"

local base, torso, head = piece('base', 'torso', 'head')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local lturret, rturret, lflare, rflare = piece('lturret', 'rturret', 'lflare', 'rflare')

local firepoints = {[0] = lflare, [1] = rflare}

local smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 2

local THIGH_FRONT_ANGLE = -math.rad(50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local SHIN_FRONT_ANGLE = math.rad(45)
local SHIN_FRONT_SPEED = math.rad(90) * PACE
local SHIN_BACK_ANGLE = math.rad(10)
local SHIN_BACK_SPEED = math.rad(90) * PACE

local ARM_FRONT_ANGLE = -math.rad(20)
local ARM_FRONT_SPEED = math.rad(22.5) * PACE
local ARM_BACK_ANGLE = math.rad(10)
local ARM_BACK_SPEED = math.rad(22.5) * PACE
local FOREARM_FRONT_ANGLE = -math.rad(40)
local FOREARM_FRONT_SPEED = math.rad(45) * PACE
local FOREARM_BACK_ANGLE = math.rad(10)
local FOREARM_BACK_SPEED = math.rad(45) * PACE

local SIG_WALK = 1
local SIG_AIM = {2, 4}
local SIG_RESTORE = 8

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 30
local torpRange = WeaponDefNames["amphraid_torpedo"].range
local shotRange = WeaponDefNames["amphraid_torpmissile"].range
local longRange = true

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local gun_1 = 0
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--Spring.Echo("Left foot up, right foot down")
		Turn(lthigh, x_axis, math.rad(20), math.rad(120)*PACE)
		Turn(lshin, x_axis, math.rad(-60), math.rad(140)*PACE)
		Turn(lfoot, x_axis, math.rad(40), math.rad(210)*PACE)
		Turn(rthigh, x_axis, math.rad(-20), math.rad(210)*PACE)
		Turn(rshin, x_axis, math.rad(50), math.rad(210)*PACE)
		Turn(rfoot, x_axis, math.rad(-30), math.rad(210)*PACE)
		Turn(torso, z_axis, math.rad(-5), math.rad(20)*PACE)
		Turn(lthigh, z_axis, math.rad(5), math.rad(20)*PACE)
		Turn(rthigh, z_axis, math.rad(5), math.rad(420)*PACE)
		Move(torso, y_axis, 4, 9*PACE)
		WaitForMove(torso, y_axis)
		Sleep(0)	-- needed to prevent anim breaking, DO NOT REMOVE
		
		--Spring.Echo("Right foot middle, left foot middle")
		Turn(lthigh, x_axis, math.rad(-10), math.rad(160)*PACE)
		Turn(lshin, x_axis, math.rad(-40), math.rad(250)*PACE)
		Turn(lfoot, x_axis, math.rad(50), math.rad(140)*PACE)
		Turn(rthigh, x_axis, math.rad(40), math.rad(140)*PACE)
		Turn(rshin, x_axis, math.rad(-40), math.rad(140)*PACE)
		Turn(rfoot, x_axis, math.rad(0), math.rad(140)*PACE)
		Move(torso, y_axis, 0, 12*PACE)
		WaitForMove(torso, y_axis)
		Sleep(0)
		
		--Spring.Echo("Right foot up, Left foot down")
		Turn(rthigh, x_axis, math.rad(20), math.rad(120)*PACE)
		Turn(rshin, x_axis, math.rad(-60), math.rad(140)*PACE)
		Turn(rfoot, x_axis, math.rad(40), math.rad(210)*PACE)
		Turn(lthigh, x_axis, math.rad(-20), math.rad(210)*PACE)
		Turn(lshin, x_axis, math.rad(50), math.rad(210)*PACE)
		Turn(lfoot, x_axis, math.rad(-30), math.rad(420)*PACE)
		Turn(torso, z_axis, math.rad(5), math.rad(20)*PACE)
		Turn(lthigh, z_axis, math.rad(-5), math.rad(20)*PACE)
		Turn(rthigh, z_axis, math.rad(-5), math.rad(20)*PACE)
		Move(torso, y_axis, 4, 9*PACE)
		WaitForMove(torso, y_axis)
		Sleep(0)
		
		--Spring.Echo("Left foot middle, right foot middle")
		Turn(rthigh, x_axis, math.rad(-10), math.rad(160)*PACE)
--		Turn(rknee, x_axis, math.rad(15), math.rad(135)*PACE)
		Turn(rshin, x_axis, math.rad(-40), math.rad(250)*PACE)
		Turn(rfoot, x_axis, math.rad(50), math.rad(140)*PACE)
		Turn(lthigh, x_axis, math.rad(40), math.rad(140)*PACE)
--		Turn(lknee, x_axis, math.rad(-35), math.rad(135))
		Turn(lshin, x_axis, math.rad(-40), math.rad(140)*PACE)
		Turn(lfoot, x_axis, math.rad(0), math.rad(140)*PACE)
		Move(torso, y_axis, 0, 12*PACE)
		WaitForMove(torso, y_axis)
		Sleep(0)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	Turn(rthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(rshin, x_axis, 0, math.rad(120)*PACE)
	Turn(rfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(lthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(lshin, x_axis, 0, math.rad(80)*PACE)
	Turn(lfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(torso, z_axis, 0, math.rad(20)*PACE)
	Move(torso, y_axis, 0, 12*PACE)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(Stopping)
end

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
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(WeaponRangeUpdate)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn(head, y_axis, 0, math.rad(65))
	Turn(lturret, x_axis, 0, math.rad(47.5))
	Turn(rturret, x_axis, 0, math.rad(47.5))
end

function script.AimFromWeapon()
	return head
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM[num])
	SetSignalMask(SIG_AIM[num])
	Turn(head, y_axis, heading, math.rad(240))
	Turn(lturret, x_axis, -pitch, math.rad(120))
	Turn(rturret, x_axis, -pitch, math.rad(120))
	WaitForTurn(head, y_axis)
	WaitForTurn(lturret, x_axis)
	WaitForTurn(rturret, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.QueryWeapon(num)
	return firepoints[gun_1]
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
			Spring.PlaySoundFile("sounds/weapon/torpedo.wav", 8, px, py, pz)
		else
			Spring.PlaySoundFile("sounds/weapon/torp_land.wav", 5, px, py, pz)
		end
	end
end

function script.BlockShot(num, targetID)
	if num == 1 then -- surface missiles
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 229, 40, 0.25)
	elseif num == 2 then -- torpedoes
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 229, 40)
	end
	return false
end

function script.Shot(num)
	gun_1 = 1 - gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(lfoot, SFX.NONE)
		Explode(lshin, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rshin, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(lfoot, SFX.FALL)
		Explode(lshin, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rshin, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(torso, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		return 2
	end
end
