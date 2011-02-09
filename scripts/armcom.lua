include "constants.lua"

local torso = piece 'torso' 
local ruparm = piece 'ruparm' 
local luparm = piece 'luparm' 
local rbigflash = piece 'rbigflash' 
local nanospray = piece 'nanospray' 
local pelvis = piece 'pelvis' 
local lfirept = piece 'lfirept' 
local head = piece 'head' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh' 
local nanolath = piece 'nanolath' 
local biggun = piece 'biggun' 
local rleg = piece 'rleg' 
local lleg = piece 'lleg' 
local ground = piece 'ground' 

local isMoving, isLasering, isDgunning = false, false, false

-- Signal definitions
local SIG_LASER = 2
local SIG_DGUN = 4

local ACT_DGUN = 4
local ACT_LASER = 2

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local RESTORE_DELAY_LASER = 2000
local RESTORE_DELAY_DGUN = 2000

local function lua_QueryNanoPiece() 
  return 0
end

local function WalkArms()
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.700000  )
		Move( head , y_axis, -0.000006  )
		Turn( pelvis , x_axis, math.rad(6.681319) )
		Turn( lthigh , x_axis, math.rad(-41.846154) )
		Turn( rthigh , x_axis, math.rad(17.582418) )
		Turn( torso , y_axis, math.rad(4.219780), math.rad(180) )
		Turn( ruparm , x_axis, math.rad(-11.252747) )
		Turn( luparm , x_axis, math.rad(11.252747) )	
		Turn( rleg , x_axis, math.rad(39.384615) )
		Turn( lleg , x_axis, math.rad(41.846154) )
		WaitForTurn(torso, y_axis)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Turn( torso , y_axis, math.rad(3.868132) )
		Turn( ruparm , x_axis, math.rad(-13.362637) )
		Turn( luparm , x_axis, math.rad(12.307692) )
		Sleep(40)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.550000  )
		Turn( pelvis , x_axis, math.rad(5.274725) )
		Turn( lthigh , x_axis, math.rad(-29.538462) )
		Turn( rthigh , x_axis, math.rad(8.791209) )
		Turn( torso , y_axis, math.rad(3.164835) )
		Turn( ruparm , x_axis, math.rad(-8.087912) )
		Turn( luparm , x_axis, math.rad(6.329670) )
		Turn( rleg , x_axis, math.rad(51.686813) )
		Turn( lleg , x_axis, math.rad(28.483516) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(-16.175824) )
		Turn( rthigh , x_axis, 0 )
		Turn( torso , y_axis, math.rad(1.406593) )
		Turn( ruparm , x_axis, math.rad(-3.159341) )
		Turn( luparm , x_axis, 0 )
		Turn( rleg , x_axis, math.rad(58.016484) )
		Turn( lleg , x_axis, math.rad(16.175824) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0.000000  )
		Turn( pelvis , x_axis, math.rad(3.516484) )
		Turn( lthigh , x_axis, math.rad(7.032967) )
		Turn( rthigh , x_axis, math.rad(-6.329670) )
		Turn( torso , y_axis, 0 )
		Turn( ruparm , x_axis, math.rad(3.164835) )
		Turn( luparm , x_axis, math.rad(-6.329670) )
		Turn( rleg , x_axis, math.rad(44.307692) )
		Turn( lleg , x_axis, math.rad(5.626374) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.200000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(10.901099) )
		Turn( rthigh , x_axis, math.rad(-34.461538) )
		Turn( torso , y_axis, math.rad(-1.406593) )
		Turn( ruparm , x_axis, math.rad(6.681319) )
		Turn( luparm , x_axis, math.rad(-8.087912) )
		Turn( rleg , x_axis, math.rad(71.384615) )
		Turn( lleg , x_axis, math.rad(20.043956) )
		Sleep(80)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( lthigh , x_axis, math.rad(13.010989) )
		Turn( rthigh , x_axis, math.rad(-42.901099) )
		Turn( torso , y_axis, math.rad(-2.461538) )
		Turn( ruparm , x_axis, math.rad(8.439560) )
		Turn( luparm , x_axis, math.rad(-9.142857) )
		Turn( rleg , x_axis, math.rad(54.505495) )
		Sleep(70)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.400000  )
		Turn( pelvis , x_axis, math.rad(5.274725) )
		Turn( lthigh , x_axis, math.rad(16.879121) )
		Turn( rthigh , x_axis, math.rad(-48.175824) )
		Turn( torso , y_axis, math.rad(-3.164835) )
		Turn( ruparm , x_axis, math.rad(10.197802) )
		Turn( luparm , x_axis, math.rad(-10.197802) )
		Turn( rleg , x_axis, math.rad(34.461538) )
		Turn( lleg , x_axis, math.rad(20.043956) )
		Sleep(80)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.700000  )
		Turn( pelvis , x_axis, math.rad(6.681319) )
		Turn( lthigh , x_axis, math.rad(15.472527) )
		Turn( rthigh , x_axis, math.rad(-40.439560) )
		Turn( torso , y_axis, math.rad(-4.219780) )
		Turn( ruparm , x_axis, math.rad(11.252747) )
		Turn( luparm , x_axis, math.rad(-11.252747) )
		Turn( rleg , x_axis, math.rad(40.439560) )
		Turn( lleg , x_axis, math.rad(30.587912) )
		Sleep(40)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Turn( ruparm , x_axis, math.rad(13.362637) )
		Turn( luparm , x_axis, math.rad(-12.307692) )
		Sleep(40)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.550000  )
		Turn( pelvis , x_axis, math.rad(5.274725) )
		Turn( lthigh , x_axis, math.rad(9.489011) )
		Turn( rthigh , x_axis, math.rad(-34.461538) )
		Turn( torso , y_axis, math.rad(-3.164835) )
		Turn( ruparm , x_axis, math.rad(8.439560) )
		Turn( luparm , x_axis, math.rad(-8.439560) )
		Turn( lleg , x_axis, math.rad(43.950549) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(0.703297) )
		Turn( rthigh , x_axis, math.rad(-26.373626) )
		Turn( torso , y_axis, math.rad(-1.758242) )
		Turn( ruparm , x_axis, math.rad(3.159341) )
		Turn( luparm , x_axis, math.rad(-3.164835) )
		Turn( lleg , x_axis, math.rad(54.500000) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0.000000  )
		Turn( pelvis , x_axis, math.rad(3.516484) )
		Turn( lthigh , x_axis, math.rad(-16.879121) )
		Turn( rthigh , x_axis, math.rad(3.862637) )
		Turn( torso , y_axis, 0 )
		Turn( ruparm , x_axis, math.rad(-3.164835) )
		Turn( luparm , x_axis, math.rad(3.868132) )
		Turn( rleg , x_axis, math.rad(8.082418) )
		Turn( lleg , x_axis, math.rad(60.483516) )
		Sleep(80)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.200000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(-29.538462) )
		Turn( rthigh , x_axis, math.rad(10.192308) )
		Turn( torso , y_axis, math.rad(1.758242) )
		Turn( ruparm , x_axis, math.rad(-6.675824) )
		Turn( luparm , x_axis, math.rad(8.791209) )
		Turn( rleg , x_axis, math.rad(26.021978) )
		Turn( lleg , x_axis, math.rad(56.263736) )
		Sleep(80)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( lthigh , x_axis, math.rad(-43.950549) )
		Turn( rthigh , x_axis, math.rad(12.302198) )
		Turn( torso , y_axis, math.rad(2.461538) )
		Turn( ruparm , x_axis, math.rad(-7.032967) )
		Turn( luparm , x_axis, math.rad(9.846154) )
		Turn( lleg , x_axis, math.rad(55.912088) )
		Sleep(70)
	end
	Move( pelvis , y_axis, -0.400000  )
	Turn( pelvis , x_axis, math.rad(5.274725) )
	Turn( lthigh , x_axis, math.rad(-43.950549) )
	Turn( rthigh , x_axis, math.rad(14.412088) )
	Turn( torso , y_axis, math.rad(3.164835) )
	Turn( ruparm , x_axis, math.rad(-8.785714) )
	Turn( luparm , x_axis, math.rad(10.197802) )
	Turn( lleg , x_axis, math.rad(25.670330) )
	Sleep(80)
end

local function WalkNoArms()
	if (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, -0.700000  )
		Move( head , y_axis, -0.000006  )
		Turn( pelvis , x_axis, math.rad(6.681319) )
		Turn( lthigh , x_axis, math.rad(-41.846154) )
		Turn( rthigh , x_axis, math.rad(17.582418) )
		Turn( rleg , x_axis, math.rad(39.384615) )
		Turn( lleg , x_axis, math.rad(41.846154) )
		Sleep(40)
	end
	if (isLasering or isDgunning) and isMoving  then
		Sleep(40)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.550000  )
		Turn( pelvis , x_axis, math.rad(5.274725) )
		Turn( lthigh , x_axis, math.rad(-29.538462) )
		Turn( rthigh , x_axis, math.rad(8.791209) )
		Turn( rleg , x_axis, math.rad(51.686813) )
		Turn( lleg , x_axis, math.rad(28.483516) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(-16.175824) )
		Turn( rthigh , x_axis, 0 )
		Turn( rleg , x_axis, math.rad(58.016484) )
		Turn( lleg , x_axis, math.rad(16.175824) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0.000000  )
		Turn( pelvis , x_axis, math.rad(3.516484) )
		Turn( lthigh , x_axis, math.rad(7.032967) )
		Turn( rthigh , x_axis, math.rad(-6.329670) )
		Turn( rleg , x_axis, math.rad(44.307692) )
		Turn( lleg , x_axis, math.rad(5.626374) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.200000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(10.901099) )
		Turn( rthigh , x_axis, math.rad(-34.461538) )
		Turn( rleg , x_axis, math.rad(71.384615) )
		Turn( lleg , x_axis, math.rad(20.043956) )
		Sleep(80)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( lthigh , x_axis, math.rad(13.010989) )
		Turn( rthigh , x_axis, math.rad(-42.901099) )
		Turn( rleg , x_axis, math.rad(54.505495) )
		Sleep(70)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.400000  )
		Turn( pelvis , x_axis, math.rad(5.274725) )
		Turn( lthigh , x_axis, math.rad(16.879121) )
		Turn( rthigh , x_axis, math.rad(-48.175824) )
		Turn( rleg , x_axis, math.rad(34.461538) )
		Turn( lleg , x_axis, math.rad(20.043956) )
		Sleep(80)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.700000  )
		Turn( pelvis , x_axis, math.rad(6.681319) )
		Turn( lthigh , x_axis, math.rad(15.472527) )
		Turn( rthigh , x_axis, math.rad(-40.439560) )
		Turn( rleg , x_axis, math.rad(40.439560) )
		Turn( lleg , x_axis, math.rad(30.587912) )
		Sleep(40)
	end
	if (isLasering or isDgunning) and isMoving  then
		Sleep(40)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.550000  )
		Turn( pelvis , x_axis, math.rad(5.274725) )
		Turn( lthigh , x_axis, math.rad(9.489011) )
		Turn( rthigh , x_axis, math.rad(-34.461538) )
		Turn( lleg , x_axis, math.rad(43.950549) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(0.703297) )
		Turn( rthigh , x_axis, math.rad(-26.373626) )
		Turn( lleg , x_axis, math.rad(54.500000) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0.000000  )
		Turn( pelvis , x_axis, math.rad(3.516484) )
		Turn( lthigh , x_axis, math.rad(-16.879121) )
		Turn( rthigh , x_axis, math.rad(3.862637) )
		Turn( rleg , x_axis, math.rad(8.082418) )
		Turn( lleg , x_axis, math.rad(60.483516) )
		Sleep(80)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.200000  )
		Turn( pelvis , x_axis, math.rad(4.571429) )
		Turn( lthigh , x_axis, math.rad(-29.538462) )
		Turn( rthigh , x_axis, math.rad(10.192308) )
		Turn( rleg , x_axis, math.rad(26.021978) )
		Turn( lleg , x_axis, math.rad(56.263736) )
		Sleep(80)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -0.300000  )
		Turn( lthigh , x_axis, math.rad(-43.950549) )
		Turn( rthigh , x_axis, math.rad(12.302198) )
		Turn( lleg , x_axis, math.rad(55.912088) )
		Sleep(70)
	end
	Move( pelvis , y_axis, -0.400000  )
	Turn( pelvis , x_axis, math.rad(5.274725) )
	Turn( lthigh , x_axis, math.rad(-43.950549) )
	Turn( rthigh , x_axis, math.rad(14.412088) )
	Turn( lleg , x_axis, math.rad(25.670330) )
	Sleep(80)
end

local function RestoreLegs() 
	Move( pelvis , y_axis, 0.000000 , 1.000000 )
	Turn( rthigh , x_axis, 0, math.rad(200.043956) )
	Turn( rleg , x_axis, 0, math.rad(200.043956) )
	Turn( lthigh , x_axis, 0, math.rad(200.043956) )
	Turn( lleg , x_axis, 0, math.rad(200.043956) )
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
	Hide( ground)
	Hide( rbigflash)
	Hide( lfirept)
	Hide( nanospray)
	StartThread(MotionControl)
end

function script.StartMoving() 
	Turn( nanolath , x_axis, math.rad(-40), ARM_SPEED_PITCH )
	Turn( biggun , x_axis, math.rad(-62.5), ARM_SPEED_PITCH )
	isMoving = true
end

function script.StopMoving() 
	isMoving = false
end

function script.AimFromWeapon(num)
	return torso
end

function script.QueryWeapon(num)
	if num == 3 then return rbigflash end
	return lfirept
end

local function RestoreLaser()
	Sleep(RESTORE_DELAY_LASER)
	isLasering = false
	Turn( luparm , x_axis, 0, ARM_SPEED_PITCH )
	if (not isDgunning) then Turn(torso, y_axis, 0, TORSO_SPEED_YAW) end
end

local function RestoreDgun()
	SetSignalMask(SIG_DGUN)
	Sleep(RESTORE_DELAY_DGUN)
	isDgunning = false
	Turn( ruparm , x_axis, 0, ARM_SPEED_PITCH )
	if (not isLasering) then Turn(torso, y_axis, 0, TORSO_SPEED_YAW) end
end

function script.AimWeapon(num, heading, pitch)
	if num >= 4 then
		Signal( SIG_LASER)
		SetSignalMask( SIG_LASER)
		isLasering = true
		if not isDgunning then 
			Turn( torso , y_axis, heading, TORSO_SPEED_YAW )
		end
		Turn( luparm , x_axis, math.rad(-50) - pitch, ARM_SPEED_PITCH )
		WaitForTurn(luparm, x_axis)
		StartThread(RestoreLaser)
		return true
	elseif num == 3 then
		Signal( SIG_DGUN)
		SetSignalMask( SIG_DGUN)
		isDgunning = true
		Turn( torso , y_axis, heading, TORSO_SPEED_YAW )
		Turn( ruparm , x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH )
		WaitForTurn(torso, y_axis)
		WaitForTurn(ruparm, x_axis)
		StartThread(RestoreDgun)
		return true
	end
	return false
end

function script.FireWeapon(num)
	if num == 5 then
		EmitSfx(lfirept, 1024)
	end
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	if not (isLasering) then Turn(luparm, x_axis, 0, ARM_SPEED_PITCH) end
	if not (isLasering or isDgunning) then Turn(torso, y_axis, 0 ,TORSO_SPEED_YAW) end
end

function script.StartBuilding(heading, pitch) 
	if not isLasering then 
		Turn( luparm , x_axis, math.rad(-60) - pitch, ARM_SPEED_PITCH )
		if not (isDgunning) then Turn(torso, y_axis, heading, TORSO_SPEED_YAW) end
	end
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanospray)
	return nanospray
end
