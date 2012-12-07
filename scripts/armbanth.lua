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

--left leg
local lupleg = piece "lupleg"
local lleg = piece "lleg"
local lfoot = piece "lfoot"
local ltoef = piece "ltoef"
local ltoeb = piece "ltoer"
local leftLeg = {lupleg, lleg, lfoot, ltoef, ltoeb}

--right leg
local rupleg = piece "rupleg"
local rleg = piece "rleg"
local rfoot = piece "rfoot"
local rtoef = piece "rtoef"
local rtoeb = piece "rtoer"
local rightLeg = {rupleg, rleg, rfoot, rtoef, rtoeb}

smokePiece = { torso, rarmgun, larm_rgunclaw }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim  = 4
local SIG_Aim2  = 8
local SIG_Aim3  = 16
local armgun = false
local missilegun = 1
local PACE = 1.4

local THIGH_FRONT_ANGLE = math.rad(-35)
local THIGH_FRONT_SPEED = math.rad(80) * PACE
local THIGH_STRAIGHT_ANGLE = math.rad(-6)
local THIGH_STRAIGHT_SPEED = math.rad(90) * PACE
local THIGH_MID_ANGLE = math.rad(-30)
local THIGH_MID_SPEED = math.rad(120) * PACE
local THIGH_BACK_ANGLE = math.rad(15)
local THIGH_BACK_SPEED = math.rad(72) * PACE

local SHIN_FRONT_ANGLE = math.rad(5)
local SHIN_FRONT_SPEED = math.rad(180) * PACE
local SHIN_STRAIGHT_ANGLE = math.rad(6)
local SHIN_STRAIGHT_SPEED = math.rad(90) * PACE
local SHIN_MID_ANGLE = math.rad(95)
local SHIN_MID_SPEED = math.rad(285) * PACE
local SHIN_BACK_ANGLE = math.rad(5)
local SHIN_BACK_SPEED = math.rad(90) * PACE

local TOEF_FRONT_ANGLE = math.rad(0)
local TOEF_FRONT_SPEED = math.rad(90) * PACE
local TOEF_BACK_ANGLE = math.rad(-15)
local TOEF_BACK_SPEED = math.rad(90) * PACE

local TOEB_FRONT_ANGLE = math.rad(15)
local TOEB_FRONT_SPEED = math.rad(90) * PACE
local TOEB_BACK_ANGLE = math.rad(0)
local TOEB_BACK_SPEED = math.rad(60) * PACE

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(15)*PACE

local ARM_FRONT_ANGLE = math.rad(-15)
local ARM_FRONT_SPEED = math.rad(25) * PACE
local ARM_BACK_ANGLE = math.rad(10)
local ARM_BACK_SPEED = math.rad(25) * PACE
local ARM_SIDE_ANGLE = math.rad(5)

local isFiring = false

local CHARGE_TIME = 60	-- frames
local FIRE_TIME = 120

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[3] and UnitDefs[unitDefID].weapons[3].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 30

wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTimeShort = wd and WeaponDefs[wd].reload*30 or 30

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function script.Create()
	Turn( larm, z_axis, -0.1)
	Turn( rarm, z_axis, 0.1)	
	Turn( lmissileflare, z_axis, math.rad(-90))
	Turn( rmissileflare, z_axis, math.rad(-90))	
	StartThread(SmokeUnit)
end

local function Contact(frontLeg, backLeg)
	-- front leg out straight, back toe angled to meet the ground
	Turn(frontLeg[1], x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
	Turn(frontLeg[2], x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
	Turn(frontLeg[4], x_axis, TOEF_FRONT_ANGLE, TOEF_FRONT_SPEED)
	Turn(frontLeg[5], x_axis, TOEB_FRONT_ANGLE, TOEB_FRONT_SPEED)

	-- back leg out straight, front toe angled to leave the ground
	Turn(backLeg[1], x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
	Turn(backLeg[2], x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
	Turn(backLeg[4], x_axis, TOEF_BACK_ANGLE, TOEF_BACK_SPEED)
	Turn(backLeg[5], x_axis, TOEB_BACK_ANGLE, TOEB_BACK_SPEED)

	-- swing arms and body
	if not(isFiring) then
		if (frontLeg == leftLeg) then
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED )
			Turn(rarm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED )
		else
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED )
			Turn(rarm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED )
		end
	end

	-- wait for leg rotations (ignore backheel of back leg - it's in the air)
	for i=1, #frontLeg do
		WaitForTurn(frontLeg[i], x_axis)
	end
	for i=1, #backLeg-1 do
		WaitForTurn(backLeg[i], x_axis)
	end
end

-- passing (front foot flat under body, back foot passing with bent knee)
local function Passing(frontLeg, backLeg)
	Turn(frontLeg[1], x_axis, THIGH_STRAIGHT_ANGLE, THIGH_STRAIGHT_SPEED)
	Turn(frontLeg[2], x_axis, SHIN_STRAIGHT_ANGLE, SHIN_STRAIGHT_SPEED)
	Turn(frontLeg[4], x_axis, TOEF_FRONT_ANGLE, TOEF_FRONT_SPEED)
	Turn(frontLeg[5], x_axis, TOEB_BACK_ANGLE, TOEB_BACK_SPEED)

	Turn(backLeg[1], x_axis, THIGH_MID_ANGLE, THIGH_MID_SPEED)
	Turn(backLeg[2], x_axis, SHIN_MID_ANGLE, SHIN_MID_SPEED)
	Turn(backLeg[4], x_axis, TOEF_BACK_ANGLE, TOEF_BACK_SPEED)
	Turn(backLeg[5], x_axis, TOEB_BACK_ANGLE, TOEB_BACK_SPEED)

	for i=1, #frontLeg-1 do
		WaitForTurn(frontLeg[i], x_axis)
	end
	for i=1, #backLeg-1 do
		WaitForTurn(backLeg[i], x_axis)
	end
end


local function Walk()
	SetSignalMask( SIG_Walk )

	-- tilt arms out a bit so they don't scrape body
	Turn(larm, z_axis, ARM_SIDE_ANGLE, ARM_BACK_SPEED )
	Turn(rarm, z_axis, -ARM_SIDE_ANGLE, ARM_FRONT_SPEED )

	while ( true ) do
		-- left leg
		Contact(leftLeg, rightLeg)
		Passing(leftLeg, rightLeg)

		-- right leg
		Contact(rightLeg, leftLeg)
		Passing(rightLeg, leftLeg)

	end
end

local function StopWalk()
	-- straighten legs
	for i=1,#leftLeg do
		Turn(leftLeg[i], x_axis, 0, 4)
		Move(leftLeg[i], y_axis, 0, 4)
	end
	for i=1,#rightLeg do
		Turn(rightLeg[i], x_axis, 0, 4)
		Move(rightLeg[i], y_axis, 0, 4)
	end

	-- and arms
	Turn(larm, z_axis, 0, ARM_BACK_SPEED)
	Turn(rarm, z_axis, 0, ARM_BACK_SPEED)
	
	Turn(body, z_axis, 0, 1)
	Turn(torso, y_axis, 0, 4)
	Move(pelvis, y_axis, 0, 4)
	Turn(pelvis, z_axis, 0, 1)
	Turn(larm, z_axis, 0, 1 )
	Turn(rarm, z_axis, 0, 1 )
	Turn(rarmgun, x_axis, 0, 1)
	Turn(larmgun, x_axis, 0, 1)
end

function script.StartMoving()
	StartThread( Walk )
end

function script.StopMoving()
	Signal( SIG_Walk )
	StartThread( StopWalk )
end


local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(6000)
	Turn( head, y_axis, 0, 3 )
	Turn( torso, y_axis, 0, 3 )
	Turn( larm, x_axis, 0, 3 )
	Turn( rarm, x_axis, 0, 3 )
	isFiring = false
end


local function missilelaunch()
		Hide ( lmissiles )
		Hide ( rmissiles )
		Sleep(30000)
		Show ( lmissiles )
		Show ( rmissiles )
end

local function armrecoil()
	if armgun then
		EmitSfx(larmflare, 1024)
		EmitSfx(larmflare, 1025)
		
		Move(larmgun, z_axis, -6)
		Turn(larm_lgunclaw, y_axis, -45)
		Turn(larm_rgunclaw, y_axis, 45)

		Move(larmgun, z_axis, 0, 3)
		Turn(larm_lgunclaw, y_axis, 0, 0.5)
		Turn(larm_rgunclaw, y_axis, 0, 0.5)
	else
		EmitSfx(rarmflare, 1024)
		EmitSfx(rarmflare, 1025)
		
		Move(rarmgun, z_axis, -6)
		Turn(rarm_lgunclaw, y_axis, -45)
		Turn(rarm_rgunclaw, y_axis, 45)

		Move(rarmgun, z_axis, 0, 3)
		Turn(rarm_lgunclaw, y_axis, 0, 0.5)
		Turn(rarm_rgunclaw, y_axis, 0, 0.5)
	end
end

function script.QueryWeapon(num)
	if num == 1 then
		return headflare
	elseif num == 2 then
		if armgun then return larmflare
		else return rarmflare end	
	elseif num == 3 then
		if missilegun == 1 then
			return lmissiles
		elseif missilegun == 2 then
			return rmissiles
		end
	end
end

function script.AimFromWeapon(num)
	if num == 1 or num == 3 then
		return headflare
	elseif num == 2 then
		return torso
	end
end

function script.AimWeapon(num, heading, pitch )
	if num == 1 then
		Signal( SIG_Aim )
		SetSignalMask( SIG_Aim )
		Turn( head, y_axis, heading, 3 )
		Turn( headflare, x_axis, -pitch, 3 )
		WaitForTurn( head, y_axis )
		WaitForTurn( headflare, x_axis )
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 then
		Signal( SIG_Aim2 )
		SetSignalMask( SIG_Aim2 )
		isFiring = true
		
		Turn( torso, y_axis, heading, 3 )
		Turn( larm, x_axis, -pitch, 3 )
		Turn( rarm, x_axis, -pitch, 3 )
		WaitForTurn( torso, y_axis )
		WaitForTurn( larm, x_axis )
		StartThread(RestoreAfterDelay)
		return true	
	elseif num == 3 then
		return true
	end
	return false
end


function script.Shot(num)
	if num == 2 then
		armgun = not armgun
		StartThread(armrecoil)
	elseif num == 3 then
		if missilegun < 2 then
			missilegun = missilegun+1
		else
			missilegun = 1
		end
		StartThread(missilelaunch)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(body, sfxNone)
		Explode(head, sfxNone)
		Explode(pelvis, sfxNone)
		dead = true
		
		Explode(lleg, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(rarmgun, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(larmgun, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(larm, sfxShatter)
		Explode(lmissiles, sfxShatter)
		Explode(rmissiles, sfxShatter)
		
		Turn(torso, y_axis, 0, 50)
		Turn(rarmgun, y_axis, 30, 20)	
		Turn(larmgun, y_axis, 30, 20)
		
		Sleep(800)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(body, sfxNone)
		Explode(head, sfxNone)
		Explode(pelvis, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(body, sfxShatter)
		Explode(head, sfxSmoke + sfxFire)
		Explode(pelvis, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
