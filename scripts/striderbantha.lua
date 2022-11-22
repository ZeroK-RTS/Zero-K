include "constants.lua"

-- body
local pelvis = piece "pelvis"
local body = piece "body"
local head = piece "head"
local headflare = piece "headflare"
local torso = piece "torso"
local lmissiles = piece "lmissiles"
local rmissiles = piece "rmissiles"
local lmissileflare = piece "lmissileflare"
local rmissileflare = piece "rmissileflare"

--left arm
local larm = piece "larm"
local larmgun = piece "larmgun"
local larm_lgunclaw = piece "larm_lgunclaw"
local larm_rgunclaw = piece "larm_rgunclaw"
local larmflare = piece "larmflare"

--right arm
local rarm = piece "rarm"
local rarmgun = piece "rarmgun"
local rarm_lgunclaw = piece "rarm_lgunclaw"
local rarm_rgunclaw = piece "rarm_rgunclaw"
local rarmflare = piece "rarmflare"

-- left leg
local lupleg = piece "lupleg"
local lleg = piece "lleg"
local lfoot = piece "lfoot"
local ltoef = piece "ltoef"
local ltoer = piece "ltoer"

--right leg
local rupleg = piece "rupleg"
local rleg = piece "rleg"
local rfoot = piece "rfoot"
local rtoef = piece "rtoef"
local rtoer = piece "rtoer"

-- legs
local leftLeg = {thigh=piece("lupleg"), shin=piece("lleg"), foot=piece("lfoot"), toef=piece("ltoef"), toeb=piece("ltoer")}
local rightLeg = {thigh=piece("rupleg"), shin=piece("rleg"), foot=piece("rfoot"), toef=piece("rtoef"), toeb=piece("rtoer")}

local smokePiece = { torso, rarmgun, larm_rgunclaw }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Balance

local ARM_AIM_SPEED = 2.7
local HEAD_AIM_SPEED = 2.4

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim = 4
local SIG_Aim2 = 8
local SIG_Idle = 32
local armGunIsR = false
local missilegun = 1
local PACE = 1.15

local LEG_FRONT_ANGLES    = { thigh=math.rad(-35), shin=math.rad(5), foot=math.rad(0), toef=math.rad(0), toeb=math.rad(25) }
local LEG_FRONT_SPEEDS    = { thigh=math.rad(90)*PACE, shin=math.rad(150)*PACE, foot=math.rad(90)*PACE, toef=math.rad(90)*PACE, toeb=math.rad(90)*PACE }

local LEG_STRAIGHT_ANGLES = { thigh=math.rad(-6), shin=math.rad(6), foot=math.rad(0), toef=math.rad(0), toeb=math.rad(0) }
local LEG_STRAIGHT_SPEEDS = { thigh=math.rad(90)*PACE, shin=math.rad(90)*PACE, foot=math.rad(90)*PACE, toef=math.rad(90)*PACE, toeb=math.rad(90)*PACE }

local LEG_BACK_ANGLES     = { thigh=math.rad(25), shin=math.rad(5), foot=math.rad(0), toef=math.rad(-25), toeb=math.rad(0) }
local LEG_BACK_SPEEDS     = { thigh=math.rad(72)*PACE, shin=math.rad(90)*PACE, foot=math.rad(90)*PACE, toef=math.rad(90)*PACE, toeb=math.rad(90)*PACE }

local LEG_BENT_ANGLES     = { thigh=math.rad(-30), shin=math.rad(95), foot=math.rad(0), toef=math.rad(0), toeb=math.rad(0) }
local LEG_BENT_SPEEDS     = { thigh=math.rad(120)*PACE, shin=math.rad(280)*PACE, foot=math.rad(90)*PACE, toef=math.rad(800)*PACE, toeb=math.rad(60)*PACE }

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(15)*PACE

-- body rise/fall with steps
local PELVIS_LIFT_HEIGHT = 0
local PELVIS_LIFT_SPEED = 8
local PELVIS_LOWER_HEIGHT = -1
local PELVIS_LOWER_SPEED = 5

local ARM_FRONT_ANGLE = math.rad(-15)
local ARM_FRONT_SPEED = math.rad(35) * PACE
local ARM_BACK_ANGLE = math.rad(10)
local ARM_BACK_SPEED = math.rad(35) * PACE
local ARM_SIDE_ANGLE = math.rad(5)

local isFiring = false
local isFiringBeam = false

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[3] and UnitDefs[unitDefID].weapons[3].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 30

wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTimeShort = wd and WeaponDefs[wd].reload*30 or 30

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function script.Create()
	Turn(larm, z_axis, -0.1)
	Turn(rarm, z_axis, 0.1)
	Turn(lmissileflare, z_axis, math.rad(-90))
	Turn(rmissileflare, z_axis, math.rad(-90))
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

local function IdleAnim()
	Signal(SIG_Idle)
	SetSignalMask(SIG_Idle)
	Sleep(12000)
	while true do
		local shoulder, arm, lclaw, rclaw
		if armGunIsR then
			shoulder, arm, lclaw, rclaw = larm, larmgun, larm_lgunclaw, larm_rgunclaw
			Turn(head, y_axis, math.rad(30), math.rad(60))
		else
			shoulder, arm, lclaw, rclaw = rarm, rarmgun, rarm_lgunclaw, rarm_rgunclaw
			Turn(head, y_axis, math.rad(-30), math.rad(60))
		end
		armGunIsR = not armGunIsR
		Turn(arm, x_axis, math.rad(-20), math.rad(45))
		Turn(shoulder, x_axis, math.rad(-20), math.rad(45))
		Sleep(2000)
		Turn(lclaw, y_axis, math.rad(30), math.rad(180))
		Turn(rclaw, y_axis, math.rad(-30), math.rad(180))
		Sleep(1500)
		Turn(lclaw, y_axis, 0, math.rad(180))
		Turn(rclaw, y_axis, 0, math.rad(180))
		Sleep(2000)
		Turn(arm, x_axis, 0, math.rad(60))
		Turn(shoulder, x_axis, 0, math.rad(60))
		Turn(head, y_axis, 0, math.rad(60))
		Sleep(6500)
	end
end

local function Step(frontLeg, backLeg)
	-- front leg out straight, back toe angled to meet the ground
	-- back leg out straight, front toe angled to leave the ground
	for i, p in pairs(frontLeg) do
		Turn(frontLeg[i], x_axis, LEG_FRONT_ANGLES[i], LEG_FRONT_SPEEDS[i])
		Turn(backLeg[i], x_axis, LEG_BACK_ANGLES[i], LEG_BACK_SPEEDS[i])
	end

	--lower body at extended stride
	Move(pelvis, y_axis, PELVIS_LOWER_HEIGHT, PELVIS_LOWER_SPEED)

	-- swing arms and body
	if not(isFiring) then
		if (frontLeg == leftLeg) then
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(larmgun, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(rarm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(rarmgun, x_axis, -ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
		else
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(larmgun, x_axis, -ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(rarm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(rarmgun, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
		end
	end

	-- wait for leg rotations (ignore backheel of back leg - it's in the air)
	for i, p in pairs(frontLeg) do
		WaitForTurn(frontLeg[i], x_axis)
		WaitForTurn(backLeg[i], x_axis)
	end

	-- front leg straight, foot flat on ground
	-- back knee bent, drags foot past front leg
	for i, p in pairs(frontLeg) do
		Turn(frontLeg[i], x_axis, LEG_STRAIGHT_ANGLES[i], LEG_STRAIGHT_SPEEDS[i])
		Turn(backLeg[i], x_axis, LEG_BENT_ANGLES[i], LEG_BENT_SPEEDS[i])
	end

	-- raise body as leg passes underneath
	Move(pelvis, y_axis, PELVIS_LIFT_HEIGHT, PELVIS_LIFT_SPEED)

	for i, p in pairs(frontLeg) do
		WaitForTurn(frontLeg[i], x_axis)
		WaitForTurn(backLeg[i], x_axis)
	end
end

local function Passing(frontLeg, backLeg)
	
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	-- tilt arms out a bit so they don't scrape body
	Turn(larm, z_axis, ARM_SIDE_ANGLE, ARM_BACK_SPEED)
	Turn(rarm, z_axis, -ARM_SIDE_ANGLE, ARM_FRONT_SPEED)

	while (true) do
		-- left leg
		Step(leftLeg, rightLeg)
		-- right leg
		Step(rightLeg, leftLeg)
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	-- straighten legs
	for i, p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0, 4)
		Move(leftLeg[i], y_axis, 0, 4)
		Turn(rightLeg[i], x_axis, 0, 4)
		Move(rightLeg[i], y_axis, 0, 4)
	end

	-- and arms
	Turn(larm, z_axis, 0, ARM_BACK_SPEED)
	Turn(rarm, z_axis, 0, ARM_BACK_SPEED)

	if not(isFiring) then
		Turn(body, z_axis, 0, 1)
		Turn(torso, y_axis, 0, 4)
		Move(pelvis, y_axis, 0, 4)
		Turn(pelvis, z_axis, 0, 1)
		Turn(larm, z_axis, 0, 1)
		Turn(rarm, z_axis, 0, 1)
		Turn(rarmgun, x_axis, 0, 1)
		Turn(larmgun, x_axis, 0, 1)
		StartThread(IdleAnim)
	end
end

function script.StartMoving()
	Signal(SIG_Idle)
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end


local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(6000)
	Turn(head, y_axis, 0, 3)
	Turn(torso, y_axis, 0, 3)
	Turn(larm, x_axis, 0, 3)
	Turn(rarm, x_axis, 0, 3)
	isFiring = false
	StartThread(IdleAnim)
end


local function missilelaunch()
	Hide (lmissiles)
	Hide (rmissiles)
	Sleep(30000)
	Show (lmissiles)
	Show (rmissiles)
end

local function armrecoil()
	if not armGunIsR then
		EmitSfx(larmflare, 1024)
		EmitSfx(larmflare, 1025)

		Move(larmgun, z_axis, -6)
		Turn(larm_lgunclaw, y_axis, math.rad(45))
		Turn(larm_rgunclaw, y_axis, math.rad(-45))

		Move(larmgun, z_axis, 0, 3)
		Turn(larm_lgunclaw, y_axis, 0, 0.5)
		Turn(larm_rgunclaw, y_axis, 0, 0.5)
	else
		EmitSfx(rarmflare, 1024)
		EmitSfx(rarmflare, 1025)

		Move(rarmgun, z_axis, -6)
		Turn(rarm_lgunclaw, y_axis, math.rad(45))
		Turn(rarm_rgunclaw, y_axis, math.rad(-45))

		Move(rarmgun, z_axis, 0, 3)
		Turn(rarm_lgunclaw, y_axis, 0, 0.5)
		Turn(rarm_rgunclaw, y_axis, 0, 0.5)
	end
	Sleep(33)
	armGunIsR = not armGunIsR
end

function script.QueryWeapon(num)
	if num == 1 then
		return headflare
	elseif num == 2 then
		if armGunIsR then return rarmflare
		else return larmflare end
	elseif num == 3 then
		if missilegun == 1 then
			return lmissiles
		elseif missilegun == 2 then
			return rmissiles
		end
	end
	return headflare
end

function script.AimFromWeapon(num)
	if num == 1 or num == 3 then
		return headflare
	elseif num == 2 then
		return torso
	end
	return headflare
end

local beam_duration = WeaponDefs[UnitDef.weapons[1].weaponDef].beamtime * 1000
function script.FireWeapon(num)
	if num ~= 1 then
		return
	end

	isFiringBeam = true
	Sleep(beam_duration)
	isFiringBeam = false
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Idle)
	if num == 1 then
		Signal(SIG_Aim)
		SetSignalMask(SIG_Aim)
		while isFiringBeam do
			Sleep(100)
		end
		Turn(head, y_axis, heading, HEAD_AIM_SPEED)
		Turn(headflare, x_axis, -pitch, HEAD_AIM_SPEED)
		WaitForTurn(head, y_axis)
		WaitForTurn(headflare, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		Signal(SIG_Aim2)
		SetSignalMask(SIG_Aim2)
		isFiring = true

		Turn(torso, y_axis, heading, ARM_AIM_SPEED)
		Turn(larm, x_axis, -pitch, ARM_AIM_SPEED)
		Turn(rarm, x_axis, -pitch, ARM_AIM_SPEED)
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 3 then
		return true
	end
	return true
end


function script.Shot(num)
	if num == 2 then
		StartThread(armrecoil)
	elseif num == 3 then
		missilegun = (missilegun % 2) + 1
		StartThread(missilelaunch)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(body, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(lleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rarmgun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(larmgun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(larm, SFX.SHATTER)
		Explode(lmissiles, SFX.SHATTER)
		Explode(rmissiles, SFX.SHATTER)
		Turn(torso, y_axis, 0, 50)
		Turn(rarmgun, y_axis, 30, 20)
		Turn(larmgun, y_axis, 30, 20)

		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(800)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(body, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(pelvis, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(body, SFX.SHATTER)
		Explode(head, SFX.SMOKE + SFX.FIRE)
		Explode(pelvis, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
