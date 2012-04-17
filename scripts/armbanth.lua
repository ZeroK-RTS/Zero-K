include "constants.lua"

-- body
local pelvis = piece "pelvis"
local body = piece "body"
local head = piece "head"
local headflare = piece "headflare"
local torso = piece "torso"
local lmissile3 = piece "lmissile3"
local rmissile3 = piece "rmissile3"
local lmissileflare3 = piece "lmissileflare3"
local rmissileflare3 = piece "rmissileflare3"

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
local ltoer = piece "ltoer"

--right leg
local rupleg = piece "rupleg"
local rleg = piece "rleg"
local rfoot = piece "rfoot"
local rtoef = piece "rtoef"
local rtoer = piece "rtoer"

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
local missilegun = false
local PACE = 1.1

local THIGH_FRONT_ANGLE = -math.rad(40)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(20)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local SHIN_FRONT_ANGLE = math.rad(35)
local SHIN_FRONT_SPEED = math.rad(90) * PACE
local SHIN_BACK_ANGLE = math.rad(5)
local SHIN_BACK_SPEED = math.rad(90) * PACE

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(15)*PACE

local ARM_FRONT_ANGLE = -math.rad(15)
local ARM_FRONT_SPEED = math.rad(22.5) * PACE
local ARM_BACK_ANGLE = math.rad(5)
local ARM_BACK_SPEED = math.rad(22.5) * PACE

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

	StartThread(SmokeUnit)
end


local function Walk()
	SetSignalMask( SIG_Walk )
	while ( true ) do
		Turn(lupleg, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(rupleg, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		if not(isFiring) then
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, 0.2, 0.5 )
			Turn(rarm, x_axis, -0.2, 0.5 )
			end	
		WaitForTurn(lupleg, x_axis)
		Sleep(0)
		
		Turn(lupleg, x_axis,  THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(rupleg, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		if not(isFiring) then
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, -0.2, 0.5 )
			Turn(rarm, x_axis, 0.2, 0.5 )
		end
		WaitForTurn(rupleg, x_axis)		
		Sleep(0)	
	end
end

local function StopWalk()
	Turn(lupleg, x_axis, 0, 4)
	Turn( lfoot, x_axis, 0, 4 )
	Turn( ltoef, x_axis, 0, 4 )
	Turn( ltoer, x_axis, 0, 4 )	
	Turn( lleg, x_axis, 0, 4 )
	Turn(rupleg, x_axis, 0, 4)
	Turn( rfoot, x_axis, 0, 4 )
	Turn( rtoef, x_axis, 0, 4 )
	Turn( rtoer, x_axis, 0, 4 )	
	Turn( rleg, x_axis, 0, 4 )
	Turn( pelvis, z_axis, 0, 1)
	Turn( body, z_axis, 0, 1)
	Turn( torso, y_axis, 0, 4)
	Move( pelvis, y_axis, 0, 4)
	Turn(rarmgun, x_axis, 0, 1)
	Turn(larmgun, x_axis, 0, 1)
	end

function script.StartMoving()
	--SetSignalMask( walk )
	StartThread( Walk )
end

function script.StopMoving()
	Signal( SIG_Walk )
	--SetSignalMask( SIG_Walk )
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
	if missilegun then
		Hide ( lmissile3 )
		Sleep(4000)
		Show ( lmissile3 )
	else
		Hide ( rmissile3 )
		Sleep(4000)
		Show ( rmissile3 )
	end
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

local function SuperBeam()
	for i=1,CHARGE_TIME do
		SetUnitValue(COB.CEG_DAMAGE,i)
		EmitSfx(headflare, 1024 + 2)
		Sleep(33)
	end
	local px, py, pz = Spring.GetUnitPosition(unitID)
	Spring.PlaySoundFile("sounds/weapon/laser/heavy_laser4.wav", 10, px, py, pz)
	for i=1,FIRE_TIME do
		EmitSfx(headflare, 2048 + 4)
	    	Sleep(33)
	end
end

function script.QueryWeapon(num)
	if num == 1 or num == 3 or num == 5 then
		return headflare
	elseif num == 2 then
		if armgun then return larmflare
		else return rarmflare end	
	elseif num == 4 then
		if missilegun then return lmissileflare3
		else return rmissileflare3 end	
	end
end

function script.AimFromWeapon(num)
	if num == 1 or num == 3 or num == 5 then
		return headflare
	elseif num == 2 or num == 4 then
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
		Signal( SIG_Aim3 )
		SetSignalMask( SIG_Aim3 )
		Turn( head, y_axis, heading, 3 )
		Turn( headflare, x_axis, -pitch, 3 )
		WaitForTurn( head, y_axis )
		WaitForTurn( headflare, x_axis )
		StartThread(RestoreAfterDelay)
		return true	
	elseif num == 4 then
		return true
	end
	return false
end


function script.FireWeapon(num)
	if num == 1 then
	    local speedmult = 1/(Spring.GetUnitRulesParam(unitID,"slowState") or 1)
		Spring.SetUnitWeaponState(unitID, 2, "reloadFrame", Spring.GetGameFrame() + reloadTimeShort*speedmult)	
	elseif num == 2 then
		armgun = not armgun
		StartThread(armrecoil)
	elseif num == 3 then
	        local speedmult = 1/(Spring.GetUnitRulesParam(unitID,"slowState") or 1)
			Spring.SetUnitWeaponState(unitID, 0, "reloadFrame", Spring.GetGameFrame() + reloadTime*speedmult)
		--StartThread(SuperBeam)
	elseif num == 4 then
		missilegun = not missilegun
		StartThread(missilelaunch)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(body, sfxNone)
		Explode(head, sfxNone)
		Explode(pelvis, sfxNone)
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
