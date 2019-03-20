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

local smokePiece = {base, turret}

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
		
		GG.SpiderWalk.walk(leg1, leg2, leg3, leg4, leg5, leg6,
			legRaiseAngle, legRaiseSpeed, legLowerSpeed,
			legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
			legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
			legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
			sleepTime)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	GG.SpiderWalk.restoreLegs(leg1, leg2, leg3, leg4, leg5, leg6, legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)			
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitWeaponState(unitID, 1, "projectileSpeed", 10)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

local function RestoreAfterDelay()
	Sleep(restore_delay)
	Turn(turret, y_axis, 0, math.rad(45))
	Turn(box, x_axis, 0, math.rad(45))
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, math.rad(240))
	Turn(box, x_axis, -pitch, math.rad(90))
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
	gun_1 = gun_1 + 1
	if gun_1 > 3 then gun_1 = 1 end
	StartThread(HideMissile, gun_1)
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/570
		-- Assume that at least one rocket will hit.
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 135.1, 75 * distMult, false, false, true)
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(box, SFX.NONE)
		Explode(base, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(leg3, SFX.NONE)
		Explode(leg4, SFX.NONE)
		Explode(leg5, SFX.NONE)
		Explode(leg6, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(box, SFX.FALL)
		Explode(base, SFX.NONE)
		Explode(leg1, SFX.FALL)
		Explode(leg2, SFX.FALL)
		Explode(leg3, SFX.FALL)
		Explode(leg4, SFX.FALL)
		Explode(leg5, SFX.FALL)
		Explode(leg6, SFX.FALL)
		Explode(turret, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(box, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(base, SFX.NONE)
		Explode(leg1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(turret, SFX.SHATTER)
		return 2
	else
		Explode(box, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(base, SFX.NONE)
		Explode(leg1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(turret, SFX.SHATTER)
		return 2
	end
end