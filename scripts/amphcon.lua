--linear constant 65536

include "constants.lua"
include 'reliableStartMoving.lua'

-- unused piece: base
local pelvis, torso = piece('pelvis', 'torso')
local rleg, rfoot, lleg, lfoot = piece('rleg', 'rfoot', 'lleg', 'lfoot')
local rdoor, rnozzle, rnano, ldoor, lnozzle, lnano = piece('rdoor', 'rnozzle', 'rnano', 'ldoor', 'lnozzle', 'lnano')

local nanoPieces = {[0] = lnano, [1] = rnano}

local smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PERIOD = 280
local INTERMISSION = 50

local LEG_FRONT_DISPLACEMENT = 4
local LEG_BACK_DISPLACEMENT = -4
local LEG_Z_SPEED = 1000 * 8/PERIOD
local LEG_RAISE_DISPLACEMENT = 2
local LEG_Y_SPEED = 1000 * LEG_RAISE_DISPLACEMENT/PERIOD * 2

local SIG_WALK = 1
local SIG_CURL = 2
local SIG_RESTORE = 8

local moving = false
local building = false
local movingData = {}

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		-- left leg up and forward, right leg down and back
		Move(lleg, y_axis, LEG_RAISE_DISPLACEMENT, LEG_Y_SPEED)
		Move(lfoot, z_axis, LEG_FRONT_DISPLACEMENT, LEG_Z_SPEED)
		
		Move(rfoot, z_axis, LEG_BACK_DISPLACEMENT, LEG_Z_SPEED)
		Sleep(PERIOD)
		Move(lleg, y_axis, 0, LEG_Y_SPEED)
		Sleep(INTERMISSION)
		
		-- right leg up and forward, left leg down and back
		Move(rleg, y_axis, LEG_RAISE_DISPLACEMENT, LEG_Y_SPEED)
		Move(rfoot, z_axis, LEG_FRONT_DISPLACEMENT, LEG_Z_SPEED)
		
		Move(lfoot, z_axis, LEG_BACK_DISPLACEMENT, LEG_Z_SPEED)
		Sleep(PERIOD)
		Move(rleg, y_axis, 0, LEG_Y_SPEED)
		Sleep(INTERMISSION)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Move(lleg, y_axis, 0, LEG_Y_SPEED)
	Move(lfoot, z_axis, 0, LEG_Z_SPEED)
	Move(rleg, y_axis, 0, LEG_Y_SPEED)
	Move(rfoot, z_axis, 0, LEG_Z_SPEED)
end

local function Curl()
	if moving or building then
		return
	end
	local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID,"disarmed") == 1)
	if stunned_or_inbuild then
		return
	end
	Signal(SIG_CURL)
	SetSignalMask(SIG_CURL)
	
	--Hide(pelvis)
	Turn(pelvis, x_axis, math.rad(45), math.rad(45))
	Move(pelvis, y_axis, -5, 5)
	Turn(rleg, x_axis, math.rad(-45), math.rad(45))
	Turn(lleg, x_axis, math.rad(-45), math.rad(45))
	
	WaitForMove(pelvis, y_axis)
	Spring.SetUnitArmored(unitID, true)
end

local function UnCurl()
	Signal(SIG_CURL)
	SetSignalMask(SIG_CURL)
	Spring.SetUnitArmored(unitID, false)

	--Show(pelvis)
	Turn(pelvis, x_axis, 0, math.rad(45))
	Move(pelvis, y_axis, 0, 5)
	Turn(rleg, x_axis, 0, math.rad(45))
	Turn(lleg, x_axis, 0, math.rad(45))
end

function script.StartMoving()
	movingData.moving = true
	StartThread(Walk)
	moving = true
	StartThread(UnCurl)
end

function script.StopMoving()
	movingData.moving = false
	StartThread(Stopping)
	moving = false
	StartThread(Curl)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	StartThread(GG.StartStopMovingControl, unitID, script.StartMoving, script.StopMoving, nil, true, movingData)
	StartThread(Curl)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(500)
	Turn(torso, y_axis, 0, math.rad(65))
	Turn(lnozzle, x_axis, 0, math.rad(180))
	Turn(rnozzle, x_axis, 0, math.rad(180))
	Turn(lnozzle, y_axis, math.rad(-1), math.rad(180))
	Turn(rnozzle, y_axis, math.rad(1), math.rad(180))
	WaitForTurn(lnozzle, y_axis)
	Turn(ldoor, y_axis, 0, math.rad(180))
	Turn(rdoor, y_axis, 0, math.rad(180))
	building = false
	StartThread(Curl)
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreAfterDelay)
end

function script.StartBuilding(heading, pitch)
	building = true
	StartThread(UnCurl)
	
	Signal(SIG_RESTORE)
	Turn(torso, y_axis, heading, math.rad(180))
	Turn(ldoor, y_axis, math.rad(90), math.rad(180))
	Turn(rdoor, y_axis, math.rad(-90), math.rad(180))
	Turn(lnozzle, y_axis, math.rad(-180), math.rad(180))
	Turn(rnozzle, y_axis, math.rad(180), math.rad(180))
	
	WaitForMove(ldoor, x_axis)
	Turn(lnozzle, x_axis, - pitch, math.rad(180))
	Turn(rnozzle, x_axis, - pitch, math.rad(180))
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(lfoot, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(lfoot, SFX.FALL)
		Explode(lleg, SFX.FALL)
		Explode(pelvis, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rleg, SFX.FALL)
		Explode(torso, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rleg, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		return 2
	end
end
