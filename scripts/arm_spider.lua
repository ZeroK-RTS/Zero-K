include "constants.lua"
include "spider_walking.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base'
local leg1 = piece 'leg1'	-- back right
local leg2 = piece 'leg2' 	-- middle right
local leg3 = piece 'leg3' 	-- front right
local leg4 = piece 'leg4' 	-- back left
local leg5 = piece 'leg5' 	-- middle left
local leg6 = piece 'leg6' 	-- front left
local platform, gun, elevator, elevator2, panel_r, panel_l, cover_r, cover_l, flare = piece('platform', 'gun', 'elevator', 'elevator2', 'panel_r', 'panel_l', 'cover_r', 'cover_l', 'flare')

smokePiece = {base, gun}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_BUILD = 3
local SIG_STOPBUILD = 4

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

	Turn(leg1, z_axis, 0, legRaiseSpeed)	-- LF leg up
	Turn(leg1, y_axis, 0, legForwardSpeed)	-- LF leg forward
	Turn(leg4, z_axis, 0, legRaiseSpeed)	-- RM leg up
	Turn(leg4, y_axis, 0, legMiddleSpeed)	-- RM leg forward
	Turn(leg5, z_axis, 0, legRaiseSpeed)	-- LB leg up
	Turn(leg5, y_axis, 0, legBackwardSpeed)	-- LB leg forward		
	
	Turn(leg2, z_axis, 0, legRaiseSpeed)	-- LF leg up
	Turn(leg2, y_axis, 0, legForwardSpeed)	-- LF leg forward
	Turn(leg3, z_axis, 0, legRaiseSpeed)	-- RM leg up
	Turn(leg3, y_axis, 0, legMiddleSpeed)	-- RM leg forward
	Turn(leg6, z_axis, 0, legRaiseSpeed)	-- LB leg up
	Turn(leg6, y_axis, 0, legBackwardSpeed)	-- LB leg forward			
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

function script.StartBuilding(heading, pitch) 
	if GetUnitValue(COB.INBUILDSTANCE) == 0 then
		Signal(SIG_STOPBUILD)
		SetUnitValue(COB.INBUILDSTANCE, 1)
		SetSignalMask(SIG_BUILD)
		
		Move(elevator,y_axis, 6, 20)
		Move(elevator2,y_axis, 6, 20)
		Move(gun,y_axis, 6, 20)
		Turn(cover_r,z_axis,-math.rad(120), math.rad(250))
		Turn(cover_l,z_axis,math.rad(120), math.rad(250))
		Turn(panel_r,y_axis,math.rad(80), math.rad(250))
		Turn(panel_l,y_axis,-math.rad(80), math.rad(250))
		WaitForMove(gun, y_axis)
		Turn(platform,y_axis,heading,math.rad(140))
	end
end

function script.StopBuilding()
	if GetUnitValue(COB.INBUILDSTANCE) == 1 then
		Signal(SIG_BUILD)
		SetUnitValue(COB.INBUILDSTANCE, 0)
		SetSignalMask(SIG_STOPBUILD)
		
		Turn(platform,y_axis,0,math.rad(140))
		Turn(panel_r,y_axis,0, math.rad(250))
		Turn(panel_l,y_axis,0, math.rad(250))
		WaitForTurn(platform,y_axis)
		Move(elevator,y_axis, 0, 20)
		Move(elevator2,y_axis, 0, 20)
		Move(gun,y_axis, 0, 20)
		WaitForMove(gun, y_axis)
		Turn(cover_r,z_axis,0, math.rad(250))
		Turn(cover_l,z_axis,0, math.rad(250))
	end
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),flare)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(panel_l, sfxNone)
		Explode(base, sfxNone)
		Explode(panel_r, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(leg3, sfxNone)
		Explode(leg4, sfxNone)
		Explode(leg5, sfxNone)
		Explode(leg6, sfxNone)
		Explode(gun, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(panel_l, sfxFall)
		Explode(base, sfxNone)
		Explode(panel_r, sfxFall)
		Explode(leg1, sfxFall)
		Explode(leg2, sfxFall)
		Explode(leg3, sfxFall)
		Explode(leg4, sfxFall)
		Explode(leg5, sfxFall)
		Explode(leg6, sfxFall)
		Explode(gun, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(panel_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
		Explode(panel_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gun, sfxShatter)
		return 2
	else
		Explode(panel_l, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
		Explode(panel_r, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gun, sfxShatter)
		return 2
	end
end
