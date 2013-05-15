--linear constant 65536

include "constants.lua"

local base, pelvis, torso = piece('base', 'pelvis', 'torso')
local rleg, rfoot, lleg, lfoot = piece('rleg', 'rfoot', 'lleg', 'lfoot')
local rdoor, rnozzle, rnano, ldoor, lnozzle, lnano = piece('rdoor', 'rnozzle', 'rnano', 'ldoor', 'lnozzle', 'lnano')

local nanoPieces = {[0] = lnano, [1] = rnano}

smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PERIOD = 500
local INTERMISSION = 100

local LEG_FRONT_DISPLACEMENT = 4
local LEG_BACK_DISPLACEMENT = -4
local LEG_Z_SPEED = 1000 * 8/PERIOD
local LEG_RAISE_DISPLACEMENT = 2
local LEG_Y_SPEED = 1000 * LEG_RAISE_DISPLACEMENT/PERIOD * 2

local SIG_WALK = 1
local SIG_RESTORE = 8

local nanoNum = 0
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

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	Move(lleg, y_axis, 0, LEG_Y_SPEED)
	Move(lfoot, z_axis, 0, LEG_Z_SPEED)
	Move(rleg, y_axis, 0, LEG_Y_SPEED)
	Move(rfoot, z_axis, 0, LEG_Z_SPEED)
end

function script.Create()
	StartThread(SmokeUnit)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn( torso, y_axis, 0, math.rad(65) )
	Turn(lnozzle, x_axis, 0, math.rad(180))
	Turn(rnozzle, x_axis, 0, math.rad(180))
	Turn(lnozzle, y_axis, math.rad(-1), math.rad(180))
	Turn(rnozzle, y_axis, math.rad(1), math.rad(180))	
	WaitForTurn(lnozzle, y_axis)
	Turn(ldoor, y_axis, 0, math.rad(180))	
	Turn(rdoor, y_axis, 0, math.rad(180))

end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreAfterDelay)
end

function script.StartBuilding(heading, pitch)
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

function script.QueryNanoPiece()
	nanoNum = 1 - nanoNum
	local nano = nanoPieces[nanoNum]
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nano)
	return nano
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity >= .25  then
		Explode(lfoot, sfxNone)
		Explode(lleg, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(rfoot, sfxNone)
		Explode(rleg, sfxNone)
		Explode(torso, sfxNone)
		return 1
	elseif severity >= .50  then
		Explode(lfoot, sfxFall)
		Explode(lleg, sfxFall)
		Explode(pelvis, sfxFall)
		Explode(rfoot, sfxFall)
		Explode(rleg, sfxFall)
		Explode(torso, sfxShatter)
		return 1
	elseif severity >= .99  then
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter)
		return 2
	else
		Explode(lfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(lleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(pelvis, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rfoot, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(rleg, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(torso, sfxShatter + sfxExplode )
		return 2
	end
end