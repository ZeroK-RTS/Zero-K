
--local ground = piece 'ground' removed object on xta model, pelvis on ca model was child of ground.
local torso = piece 'torso' 
local lfirept = piece 'lfirept' 
local rbigflash = piece 'rbigflash' 
local nanospray = piece 'nanospray' 
local nanolathe = piece 'nanolathe' 
local luparm = piece 'luparm' 
local ruparm = piece 'ruparm' 
local pelvis = piece 'pelvis' 
local rthigh = piece 'rthigh' 
local lthigh = piece 'lthigh' 
local biggun = piece 'biggun' 
local lleg = piece 'lleg' 
local l_foot = piece 'l_foot' 
local rleg = piece 'rleg' 
local r_foot = piece 'r_foot' 
local head = piece 'head' 
local orbit = piece 'orbit' --empty
local orbitfire = piece 'orbitfire' --empty 


include "constants.lua"

--Note: normal script/model setup has the comm lasering and nanoing out of the same hand, and dgunning with the other.
--This has been fixed here so that he attacks with one hand and nanos with the other
--but the piece choices will look a bit odd as a result.

local isMoving, isLasering, isDgunning, gunLockOut, shieldOn = false, false, false, false, true

-- Signal definitions
local SIG_LASER = 2
local SIG_DGUN = 4

local ACT_DGUN = 4
local ACT_LASER = 2

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local RESTORE_DELAY_LASER = 2000
local RESTORE_DELAY_DGUN = 1000

local function WalkArms()
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Move( rbigflash , x_axis, 0  )
		Move( lfirept , y_axis, 0  )
		Move( lfirept , z_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(17) )
		Turn( lthigh , x_axis, math.rad(-41) )
		Turn( torso , y_axis, math.rad(6) )
		Turn( luparm , x_axis, math.rad(30) )
		Turn( ruparm , x_axis, math.rad(-10) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(42) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( rleg , x_axis, math.rad(27) )
		Turn( r_foot , x_axis, math.rad(-28) )
		Sleep(120)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(7) )
		Turn( lthigh , x_axis, math.rad(-33) )
		Turn( torso , y_axis, math.rad(3) )
		Turn( luparm , x_axis, math.rad(25) )
		Turn( ruparm , x_axis, math.rad(-5) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(32) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( rleg , x_axis, math.rad(39) )
		Turn( r_foot , x_axis, math.rad(-27) )
		Sleep(110)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(-11) )
		Turn( lthigh , x_axis, math.rad(-26) )
		Turn( torso , y_axis, 0 )
		Turn( luparm , x_axis, math.rad(20) )
		Turn( ruparm , x_axis, 0 )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( l_foot , x_axis, math.rad(-10) )
		Turn( rleg , x_axis, math.rad(51) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(-19) )
		Turn( lthigh , x_axis, math.rad(1) )
		Turn( torso , y_axis, math.rad(-3) )
		Turn( luparm , x_axis, math.rad(10) )
		Turn( ruparm , x_axis, math.rad(10) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(6) )
		Turn( l_foot , x_axis, math.rad(-9) )
		Turn( rleg , x_axis, math.rad(52) )
		Turn( r_foot , x_axis, math.rad(-23) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(-42) )
		Turn( lthigh , x_axis, math.rad(8) )
		Turn( torso , y_axis, math.rad(-6) )
		Turn( luparm , x_axis, 0 )
		Turn( ruparm , x_axis, math.rad(20) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(10) )
		Turn( l_foot , x_axis, math.rad(-16) )
		Turn( rleg , x_axis, math.rad(51) )
		Turn( r_foot , x_axis, math.rad(-6) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(3) )
		Turn( rthigh , x_axis, math.rad(-49) )
		Turn( lthigh , x_axis, math.rad(11) )
		Turn( torso , y_axis, math.rad(-9) )
		Turn( luparm , x_axis, math.rad(-5) )
		Turn( ruparm , x_axis, math.rad(25) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( lleg , x_axis, math.rad(19) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( rleg , x_axis, math.rad(33) )
		Sleep(110)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(-44) )
		Turn( lthigh , x_axis, math.rad(19) )
		Turn( torso , y_axis, math.rad(-6) )
		Turn( luparm , x_axis, math.rad(-10) )
		Turn( ruparm , x_axis, math.rad(30) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(23) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( rleg , x_axis, math.rad(49) )
		Turn( r_foot , x_axis, math.rad(-8) )
		Sleep(120)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(-33) )
		Turn( lthigh , x_axis, math.rad(3) )
		Turn( torso , y_axis, math.rad(-3) )
		Turn( luparm , x_axis, math.rad(-5) )
		Turn( ruparm , x_axis, math.rad(25) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(44) )
		Turn( l_foot , x_axis, math.rad(-27) )
		Turn( rleg , x_axis, math.rad(41) )
		Turn( r_foot , x_axis, math.rad(-13) )
		Sleep(110)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(-26) )
		Turn( lthigh , x_axis, math.rad(-12) )
		Turn( torso , y_axis, 0 )
		Turn( luparm , x_axis, 0 )
		Turn( ruparm , x_axis, math.rad(20) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(62) )
		Turn( rleg , x_axis, math.rad(36) )
		Turn( r_foot , x_axis, math.rad(-15) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(6) )
		Turn( lthigh , x_axis, math.rad(-26) )
		Turn( torso , y_axis, math.rad(3) )
		Turn( luparm , x_axis, math.rad(10) )
		Turn( ruparm , x_axis, math.rad(10) )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(72) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( rleg , x_axis, math.rad(3) )
		Turn( r_foot , x_axis, math.rad(-12) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(16) )
		Turn( lthigh , x_axis, math.rad(-39) )
		Turn( torso , y_axis, math.rad(6) )
		Turn( luparm , x_axis, math.rad(21) )
		Turn( ruparm , x_axis, 0 )
		Turn( biggun , x_axis, math.rad(41) )
		Turn( nanolathe , x_axis, math.rad(36) )
		Turn( lleg , x_axis, math.rad(55) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( rleg , x_axis, math.rad(8) )
		Turn( r_foot , x_axis, math.rad(-19) )
		Sleep(100)
	end
	Move( pelvis , y_axis, 0  )
	Turn( pelvis , x_axis, math.rad(3) )
	Turn( rthigh , x_axis, math.rad(22) )
	Turn( lthigh , x_axis, math.rad(-48) )
	Turn( torso , y_axis, math.rad(9) )
	Turn( luparm , x_axis, math.rad(25) )
	Turn( ruparm , x_axis, math.rad(-5) )
	Turn( biggun , x_axis, math.rad(41) )
	Turn( lleg , x_axis, math.rad(40) )
	Turn( l_foot , x_axis, math.rad(-8) )
	Turn( rleg , x_axis, math.rad(11) )
	Turn( r_foot , x_axis, math.rad(-23) )
	Sleep(110)
end

local function WalkNoArms()
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Move( rbigflash , x_axis, 0  )
		Move( lfirept , y_axis, 0  )
		Move( lfirept , z_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(17) )
		Turn( lthigh , x_axis, math.rad(-41) )
		Turn( lleg , x_axis, math.rad(42) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( rleg , x_axis, math.rad(27) )
		Turn( r_foot , x_axis, math.rad(-28) )
		Sleep(120)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(7) )
		Turn( lthigh , x_axis, math.rad(-33) )
		Turn( lleg , x_axis, math.rad(32) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( rleg , x_axis, math.rad(39) )
		Turn( r_foot , x_axis, math.rad(-27) )
		Sleep(110)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(-11) )
		Turn( lthigh , x_axis, math.rad(-26) )
		Turn( l_foot , x_axis, math.rad(-10) )
		Turn( rleg , x_axis, math.rad(51) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(-19) )
		Turn( lthigh , x_axis, math.rad(1) )
		Turn( lleg , x_axis, math.rad(6) )
		Turn( l_foot , x_axis, math.rad(-9) )
		Turn( rleg , x_axis, math.rad(52) )
		Turn( r_foot , x_axis, math.rad(-23) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(-42) )
		Turn( lthigh , x_axis, math.rad(8) )
		Turn( lleg , x_axis, math.rad(10) )
		Turn( l_foot , x_axis, math.rad(-16) )
		Turn( rleg , x_axis, math.rad(51) )
		Turn( r_foot , x_axis, math.rad(-6) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(3) )
		Turn( rthigh , x_axis, math.rad(-49) )
		Turn( lthigh , x_axis, math.rad(11) )
		Turn( lleg , x_axis, math.rad(19) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( rleg , x_axis, math.rad(33) )
		Sleep(110)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(-44) )
		Turn( lthigh , x_axis, math.rad(19) )
		Turn( lleg , x_axis, math.rad(23) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( rleg , x_axis, math.rad(49) )
		Turn( r_foot , x_axis, math.rad(-8) )
		Sleep(120)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(-33) )
		Turn( lthigh , x_axis, math.rad(3) )
		Turn( lleg , x_axis, math.rad(44) )
		Turn( l_foot , x_axis, math.rad(-27) )
		Turn( rleg , x_axis, math.rad(41) )
		Turn( r_foot , x_axis, math.rad(-13) )
		Sleep(110)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( rthigh , x_axis, math.rad(-26) )
		Turn( lthigh , x_axis, math.rad(-12) )
		Turn( lleg , x_axis, math.rad(62) )
		Turn( rleg , x_axis, math.rad(36) )
		Turn( r_foot , x_axis, math.rad(-15) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(6) )
		Turn( lthigh , x_axis, math.rad(-26) )
		Turn( lleg , x_axis, math.rad(72) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( rleg , x_axis, math.rad(3) )
		Turn( r_foot , x_axis, math.rad(-12) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( rthigh , x_axis, math.rad(16) )
		Turn( lthigh , x_axis, math.rad(-39) )
		Turn( lleg , x_axis, math.rad(55) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( rleg , x_axis, math.rad(8) )
		Turn( r_foot , x_axis, math.rad(-19) )
		Sleep(100)
	end
	Move( pelvis , y_axis, 0  )
	Turn( pelvis , x_axis, math.rad(3) )
	Turn( rthigh , x_axis, math.rad(22) )
	Turn( lthigh , x_axis, math.rad(-48) )
	Turn( lleg , x_axis, math.rad(40) )
	Turn( l_foot , x_axis, math.rad(-8) )
	Turn( rleg , x_axis, math.rad(11) )
	Turn( r_foot , x_axis, math.rad(-23) )
	Sleep(110)
end

local function RestoreLegs()
	Move( pelvis , y_axis, 0 , 1 )
	Turn( rthigh , x_axis, 0, math.rad(200.043956) )
	Turn( rleg , x_axis, 0, math.rad(200.043956) )
	Turn( lthigh , x_axis, 0, math.rad(200.043956) )
	Turn( lleg , x_axis, 0, math.rad(200.043956) )
	Sleep(200)
end

local function BigFire()
--	gunLockOut = true
	Move( luparm , z_axis, 0  )
	Move( luparm , z_axis, -3 , 250 )
	Move( nanolathe , z_axis, 0  )
	Move( nanolathe , z_axis, -5 , 520 )
--	Move( rbigflash , x_axis, 0  )		--unnecessary lines?
--	Move( lfirept , y_axis, 0  )
--	Move( lfirept , z_axis, 0  )
	Turn( luparm , x_axis, 0 )
	Turn( luparm , x_axis, math.rad(-1), math.rad(113) )
	Sleep(10)

	Move( luparm , z_axis, -1 , 16 )
	Move( nanolathe , z_axis, -3 , 30 )
	Turn( luparm , x_axis, 0, math.rad(14) )
	Sleep(80)
	Move( luparm , z_axis, 0 , 14 )
	Move( nanolathe , z_axis, -2 , 15 )
	Turn( luparm , x_axis, 0, 0 )
	Sleep(70)

	Move( luparm , z_axis, 0 , 1 )
	Turn( luparm , x_axis, math.rad(1), math.rad(15) )
	Turn( luparm , z_axis, math.rad(-(0)), math.rad(8) )
	Sleep(50)
	Move( luparm , z_axis, 0 , 5 )
	Move( nanolathe , z_axis, 0 , 44 )
	Turn( luparm , x_axis, 0, math.rad(19) )
	Turn( luparm , z_axis, math.rad(-(0)), math.rad(9) )
	Sleep(50)
--	gunLockOut = false
end

local function MotionControl()
	while true do 
		if isMoving then 
			if isLasering or isDgunning then WalkNoArms()
			else WalkArms() end
		else 
			RestoreLegs()
			Sleep(100)
		end
	end
end

function script.Create()
	--Hide( ground) removed object on xta model, pelvis on ca model was child of ground.
	Hide( lfirept)
	Hide( rbigflash)
	Hide( nanospray)
	StartThread(MotionControl)
end

function script.StartMoving() 
	isMoving = true
end

function script.StopMoving() 
	isMoving = false
end

function script.AimFromWeapon4(num)
	return torso
end

function script.QueryWeapon(num)
	return lfirept
end

function script.FireWeapon(num) 
	if num == 5 then
		EmitSfx( lfirept,  1024 )
		EmitSfx( lfirept,  1025 )
	elseif num == 3 then
		EmitSfx( lfirept,  1026 )
		EmitSfx( lfirept,  1027 )
	end
end

local function RestoreLaser()
	Sleep(RESTORE_DELAY_LASER)
	isLasering = false
	Turn( luparm , x_axis, 0, ARM_SPEED_PITCH )
	if not isDgunning then Turn( torso , y_axis, 0, TORSO_SPEED_YAW) end
end

local function RestoreDgun()
	SetSignalMask( SIG_DGUN)
	Sleep(RESTORE_DELAY_DGUN)
	isDgunning = false
	Turn( luparm , x_axis, 0, ARM_SPEED_PITCH )
	Turn( nanolathe , x_axis, math.rad(36), ARM_SPEED_PITCH )
	if not isLasering then Turn( torso , y_axis, 0, TORSO_SPEED_YAW) end
end

function script.AimWeapon(num, heading, pitch)
	if num >=4 then
		Signal( SIG_LASER)
		SetSignalMask( SIG_LASER)
		isLasering = true
		if not isDgunning then 
			Turn( torso , y_axis, heading, TORSO_SPEED_YAW )
		end
		Turn( luparm , x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH )
		WaitForTurn(torso, y_axis)
		WaitForTurn(luparm, x_axis)
		StartThread(RestoreLaser)
		return true
	elseif num == 3 then
		Signal( SIG_DGUN)
		SetSignalMask( SIG_DGUN)
		isDgunning = true
		Turn( torso , y_axis, heading, TORSO_SPEED_YAW )
		Turn( nanolathe , x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH )
		WaitForTurn(torso, y_axis)
		WaitForTurn(nanolathe, x_axis)
		StartThread(RestoreDgun)
		return true
	elseif num == 2 then
		Sleep(100)
		return (shieldOn)
	end
	return false
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn( ruparm , x_axis, 0, ARM_SPEED_PITCH )
	if not (isLasering or isDgunning) then Turn(torso, y_axis, 0 ,TORSO_SPEED_YAW) end
end

function script.StartBuilding(heading, pitch) 
	Turn( ruparm , x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH )
	if not (isDgunning) then Turn(torso, y_axis, heading, TORSO_SPEED_YAW) end
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),rbigflash)
	return rbigflash
end

function script.Activate()
	shieldOn = true
end

function script.Deactivate()
	shieldOn = false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, sfxNone)
		Explode(luparm, sfxNone)
		Explode(ruparm, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(lthigh, sfxNone)
		Explode(rthigh, sfxNone)
		Explode(nanospray, sfxNone)
		Explode(biggun, sfxNone)
		Explode(lleg, sfxNone)
		Explode(rleg, sfxNone)
		return 1
	else
		Explode(torso, sfxShatter)
		Explode(luparm, sfxSmoke + sfxFire + sfxExplode)
		Explode(ruparm, sfxSmoke + sfxFire + sfxExplode)
		Explode(pelvis, sfxShatter)
		Explode(lthigh, sfxShatter)
		Explode(rthigh, sfxShatter)
		Explode(nanospray, sfxSmoke + sfxFire + sfxExplode)
		Explode(biggun, sfxSmoke + sfxFire + sfxExplode)
		Explode(lleg, sfxShatter)
		Explode(rleg, sfxShatter)
		Explode(head, sfxSmoke + sfxFire)
		return 2
	end
end