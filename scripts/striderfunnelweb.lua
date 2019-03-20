include "constants.lua"
include "spider_walking.lua"

local ALLY_ACCESS = {allied = true}

local notum = piece 'notum'
local gaster = piece 'gaster' 
local gunL, gunR, flareL, flareR, aimpoint = piece('gunl', 'gunr', 'flarel', 'flarer', 'aimpoint')
local shieldArm, shield, eye, eyeflare = piece('shield_arm', 'shield', 'eye', 'eyeflare')
local emitl, emitr = piece('emitl', 'emitr')

-- note reversed sides from piece names!
local br = piece 'thigh_bacl'	-- back right
local mr = piece 'thigh_midl' 	-- middle right
local fr = piece 'thigh_frol' 	-- front right
local bl = piece 'thigh_bacr' 	-- back left
local ml = piece 'thigh_midr' 	-- middle left
local fl = piece 'thigh_fror' 	-- front left

local smokePiece = {eye}
local nanoPieces = {eye}

local SIG_WALK = 1
local SIG_BUILD = 2

local PERIOD = 0.275

local sleepTime = PERIOD*1000

local legRaiseAngle = math.rad(20)
local legRaiseSpeed = legRaiseAngle/PERIOD
local legLowerSpeed = legRaiseAngle/PERIOD

local legForwardAngle = math.rad(12)
local legForwardTheta = math.rad(25)
local legForwardOffset = 0
local legForwardSpeed = legForwardAngle/PERIOD

local legMiddleAngle = math.rad(12)
local legMiddleTheta = 0
local legMiddleOffset = 0
local legMiddleSpeed = legMiddleAngle/PERIOD

local legBackwardAngle = math.rad(12)
local legBackwardTheta = -math.rad(25)
local legBackwardOffset = 0
local legBackwardSpeed = legBackwardAngle/PERIOD


function script.StartBuilding()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1);
end

function script.StopBuilding()
	Signal(SIG_BUILD)
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 0);
end


local function Walk()
	Signal (SIG_WALK)
	SetSignalMask (SIG_WALK)
	while true do
		GG.SpiderWalk.walk (br, mr, fr, bl, ml, fl,
			legRaiseAngle, legRaiseSpeed, legLowerSpeed,
			legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
			legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
			legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
			sleepTime)
	end
end

local function RestoreLegs()
	Signal (SIG_WALK)
	SetSignalMask (SIG_WALK)
	GG.SpiderWalk.restoreLegs (br, mr, fr, bl, ml, fl,
		legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)				
end

function script.Create()
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 1) -- shields shouldn't disappear when turned off
	Hide (gunL)
	Hide (gunR)
	Move (aimpoint, z_axis, 4)
	Move (aimpoint, y_axis, 2)
	Move (aimpoint, x_axis, 0)
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.Activate()
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 0, ALLY_ACCESS)
end

function script.Deactivate()
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 1, ALLY_ACCESS)
end

function script.StartMoving ()
	StartThread (Walk)
end

function script.StopMoving ()
	StartThread (RestoreLegs)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),gaster)
	return gaster
end

function script.QueryWeapon(num)
	return aimpoint
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		return 1
	elseif severity <= .50 then
		Explode (shield, SFX.FALL)
		Explode (shieldArm, SFX.FALL)
		Explode (eye, SFX.FALL)
		Explode (br, SFX.FALL)
		Explode (ml, SFX.FALL)
		Explode (fr, SFX.FALL)
		return 1
	elseif severity <= .75 then
		Explode (bl, SFX.FALL)
		Explode (mr, SFX.FALL)
		Explode (fl, SFX.FALL)
		Explode (shield, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (shieldArm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (eye, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (br, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (ml, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (fr, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (gaster, SFX.SHATTER)
		return 2
	else
		Explode (shield, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (shieldArm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (eye, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (bl, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (mr, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (fl, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (br, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (ml, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (fr, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode (gaster, SFX.SHATTER)
		Explode (notum, SFX.SHATTER)
		return 2
	end
end
