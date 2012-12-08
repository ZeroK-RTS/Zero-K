include "constants.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- pieces

local pelvis, torso, head, shouldercannon, shoulderflare = piece("pelvis", "torso", "head", "shouldercannon", "shoulderflare")
local aaturret, aagun, aaflare1, aaflare2, headlaser1, headlaser2, headlaser3 = piece("AAturret", "AAguns", "AAflare1", "AAflare2", "headlaser1", "headlaser2", "headlaser3" )
local larm, larmcannon, larmbarrel1, larmflare1, larmbarrel2, larmflare2, larmbarrel3, larmflare3 = piece("larm", "larmcannon", "larmbarrel1", "larmflare1",
    "larmbarrel2", "larmflare2", "larmbarrel3", "larmflare3")
local rarm, rarmcannon, rarmbarrel1, rarmflare1, rarmbarrel2, rarmflare2, rarmbarrel3, rarmflare3 = piece("rarm", "rarmcannon", "rarmbarrel1", "rarmflare1",
    "rarmbarrel2", "rarmflare2", "rarmbarrel3", "rarmflare3")
local lupleg, lmidleg, lleg, lfoot, lftoe, lbtoe = piece("lupleg", "lmidleg", "lleg", "lfoot", "lftoe", "lbtoe")
local rupleg, rmidleg, rleg, rfoot, rftoe, rbtoe = piece("rupleg", "rmidleg", "rleg", "rfoot", "rftoe", "rbtoe")

smokePiece = { torso, head, shouldercannon }

local gunFlares = {
    {larmflare1, larmflare2, larmflare3, rarmflare1, rarmflare2, rarmflare3},
    {aaflare1, aaflare2},
    {shoulderflare},
    {headlaser1, headlaser2, headlaser3}
}
local barrels = {larmbarrel1, larmbarrel2, larmbarrel3, rarmbarrel1, rarmbarrel2, rarmbarrel3}
local aimpoints = {torso, aaturret, shoulderflare, head}

local gunIndex = {1,1,1,1}

local lastTorsoHeading = 0
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--signals
local SIG_Restore = 1
local SIG_Walk = 2
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
	Turn( shoulderflare, x_axis, math.rad(-90))	
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
	Turn( lupleg, x_axis, 0, 4)
	Turn( lfoot, x_axis, 0, 4 )
	Turn( lftoe, x_axis, 0, 4 )
	Turn( lbtoe, x_axis, 0, 4 )	
	Turn( lleg, x_axis, 0, 4 )
	Turn( rupleg, x_axis, 0, 4)
	Turn( rfoot, x_axis, 0, 4 )
	Turn( rftoe, x_axis, 0, 4 )
	Turn( rbtoe, x_axis, 0, 4 )	
	Turn( rleg, x_axis, 0, 4 )
	Turn( pelvis, z_axis, 0, 1)
	if not(isFiring) then
		Turn( torso, y_axis, 0, 4)
	end
	Move( pelvis, y_axis, 0, 4)
	Turn( rarm, x_axis, 0, 1)
	Turn( larm, x_axis, 0, 1)
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
	Sleep(5000)
	Turn( head, y_axis, 0, 2 )
	Turn( torso, y_axis, 0, 1.5 )
	Turn( larm, x_axis, 0, 2 )
	Turn( rarm, x_axis, 0, 2 )
	Turn( shouldercannon, x_axis, 0, math.rad(90))
	isFiring = false
	lastTorsoHeading = 0
end

function script.AimFromWeapon(num)
    return aimpoints[num]
end

function script.QueryWeapon(num)
    return gunFlares[num][ gunIndex[num] ]
end

function script.AimWeapon(num, heading, pitch)
    local SIG_AIM = 2^(num+1)
    isFiring = true
    Signal(SIG_AIM)
    SetSignalMask(SIG_AIM)
	
    StartThread(RestoreAfterDelay)
	
    if num == 1 then
		Turn(torso, y_axis, heading, math.rad(180))
		Turn(larm, x_axis, -pitch, math.rad(120))
		Turn(rarm, x_axis, -pitch, math.rad(120))
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
    elseif num == 2 then
		Turn(aaturret, y_axis, heading - lastTorsoHeading, math.rad(360))
		Turn(aagun, x_axis, -pitch, math.rad(240))
		WaitForTurn(aaturret, y_axis)
		WaitForTurn(aagun, x_axis)
    elseif num == 3 then
		--Turn(torso, y_axis, heading, math.rad(180))
		--Turn(shouldercannon, x_axis, math.rad(90) - pitch, math.rad(270))
		--WaitForTurn(torso, y_axis)
		--WaitForTurn(shouldercannon, x_axis)
    elseif num == 4 then
		Turn(torso, y_axis, heading, math.rad(180))
		WaitForTurn(torso, y_axis)
    end
    
    if num ~= 2 then
		lastTorsoHeading = heading
    end
    
    return true
end

function script.Shot(num)
	if num == 1 then
		Move(barrels[gunIndex[1]], z_axis, -20)
		Move(barrels[gunIndex[1]], z_axis, 0, 20)
    end
    gunIndex[num] = gunIndex[num] + 1
    if gunIndex[num] > #gunFlares[num] then
		gunIndex[num] = 1
    end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .5) then
		Explode(torso, sfxNone)
		Explode(head, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rarmcannon, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(larmcannon, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(larm, sfxShatter)
		
		return 1 -- corpsetype
	else
		Explode(torso, sfxShatter)
		Explode(head, sfxSmoke + sfxFire)
		Explode(pelvis, sfxShatter)
		return 2 -- corpsetype
	end
end
