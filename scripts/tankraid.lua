-- linear constant 65536

include "constants.lua"

-- WARNING: change your constant for the -brackets to 65536 before compilingnot
local base, body, turret, sleeve, barrel, firepoint, tracks1, tracks2, tracks3, tracks4,
wheels1, wheels2, wheels3, wheels4, wheels5, wheels6, wheels7, wheels8 =
piece('base', 'body', 'turret', 'sleeve', 'barrel', 'firepoint', 'tracks1', 'tracks2',
'tracks3', 'tracks4', 'wheels1', 'wheels2', 'wheels3', 'wheels4', 'wheels5', 'wheels6', 'wheels7', 'wheels8')

local moving, once, animCount = false,true,0

-- Signal definitions
local SIG_Walk = 2
local SIG_Restore = 1
local SIG_AIM1 = 1

local ANIM_SPEED = 50
local RESTORE_DELAY = 3000

local TURRET_TURN_SPEED = math.rad(900)
local GUN_TURN_SPEED = math.rad(400)

local WHEEL_TURN_SPEED1 = 480
local WHEEL_TURN_SPEED1_ACCELERATION = 75
local WHEEL_TURN_SPEED1_DECELERATION = 200

local smokePiece = {body, turret}

local flaming = false

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	
	Sleep(RESTORE_DELAY)
	
	Turn(turret, y_axis, math.rad(0), math.rad(TURRET_TURN_SPEED/2))
	Turn(sleeve, x_axis, math.rad(0), math.rad(TURRET_TURN_SPEED/2))
end

----------------------------------------------------------
----------------------------------------------------------

--[[
function FlameTrailThread()
	flaming = true
	Signal(SIG_Restore)
	Signal(SIG_AIM1)
	
	Turn(turret, y_axis, math.pi, math.rad(TURRET_TURN_SPEED))
	Turn(sleeve, x_axis, 0.6, math.rad(GUN_TURN_SPEED))
	
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	
	for i = 1, 20 do
		EmitSfx(firepoint, GG.Script.FIRE_W2)
		Sleep(400)
	end
	flaming = false
end


function FlameTrail()
	StartThread(FlameTrailThread)
end
]]

----------------------------------------------------------
----------------------------------------------------------

local function AnimationControl()

	local current_tracks = 0
	
	while true do
	
		if moving or once then
		
			if current_tracks == 0 then
			
				Show(tracks1)
				Hide(tracks4)
				current_tracks = current_tracks + 1
			elseif current_tracks == 1 then
				
				Show(tracks2)
				Hide(tracks1)
				current_tracks = current_tracks + 1
			elseif current_tracks == 2 then
			
				Show(tracks3)
				Hide(tracks2)
				current_tracks = current_tracks + 1
			elseif current_tracks == 3 then
			
				Show(tracks4)
				Hide(tracks3)
				current_tracks = 0
			end
			
			once = false
			
		end
		animCount = animCount + 1
		Sleep(ANIM_SPEED)
	end
end

local function Moving()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	Spin(wheels1, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels2, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels3, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels4, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels5, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels6, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels7, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
	Spin(wheels8, x_axis, WHEEL_TURN_SPEED1, WHEEL_TURN_SPEED1_ACCELERATION)
end

local function Stopping()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	-- I don\'t like insta braking. It\'s not perfect but works for most cases.
	-- Probably looks goofy when the unit is turtling,, i.e. does not become faster as time increases..
	once = animCount*ANIM_SPEED/1000

	StopSpin(wheels1, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels2, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels3, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels4, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels5, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels6, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels7, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
	StopSpin(wheels8, x_axis, WHEEL_TURN_SPEED1_DECELERATION)
end


function script.StartMoving()
	moving = true
	animCount = 0
	StartThread(Moving)
end

function script.StopMoving()

	moving = false
	StartThread(Stopping)
end

-- Weapons
function script.AimFromWeapon()
	return turret
end

function script.QueryWeapon()
	return firepoint
end

function script.AimWeapon(num, heading, pitch)
	if flaming then
		return false
	end
	
	Signal(SIG_AIM1)
	SetSignalMask(SIG_AIM1)
	
	Turn(turret, y_axis, heading, TURRET_TURN_SPEED)
	Turn(sleeve, x_axis, -pitch, GUN_TURN_SPEED)
	
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	
	StartThread(RestoreAfterDelay)
	
	return true
	--[[
	local fx, _, fz = Spring.GetUnitPiecePosition(unitID, firepoint)
	local tx, _, tz = Spring.GetUnitPiecePosition(unitID, turret)
	local pieceHeading = math.pi * Spring.GetHeadingFromVector(fx-tx,fz-tz) * 2^-15
	
	local headingDiff = math.abs((heading+pieceHeading)%(math.pi*2) - math.pi)
	
	if headingDiff > 2.6 then
		Turn(turret, y_axis, heading)
		Turn(sleeve, x_axis, -pitch)
		StartThread(RestoreAfterDelay)
		-- EmitSfx works if the turret takes no time to turn and there is no waitForTurn
		return true
	else
		Turn(turret, y_axis, heading, math.rad(TURRET_TURN_SPEED))
		Turn(sleeve, x_axis, -pitch, math.rad(GUN_TURN_SPEED))
		StartThread(RestoreAfterDelay)
		return false
	end
	--]]
end

local function Recoil()
	Move(barrel, z_axis, -3.5)
	Sleep(150)
	Move(barrel, z_axis, 0, 10)
end

function script.BlockShot(num)
	return flaming
end

function script.Shot(num)
	--[[
	Turn(firepoint, y_axis, math.rad(25))
	EmitSfx(firepoint, GG.Script.FIRE_W2)
	Turn(firepoint, y_axis, - math.rad(25))
	EmitSfx(firepoint, GG.Script.FIRE_W2)
	Turn(firepoint, y_axis, 0)
	--]]
	StartThread(Recoil)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 125, 50)
end

function script.Killed(recentDamage, maxHealth)
	local severity = 100 * recentDamage / maxHealth
	if severity <= 25 then
		Explode(body, SFX.NONE)
		Explode(turret, SFX.NONE)
		return 1
	end
	if severity <= 50 then
		Explode(body, SFX.NONE)
		Explode(turret,SFX.NONE)
		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 1
	else
		Explode(body, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(tracks1, SFX.SHATTER + SFX.SMOKE + SFX.FIRE)
		Hide(tracks2)
		Hide(tracks3)
		Hide(tracks4)
		return 2
	end
end

function script.Create()
	moving = false
	
	Turn(firepoint, x_axis, math.rad(7))
	
	Hide(tracks1)
	Hide(tracks2)
	Hide(tracks3)

	while select(5, Spring.GetUnitHealth(unitID)) < 1 do
		Sleep(250)
	end
	
	StartThread(AnimationControl)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end
