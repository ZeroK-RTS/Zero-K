local ground = piece 'ground' 
local chest = piece 'chest' 
local mlasflsh = piece 'mlasflsh' 
local bigflsh = piece 'bigflsh' 
local nanospray = piece 'nanospray' 
local l_nano = piece 'l_nano' 
local l_sho = piece 'l_sho' 
local r_sho = piece 'r_sho' 
local pelvis = piece 'pelvis' 
local r_upleg = piece 'r_upleg' 
local l_upleg = piece 'l_upleg' 
local r_dgun = piece 'r_dgun' 
local l_lowleg = piece 'l_lowleg' 
local l_foot = piece 'l_foot' 
local r_lowleg = piece 'r_lowleg' 
local r_foot = piece 'r_foot' 
local head = piece 'head' 

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
		Move( bigflsh , x_axis, 0  )
		Move( mlasflsh , y_axis, 0  )
		Move( mlasflsh , z_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(17) )
		Turn( l_upleg , x_axis, math.rad(-41) )
		Turn( chest , y_axis, math.rad(6) )
		Turn( l_sho , x_axis, math.rad(30) )
		Turn( r_sho , x_axis, math.rad(-10) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(42) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( r_lowleg , x_axis, math.rad(27) )
		Turn( r_foot , x_axis, math.rad(-28) )
		Sleep(120)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(7) )
		Turn( l_upleg , x_axis, math.rad(-33) )
		Turn( chest , y_axis, math.rad(3) )
		Turn( l_sho , x_axis, math.rad(25) )
		Turn( r_sho , x_axis, math.rad(-5) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(32) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( r_lowleg , x_axis, math.rad(39) )
		Turn( r_foot , x_axis, math.rad(-27) )
		Sleep(110)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(-11) )
		Turn( l_upleg , x_axis, math.rad(-26) )
		Turn( chest , y_axis, 0 )
		Turn( l_sho , x_axis, math.rad(20) )
		Turn( r_sho , x_axis, 0 )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_foot , x_axis, math.rad(-10) )
		Turn( r_lowleg , x_axis, math.rad(51) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(-19) )
		Turn( l_upleg , x_axis, math.rad(1) )
		Turn( chest , y_axis, math.rad(-3) )
		Turn( l_sho , x_axis, math.rad(10) )
		Turn( r_sho , x_axis, math.rad(10) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(6) )
		Turn( l_foot , x_axis, math.rad(-9) )
		Turn( r_lowleg , x_axis, math.rad(52) )
		Turn( r_foot , x_axis, math.rad(-23) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(-42) )
		Turn( l_upleg , x_axis, math.rad(8) )
		Turn( chest , y_axis, math.rad(-6) )
		Turn( l_sho , x_axis, 0 )
		Turn( r_sho , x_axis, math.rad(20) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(10) )
		Turn( l_foot , x_axis, math.rad(-16) )
		Turn( r_lowleg , x_axis, math.rad(51) )
		Turn( r_foot , x_axis, math.rad(-6) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(3) )
		Turn( r_upleg , x_axis, math.rad(-49) )
		Turn( l_upleg , x_axis, math.rad(11) )
		Turn( chest , y_axis, math.rad(-9) )
		Turn( l_sho , x_axis, math.rad(-5) )
		Turn( r_sho , x_axis, math.rad(25) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_lowleg , x_axis, math.rad(19) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( r_lowleg , x_axis, math.rad(33) )
		Sleep(110)
	end
	if not (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(-44) )
		Turn( l_upleg , x_axis, math.rad(19) )
		Turn( chest , y_axis, math.rad(-6) )
		Turn( l_sho , x_axis, math.rad(-10) )
		Turn( r_sho , x_axis, math.rad(30) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(23) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( r_lowleg , x_axis, math.rad(49) )
		Turn( r_foot , x_axis, math.rad(-8) )
		Sleep(120)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(-33) )
		Turn( l_upleg , x_axis, math.rad(3) )
		Turn( chest , y_axis, math.rad(-3) )
		Turn( l_sho , x_axis, math.rad(-5) )
		Turn( r_sho , x_axis, math.rad(25) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(44) )
		Turn( l_foot , x_axis, math.rad(-27) )
		Turn( r_lowleg , x_axis, math.rad(41) )
		Turn( r_foot , x_axis, math.rad(-13) )
		Sleep(110)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(-26) )
		Turn( l_upleg , x_axis, math.rad(-12) )
		Turn( chest , y_axis, 0 )
		Turn( l_sho , x_axis, 0 )
		Turn( r_sho , x_axis, math.rad(20) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(62) )
		Turn( r_lowleg , x_axis, math.rad(36) )
		Turn( r_foot , x_axis, math.rad(-15) )
		Sleep(100)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(6) )
		Turn( l_upleg , x_axis, math.rad(-26) )
		Turn( chest , y_axis, math.rad(3) )
		Turn( l_sho , x_axis, math.rad(10) )
		Turn( r_sho , x_axis, math.rad(10) )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(72) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( r_lowleg , x_axis, math.rad(3) )
		Turn( r_foot , x_axis, math.rad(-12) )
		Sleep(90)
	end
	if not (isLasering or isDgunning) and isMoving  then
	
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(16) )
		Turn( l_upleg , x_axis, math.rad(-39) )
		Turn( chest , y_axis, math.rad(6) )
		Turn( l_sho , x_axis, math.rad(21) )
		Turn( r_sho , x_axis, 0 )
		Turn( r_dgun , x_axis, math.rad(41) )
		Turn( l_nano , x_axis, math.rad(36) )
		Turn( l_lowleg , x_axis, math.rad(55) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( r_lowleg , x_axis, math.rad(8) )
		Turn( r_foot , x_axis, math.rad(-19) )
		Sleep(100)
	end
	Move( pelvis , y_axis, 0  )
	Turn( pelvis , x_axis, math.rad(3) )
	Turn( r_upleg , x_axis, math.rad(22) )
	Turn( l_upleg , x_axis, math.rad(-48) )
	Turn( chest , y_axis, math.rad(9) )
	Turn( l_sho , x_axis, math.rad(25) )
	Turn( r_sho , x_axis, math.rad(-5) )
	Turn( r_dgun , x_axis, math.rad(41) )
	Turn( l_lowleg , x_axis, math.rad(40) )
	Turn( l_foot , x_axis, math.rad(-8) )
	Turn( r_lowleg , x_axis, math.rad(11) )
	Turn( r_foot , x_axis, math.rad(-23) )
	Sleep(110)
end

local function WalkNoArms()
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, -1*2.5  )
		Move( bigflsh , x_axis, 0  )
		Move( mlasflsh , y_axis, 0  )
		Move( mlasflsh , z_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(17) )
		Turn( l_upleg , x_axis, math.rad(-41) )
		Turn( l_lowleg , x_axis, math.rad(42) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( r_lowleg , x_axis, math.rad(27) )
		Turn( r_foot , x_axis, math.rad(-28) )
		Sleep(120)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(7) )
		Turn( l_upleg , x_axis, math.rad(-33) )
		Turn( l_lowleg , x_axis, math.rad(32) )
		Turn( l_foot , x_axis, math.rad(-5) )
		Turn( r_lowleg , x_axis, math.rad(39) )
		Turn( r_foot , x_axis, math.rad(-27) )
		Sleep(110)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(-11) )
		Turn( l_upleg , x_axis, math.rad(-26) )
		Turn( l_foot , x_axis, math.rad(-10) )
		Turn( r_lowleg , x_axis, math.rad(51) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(-19) )
		Turn( l_upleg , x_axis, math.rad(1) )
		Turn( l_lowleg , x_axis, math.rad(6) )
		Turn( l_foot , x_axis, math.rad(-9) )
		Turn( r_lowleg , x_axis, math.rad(52) )
		Turn( r_foot , x_axis, math.rad(-23) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(-42) )
		Turn( l_upleg , x_axis, math.rad(8) )
		Turn( l_lowleg , x_axis, math.rad(10) )
		Turn( l_foot , x_axis, math.rad(-16) )
		Turn( r_lowleg , x_axis, math.rad(51) )
		Turn( r_foot , x_axis, math.rad(-6) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(3) )
		Turn( r_upleg , x_axis, math.rad(-49) )
		Turn( l_upleg , x_axis, math.rad(11) )
		Turn( l_lowleg , x_axis, math.rad(19) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( r_lowleg , x_axis, math.rad(33) )
		Sleep(110)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(-44) )
		Turn( l_upleg , x_axis, math.rad(19) )
		Turn( l_lowleg , x_axis, math.rad(23) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( r_lowleg , x_axis, math.rad(49) )
		Turn( r_foot , x_axis, math.rad(-8) )
		Sleep(120)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(-33) )
		Turn( l_upleg , x_axis, math.rad(3) )
		Turn( l_lowleg , x_axis, math.rad(44) )
		Turn( l_foot , x_axis, math.rad(-27) )
		Turn( r_lowleg , x_axis, math.rad(41) )
		Turn( r_foot , x_axis, math.rad(-13) )
		Sleep(110)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(5) )
		Turn( r_upleg , x_axis, math.rad(-26) )
		Turn( l_upleg , x_axis, math.rad(-12) )
		Turn( l_lowleg , x_axis, math.rad(62) )
		Turn( r_lowleg , x_axis, math.rad(36) )
		Turn( r_foot , x_axis, math.rad(-15) )
		Sleep(100)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(6) )
		Turn( l_upleg , x_axis, math.rad(-26) )
		Turn( l_lowleg , x_axis, math.rad(72) )
		Turn( l_foot , x_axis, math.rad(-26) )
		Turn( r_lowleg , x_axis, math.rad(3) )
		Turn( r_foot , x_axis, math.rad(-12) )
		Sleep(90)
	end
	if (isLasering or isDgunning) and isMoving  then
		Move( pelvis , y_axis, 0  )
		Turn( pelvis , x_axis, math.rad(4) )
		Turn( r_upleg , x_axis, math.rad(16) )
		Turn( l_upleg , x_axis, math.rad(-39) )
		Turn( l_lowleg , x_axis, math.rad(55) )
		Turn( l_foot , x_axis, math.rad(-23) )
		Turn( r_lowleg , x_axis, math.rad(8) )
		Turn( r_foot , x_axis, math.rad(-19) )
		Sleep(100)
	end
	Move( pelvis , y_axis, 0  )
	Turn( pelvis , x_axis, math.rad(3) )
	Turn( r_upleg , x_axis, math.rad(22) )
	Turn( l_upleg , x_axis, math.rad(-48) )
	Turn( l_lowleg , x_axis, math.rad(40) )
	Turn( l_foot , x_axis, math.rad(-8) )
	Turn( r_lowleg , x_axis, math.rad(11) )
	Turn( r_foot , x_axis, math.rad(-23) )
	Sleep(110)
end

local function RestoreLegs()
	Move( pelvis , y_axis, 0 , 1 )
	Turn( r_upleg , x_axis, 0, math.rad(200.043956) )
	Turn( r_lowleg , x_axis, 0, math.rad(200.043956) )
	Turn( l_upleg , x_axis, 0, math.rad(200.043956) )
	Turn( l_lowleg , x_axis, 0, math.rad(200.043956) )
	Sleep(200)
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
	Hide( mlasflsh)
	Hide( bigflsh)
	Hide( nanospray)
	StartThread(MotionControl)
end

function script.StartMoving() 
	isMoving = true
end

function script.StopMoving() 
	isMoving = false
end

function script.AimFromWeapon1(num)
	if num == 3 then
		return r_sho
	else
		return f_sho
	end
end

function script.QueryWeapon(num)
	if num == 3 then
		return bigflsh
	else
		return mlasflsh
	end
end

function script.FireWeapon(num) 
	if num == 5 then
		EmitSfx( mlasflsh,  1024 )
		EmitSfx( mlasflsh,  1025 )
	elseif num == 3 then
		EmitSfx( bigflsh,  1026 )
		EmitSfx( bigflsh,  1027 )
	end
end

local function RestoreLaser()
	Sleep(RESTORE_DELAY_LASER)
	isLasering = false
	Turn( l_sho , x_axis, 0, ARM_SPEED_PITCH )
	if not isDgunning then Turn( chest , y_axis, 0, TORSO_SPEED_YAW) end
end

local function RestoreDgun()
	SetSignalMask( SIG_DGUN)
	Sleep(RESTORE_DELAY_DGUN)
	isDgunning = false
	Turn( r_sho , x_axis, 0, ARM_SPEED_PITCH )
	Turn( r_nano , x_axis, math.rad(0), ARM_SPEED_PITCH )
	if not isLasering then Turn( chest , y_axis, 0, TORSO_SPEED_YAW) end
end

function script.AimWeapon(num, heading, pitch)
	if num >=4 then
		Signal( SIG_LASER)
		SetSignalMask( SIG_LASER)
		isLasering = true
		if not isDgunning then 
			Turn( chest , y_axis, heading, TORSO_SPEED_YAW )
		end
		Turn( l_sho , x_axis, math.rad(0) - pitch, ARM_SPEED_PITCH )
		WaitForTurn(chest, y_axis)
		WaitForTurn(l_sho, x_axis)
		StartThread(RestoreLaser)
		return true
	elseif num == 3 then
		Signal( SIG_DGUN)
		SetSignalMask( SIG_DGUN)
		isDgunning = true
		Turn( chest , y_axis, heading, TORSO_SPEED_YAW )
		Turn( r_sho , x_axis, math.rad(0) - pitch, ARM_SPEED_PITCH )
		WaitForTurn(chest, y_axis)
		WaitForTurn(r_sho, x_axis)
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
	Turn( r_sho , x_axis, 0, ARM_SPEED_PITCH )
	if not (isLasering or isDgunning) then Turn(chest, y_axis, 0 ,TORSO_SPEED_YAW) end
end

function script.StartBuilding(heading, pitch) 
	Turn( r_sho , x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH )
	if not (isDgunning) then Turn(chest, y_axis, heading, TORSO_SPEED_YAW) end
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),bigflsh)
	return bigflsh
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
		Explode(chest, sfxNone)
		Explode(l_sho, sfxNone)
		Explode(r_sho, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(l_upleg, sfxNone)
		Explode(r_upleg, sfxNone)
		Explode(nanospray, sfxNone)
		Explode(r_dgun, sfxNone)
		Explode(l_lowleg, sfxNone)
		Explode(r_lowleg, sfxNone)
		return 1
	else
		Explode(chest, sfxShatter)
		Explode(l_sho, sfxSmoke + sfxFire + sfxExplode)
		Explode(r_sho, sfxSmoke + sfxFire + sfxExplode)
		Explode(pelvis, sfxShatter)
		Explode(l_upleg, sfxShatter)
		Explode(r_upleg, sfxShatter)
		Explode(nanospray, sfxSmoke + sfxFire + sfxExplode)
		Explode(r_dgun, sfxSmoke + sfxFire + sfxExplode)
		Explode(l_lowleg, sfxShatter)
		Explode(r_lowleg, sfxShatter)
		Explode(head, sfxSmoke + sfxFire)
		return 2
	end
end