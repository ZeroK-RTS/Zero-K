include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base' 
local hips = piece 'hips'
local torsoPivot = piece 'torsopivot'
local torsoTrue = piece 'torso'
local camera = piece 'camera' 
local shoulderl = piece 'shoulderl' 
local shoulderr = piece 'shoulderr' 
local arml = piece 'arml' 
local armr = piece 'armr' 
local forearml = piece 'forearml' 
local forearmr = piece 'forearmr' 
local handl = piece 'handl' 
local handr = piece 'handr' 
local receiver = piece 'receiver' 
local barrel = piece 'barrel' 
local flare = piece 'flare' 
local gunemit = piece 'gunemit' 
local scope = piece 'scope' 
local stock = piece 'stock' 
local thighl = piece 'thighl' 
local thighr = piece 'thighr' 
local shinl = piece 'shinl' 
local shinr = piece 'shinr' 
local anklel = piece 'anklel' 
local ankler = piece 'ankler' 
local footl = piece 'footl' 
local footr = piece 'footr' 
local backpack = piece 'backpack' 

local smokePiece = {torsoTrue, backpack}
--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_AIM = 2
local SIG_PACK = 4
local SIG_WALK = 8
local SIG_IDLE = 1
local SIG_RESTORE = 16

local PACE = 1.9

local THIGH_FRONT_ANGLE = -math.rad(50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local SHIN_FRONT_ANGLE = math.rad(45)
local SHIN_FRONT_SPEED = math.rad(90) * PACE
local SHIN_BACK_ANGLE = math.rad(10)
local SHIN_BACK_SPEED = math.rad(90) * PACE

local ARM_FRONT_ANGLE = -math.rad(20)
local ARM_FRONT_SPEED = math.rad(22.5) * PACE
local ARM_BACK_ANGLE = math.rad(10)
local ARM_BACK_SPEED = math.rad(22.5) * PACE

local GUN_STOWED_ANGLE = math.rad(-45)
local GUN_STOWED_SPEED = math.rad(45)
local GUN_READY_SPEED = math.rad(45)
--[[
local GUN_FRONT_ANGLE = -math.rad(15)
local GUN_FRONT_SPEED = math.rad(40) * PACE
local GUN_BACK_ANGLE = -math.rad(10)
local GUN_BACK_SPEED = math.rad(40) * PACE
]]--

local TORSO_ANGLE_MOTION = math.rad(10)
local TORSO_SPEED_MOTION = math.rad(15)*PACE

local VERT_AIM_SPEED = math.rad(210)
local AIM_SPEED = math.rad(360) -- noscope
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local bAiming, bCanAim, gun_unpacked, idleArmState = false, true, false, false
local maintainHeading = false
local torsoHeading = 0

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--left leg up, right leg back
		Turn(thighl, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(shinl, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(thighr, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(shinr, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		if not(bAiming) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end

		Move(hips, y_axis, 0, 10.0)
		WaitForMove(hips, y_axis)

		Move(hips, y_axis, 0.5, 10.0)

		WaitForTurn(thighl, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(thighl, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(shinl, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(thighr, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(shinr, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)

		Move(hips, y_axis, 0, 10.0)
		WaitForMove(hips, y_axis)

		Move(hips, y_axis, 0.5, 10.0)

		WaitForTurn(thighr, x_axis)		
		Sleep(0)
	end	
end

local function IdleAnim()
	Signal(SIG_IDLE)
	SetSignalMask(SIG_IDLE)
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do
		Sleep(1000)
	end
	Sleep(3000)
	while true do
		if not(bAiming) then
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(-30), math.rad(80))
		Sleep(3500)
		if not(bAiming) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(30), math.rad(80))
		Turn(forearmr, x_axis, math.rad(-30), math.rad(60))
		idleArmState = true
		Sleep(3500)
		if not(bAiming) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(-30), math.rad(80))
		Sleep(3500)
		if not(bAiming) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(30), math.rad(80))	
		Turn(forearmr, x_axis, 0, math.rad(60))
		idleArmState = false
		Sleep(3500)
	end
end
	
local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Move(hips, y_axis, 0, 10.0)
	Turn(thighl, x_axis, 0, math.rad(60*PACE))
	Turn(shinl, x_axis, 0, math.rad(60*PACE))
	Turn(thighr, x_axis, 0, math.rad(60*PACE))
	Turn(shinr, x_axis, 0, math.rad(60*PACE))	
	if not(bAiming) then
		Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
	end
	StartThread(IdleAnim)	
end

function script.StartMoving()
	StartThread(Walk)
	Signal(SIG_IDLE)
end

function script.StopMoving()
	StartThread(Stopping)
end


function script.ChangeHeading(delta)
	if delta == 0 then
		return
	end
	if maintainHeading then
		torsoHeading = torsoHeading + delta * headingToRad
		Turn(torsoTrue, y_axis, -torsoHeading, AIM_SPEED)
	end
end

----------------------------------------------------
--start ups :)
--------------------------------------------------------

local function UnpackGunInstant()
	Turn(shoulderr, x_axis, math.rad(-90))
	Turn(shoulderl, x_axis, math.rad(-90))
	--Turn(forearml, x_axis, math.rad(-90))
	Turn(forearml, z_axis, math.rad(-80))
	Turn(handl, y_axis, math.rad(-90))
	Move(barrel, y_axis, -4.2)
	Move(stock, y_axis, 9)
	gun_unpacked = true
end

function script.Create()
	--Turn(forearmr, x_axis, math.rad(-45), math.rad(280))
	StartThread(SmokeUnit, smokePiece)
	UnpackGunInstant()
	StartThread(IdleAnim)
	--StartThread(TorsoHeadingThread)
	end
	
function script.AimFromWeapon(num)
	return shoulderr
end

function script.QueryWeapon(num)
	return gunemit
end
-----------------------------------------------------------------------
--gun functions
-----------------------------------------------------------------------	

local function PackGun()
	Signal(SIG_IDLE)
	Signal(SIG_PACK)
	SetSignalMask(SIG_PACK)
	
	bCanAim = false
	Move(barrel, y_axis, 0, 900)
	Move(stock, y_axis, 0, 1400)

	WaitForMove(barrel, y_axis)
	WaitForMove(stock, y_axis)
		
	Turn(forearmr, x_axis, 0, math.rad(140))
	--Turn(torsoTrue, y_axis, 0, math.rad(120))
	Turn(forearml, z_axis, 0, math.rad(250))
	Turn(handl, y_axis, 0, math.rad(250))
		
	WaitForTurn(forearml, z_axis)
	Turn(shoulderl, x_axis, 0, math.rad(250))
	gun_unpacked = false
	bCanAim = true
end

local function UnpackGun()
	Signal(SIG_IDLE)
	Signal(SIG_PACK)
	SetSignalMask(SIG_PACK)
	
	Turn(forearmr, x_axis, 0, math.rad(200))
	Turn(forearml, z_axis, math.rad(-80), math.rad(200))
	Turn(handl, y_axis, math.rad(90), math.rad(200))
	WaitForTurn(forearml, z_axis)
	Move(barrel, y_axis, -4.2, 900)
	Move(stock, y_axis, 9, 1400)
	WaitForMove(barrel, y_axis)
	gun_unpacked = true
end
	
local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(10000)
	--if the gun is unpacked and we\'re not aiming, close it
	--if gun_unpacked and not bAiming then
	--
		Turn(torsoTrue, y_axis, 0, math.rad(120))
		Turn(torsoPivot, y_axis, 0, math.rad(120))
		torsoHeading = 0
		--Turn(shoulderr, x_axis, math.rad(-90), math.rad(140))
	--	StartThread(PackGun)
	--end
	maintainHeading = false
	bAiming = false
	StartThread(IdleAnim)
end

	
function script.AimWeapon(num, heading, pitch)
	Signal(SIG_IDLE)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	maintainHeading = true
	
	GG.DontFireRadar_CheckAim(unitID)
	
	-- Announce that we would like to aim, and wait until we can
	while not bCanAim do
		Sleep(100)
	end
	bAiming = true
	Turn(hips, x_axis, 0)
	Turn(torsoTrue, x_axis, 0)
	Turn(camera, y_axis, 0, math.rad(100))
	Turn(shoulderr, x_axis, math.rad(-90) - pitch, math.rad(180))
	Turn(shoulderl, x_axis, math.rad(-90) - pitch, math.rad(180))
	Turn(forearmr, x_axis, 0, math.rad(180))
	if not gun_unpacked then
		UnpackGun()
	end
	Turn(torsoPivot, y_axis, heading, AIM_SPEED)
	Turn(torsoTrue, y_axis, 0, VERT_AIM_SPEED)
	WaitForTurn(shoulderl, x_axis)
	WaitForTurn(torsoPivot, y_axis)
	WaitForTurn(torsoTrue, y_axis)
	WaitForTurn(shoulderr, x_axis)
	WaitForTurn(forearmr, x_axis)
	StartThread(RestoreAfterDelay)
	torsoHeading = 0
	Turn(camera, y_axis, 0, math.rad(100))
	return(true)
end

function script.BlockShot(num, targetID)
	return (targetID and (GG.DontFireRadar_CheckBlock(unitID, targetID) or GG.OverkillPrevention_CheckBlock(unitID, targetID, 1500.1, 28))) or false
end

function script.FireWeapon(num)
--	bCanAim = false
	Turn(forearmr, x_axis, math.rad(-20), math.rad(300))
--	Turn(torsoTrue, y_axis, math.rad(-20), math.rad(400))
--	Turn(camera, y_axis, math.rad(20), math.rad(400))
--	Turn(forearmr, y_axis, math.rad(10), math.rad(400))
	Move(barrel, y_axis, 0)
	WaitForTurn(forearmr, x_axis)
	Turn(forearmr, x_axis, 0, math.rad(-90), math.rad(15))
--	Turn(torsoTrue, y_axis, 0, math.rad(100))
--	Turn(camera, y_axis, 0, math.rad(150))
--	Turn(forearmr, y_axis, 0, math.rad(200))
	Sleep(15200)
	Move(barrel, y_axis, -4.2, 4)
--	bCanAim = true
end
	
function script.Killed(recentDamage, maxHealth)
	Signal(SIG_MOVE)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		--[[
		Turn(shinr, x_axis, 0)	
		Turn(thighr, x_axis, 0)
		Turn(thighl, x_axis, 0)
		Turn(shinl, x_axis, 0)

		WaitForTurn(thighl, x_axis)
		WaitForTurn(thighl, x_axis)
		Sleep(250)

		Turn(base, x_axis, math.rad(90), math.rad(50))
		Turn(hips, x_axis, math.rad(-90), math.rad(50))
		Turn(thighr, x_axis, math.rad(-45), math.rad(50))
		Turn(thighl, x_axis, math.rad(-45), math.rad(50))
		Turn(shinr, x_axis, math.rad(135), math.rad(50))	
		Turn(shinl, x_axis, math.rad(135), math.rad(50))
		Move(hips, y_axis, -3, 2000) 

		WaitForMove(hips, y_axis)		
		Sleep(2000)]]
		
		Explode(shoulderl, sfxNone)
		Explode(shoulderr, sfxNone)
		Explode(hips, sfxNone)
		Explode(torsoTrue, sfxNone)
		Explode(camera, sfxNone)
		return 1
	elseif severity <= .50 then
		Explode(shoulderl, sfxShatter)
		Explode(shoulderr, sfxShatter)
		Explode(camera, SFX.FALL + SFX.SMOKE + SFX.FIRE)
--		Sleep(200)
		Explode(torsoTrue, sfxShatter)
		
--		Turn(base, x_axis, math.rad(-90), math.rad(50))
--		Turn(hips, x_axis, math.rad(90), math.rad(50))
--		WaitForTurn(base, x_axis)
--		Sleep(1000)
	
		Explode(hips, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 1
	elseif severity <= .99 then
		Explode(hips, sfxShatter)
		Explode(torsoTrue, sfxShatter)
		Explode(shoulderl, sfxShatter)
		Explode(forearml, sfxShatter)
		Explode(shoulderr, sfxShatter)
		Explode(forearmr, sfxShatter)
		Explode(thighr, sfxShatter)
		Explode(thighl, sfxShatter)
		Explode(shinl, sfxShatter)
		Explode(shinr, sfxShatter)
		Explode(camera, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(backpack, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(receiver, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	else
		Explode(hips, sfxShatter)
		Explode(torsoTrue, sfxShatter)
		Explode(shoulderl, sfxShatter)
		Explode(forearml, sfxShatter)
		Explode(shoulderr, sfxShatter)
		Explode(forearmr, sfxShatter)
		Explode(thighr, sfxShatter)
		Explode(thighl, sfxShatter)
		Explode(shinl, sfxShatter)
		Explode(shinr, sfxShatter)
		Explode(camera, SFX.FALL + SFX.SMOKE + SFX.FIRE + sfxExplode)
		Explode(backpack, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(receiver, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
