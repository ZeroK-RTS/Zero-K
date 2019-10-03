--linear constant 65536

include "constants.lua"

local base, head, body, barrel, firepoint = piece('base', 'head', 'body', 'barrel', 'firepoint')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')
local vent1, vent2, vent3 = piece('vent1', 'vent2', 'vent3')

local smokePiece = {body}
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
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8
local SIG_BOB = 16
local SIG_FLOAT = 32
local SIG_UNPACK = 64

local wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local PROJECTILE_SPEED = WeaponDefs[wd].projectilespeed

local UNPACK_TIME = 1/3

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local gun_1 = 1

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim functions

local function Bob()
	Signal(SIG_BOB)
	SetSignalMask(SIG_BOB)
	while true do
		Turn(base, x_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Turn(base, z_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Move(base, y_axis, math.rad(math.random(0,6)), math.rad(math.random(2,6)))
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Turn(base, z_axis, math.rad(math.random(-3,3)), math.rad(math.random(1,2)))
		Move(base, y_axis, math.rad(math.random(-6,0)), math.rad(math.random(2,6)))
		Sleep(2000)
	end
end

local function SinkBubbles()
	SetSignalMask(SIG_FLOAT)
	while true do
		EmitSfx(vent1, SFX.BUBBLE)
		EmitSfx(vent2, SFX.BUBBLE)
		EmitSfx(vent3, SFX.BUBBLE)
		Sleep(66)
	end
end

local function dustBottom()
	local x1,y1,z1 = Spring.GetUnitPiecePosDir(unitID,rfoot)
	Spring.SpawnCEG("uw_vindiback", x1, y1+5, z1, 0, 0, 0, 0)
	local x2,y2,z2 = Spring.GetUnitPiecePosDir(unitID,lfoot)
	Spring.SpawnCEG("uw_vindiback", x2, y2+5, z2, 0, 0, 0, 0)
end
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim gadget callins

function Float_startFromFloor()
	dustBottom()
	Signal(SIG_WALK)
	Signal(SIG_FLOAT)
	StartThread(Bob)
end

function Float_stopOnFloor()
	dustBottom()
	Signal(SIG_BOB)
	Signal(SIG_FLOAT)
end

function Float_rising()
	 Signal(SIG_FLOAT)
end

function Float_sinking()
	Signal(SIG_FLOAT)
	StartThread(SinkBubbles)
end

function Float_crossWaterline(speed)
	--Signal(SIG_FLOAT)
end

function Float_stationaryOnSurface()
	Signal(SIG_FLOAT)
end

function unit_teleported(position)
	return GG.Floating_UnitTeleported(unitID, position)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(base, x_axis, 0, math.rad(20))
	Turn(base, z_axis, 0, math.rad(20))
	Move(base, y_axis, 0, 10)
	
	while true do
		--left leg up, right leg back
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lshin, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rshin, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lshin, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rshin, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		WaitForTurn(rthigh, x_axis)
		Sleep(0)
	end
end

function script.StartMoving()
	--Move(lthigh, y_axis, 0, 12)
	--Move(rthigh, y_axis, 0, 12)
	Signal(SIG_UNPACK)
	StartThread(Walk)
end

local function Unpack()
	Signal(SIG_UNPACK)
	SetSignalMask(SIG_UNPACK)
	
	Sleep(UNPACK_TIME)
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
	
	--Move(lthigh, y_axis, 4, 12)
	--Move(rthigh, y_axis, 4, 12)
	
	GG.Floating_StopMoving(unitID)
	
	StartThread(Unpack)
end

function script.StopMoving()
	StartThread(Stopping)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local function WeaponRangeUpdate()
	while true do
		local height = select(2, Spring.GetUnitPosition(unitID))
		if height < -20 then
			Spring.SetUnitWeaponState(unitID, 2, {range = 400-height})
		else
			Spring.SetUnitWeaponState(unitID, 2, {range = 450})
		end
		Sleep(500)
	end
end


function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(WeaponRangeUpdate)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn(head, y_axis, 0, math.rad(65))
	Turn(barrel, x_axis, 0, math.rad(65))
end

function script.AimFromWeapon()
	--Spring.Echo(Spring.GetUnitWeaponState(unitID, 1, "projectileSpeed"))
	--Spring.Echo(PROJECTILE_SPEED)
	
	local height = select(2, Spring.GetUnitBasePosition(unitID))
	if height < -130 then
		Spring.SetUnitWeaponState(unitID,2,{projectileSpeed = 200})
	else
		Spring.SetUnitWeaponState(unitID,2,{projectileSpeed = PROJECTILE_SPEED})
	end
	
	return barrel
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn(head, y_axis, heading, math.rad(360))
		Turn(barrel, x_axis, -pitch, math.rad(180))
		WaitForTurn(head, y_axis)
		WaitForTurn(barrel, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		GG.Floating_AimWeapon(unitID)
		return false
	end
end

function script.QueryWeapon(num)
	return barrel
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/450
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 150.1, 35 * distMult, false, false, true)
	end
	return false
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
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(lfoot, SFX.FALL)
		Explode(lshin, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rshin, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(body, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(body, SFX.SHATTER)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(body, SFX.SHATTER + SFX.EXPLODE)
		return 2
	end
end
