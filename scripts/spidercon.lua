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


local smokePiece = {base, gun}
local nanoPiece = flare

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_BUILD = 3
local SIG_STOPBUILD = 4

local PERIOD = 0.22

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
	GG.SpiderWalk.restoreLegs(leg1, leg2, leg3, leg4, leg5, leg6,
		legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, {nanoPiece})
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

function script.StartBuilding(heading, pitch)
	if GetUnitValue(COB.INBUILDSTANCE) == 0 then
		Signal(SIG_STOPBUILD)
		SetUnitValue(COB.INBUILDSTANCE, 1)
		SetSignalMask(SIG_BUILD)
		
		Move(elevator,y_axis, 4.5, 15)
		Move(elevator2,y_axis, 4.5, 15)
		Move(gun,y_axis, 4.5, 15)
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
		Move(elevator,y_axis, 0, 15)
		Move(elevator2,y_axis, 0, 15)
		Move(gun,y_axis, 0, 15)
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
	if severity <= .25 then
		Explode(panel_l, SFX.NONE)
		Explode(base, SFX.NONE)
		Explode(panel_r, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(leg3, SFX.NONE)
		Explode(leg4, SFX.NONE)
		Explode(leg5, SFX.NONE)
		Explode(leg6, SFX.NONE)
		Explode(gun, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(panel_l, SFX.FALL)
		Explode(base, SFX.NONE)
		Explode(panel_r, SFX.FALL)
		Explode(leg1, SFX.FALL)
		Explode(leg2, SFX.FALL)
		Explode(leg3, SFX.FALL)
		Explode(leg4, SFX.FALL)
		Explode(leg5, SFX.FALL)
		Explode(leg6, SFX.FALL)
		Explode(gun, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(panel_l, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(base, SFX.NONE)
		Explode(panel_r, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(gun, SFX.SHATTER)
		return 2
	else
		Explode(panel_l, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(base, SFX.NONE)
		Explode(panel_r, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(gun, SFX.SHATTER)
		return 2
	end
end
