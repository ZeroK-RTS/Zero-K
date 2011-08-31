include "constants.lua"
include "spider_walking.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base'
local turret = piece 'turret' 
local box = piece 'box' 
local leg1 = piece 'leg1'	-- back right
local leg2 = piece 'leg2' 	-- middle right
local leg3 = piece 'leg3' 	-- front right
local leg4 = piece 'leg4' 	-- back left
local leg5 = piece 'leg5' 	-- middle left
local leg6 = piece 'leg6' 	-- front left

local flares = { piece('missile1', 'missile2', 'missile3') }

smokePiece = {base, turret}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_MISSILEANIM = {4, 8, 16}

local PERIOD = 0.2

local sleepTime = PERIOD*1000

local legRaiseAngle = math.rad(30)
local legRaiseSpeed = legRaiseAngle/PERIOD
local legLowerSpeed = legRaiseAngle/PERIOD

local legForwardAngle = math.rad(20)
local legForwardTheta = math.rad(45)
local legForwardOffset = 0
local legForwardSpeed = legForwardAngle/PERIOD

local legMiddleAngle = math.rad(20)
local legMiddleTheta = 0
local legMiddleOffset = 0
local legMiddleSpeed = legMiddleAngle/PERIOD

local legBackwardAngle = math.rad(20)
local legBackwardTheta = -math.rad(45)
local legBackwardOffset = 0
local legBackwardSpeed = legBackwardAngle/PERIOD

local restore_delay = 4000

--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------
local gun_1 = 1

-- four-stroke hexapedal walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		
		walk(leg1, leg2, leg3, leg4, leg5, leg6,
			legRaiseAngle, legRaiseSpeed, legLowerSpeed,
			legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
			legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
			legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
			sleepTime)
	end
end

local function RestoreLegs()
	SetSignalMask(SIG_WALK)
	restoreLegs(leg1, leg2, leg3, leg4, leg5, leg6,
		legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)			
end

function script.Create()
	StartThread(SmokeUnit)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	StartThread(RestoreLegs)
end

local function RestoreAfterDelay()
	Sleep(restore_delay)
	Turn( turret, y_axis, 0, math.rad(45) )
	Turn( box , x_axis, 0, math.rad(45) )
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(240) )
	Turn( box , x_axis, -pitch, math.rad(90) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(box, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return box
end

function script.QueryWeapon(num)
	return flares[gun_1]
end

local function HideMissile(num)
	Signal(SIG_MISSILEANIM[num])
	SetSignalMask(SIG_MISSILEANIM[num])
	Hide(flares[num])
	Sleep(3000)
	Show(flares[num])
end

function script.Shot(num)
	StartThread(HideMissile, gun_1)
	gun_1 = gun_1 + 1
	if gun_1 > 3 then gun_1 = 1 end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(box, sfxNone)
		Explode(base, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(leg3, sfxNone)
		Explode(leg4, sfxNone)
		Explode(leg5, sfxNone)
		Explode(leg6, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(box, sfxFall)
		Explode(base, sfxNone)
		Explode(leg1, sfxFall)
		Explode(leg2, sfxFall)
		Explode(leg3, sfxFall)
		Explode(leg4, sfxFall)
		Explode(leg5, sfxFall)
		Explode(leg6, sfxFall)
		Explode(turret, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(box, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(turret, sfxShatter)
		return 2
	else
		Explode(box, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(turret, sfxShatter)
		return 2
	end
end
-----------



function script.StartBuilding(heading, pitch) 
	if GetUnitValue(COB.INBUILDSTANCE) == 0 then
		SetUnitValue(COB.INBUILDSTANCE, 1)
	end
end

function script.StopBuilding()
	if GetUnitValue(COB.INBUILDSTANCE) == 1 then
		SetUnitValue(COB.INBUILDSTANCE, 0)
	end
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),turret)
	return turret
end
