--linear constant 163840

include "constants.lua"

local base, rockbase, body, turret, firepoint, 
	rwheel1, rwheel2, 
	lwheel1, lwheel2, 
	gs1r, gs2r, gs1l, gs2l = 
piece('base', 'rockbase', 'body', 'turret', 'firepoint', 
	'rwheel1', 'rwheel2', 
	'lwheel1', 'lwheel2', 
	'gs1r', 'gs2r', 'gs1l', 'gs2l')

local SIG_AIM = 1
local SIG_MOVE = 2

local spGetGroundHeight = Spring.GetGroundHeight
local spGetPiecePosition = Spring.GetUnitPiecePosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir

local SUSPENSION_BOUND = 7
local WHEEL_TURN_MULT = 1.2
local ANIM_PERIOD = 50

local smokePiece = {turret, body}
local moving, runSpin, wheelTurnSpeed

local turnTilt = 0

local SETTLE_PERIODS = 15
local settleTimer = 0

local function GetWheelHeight(piece)
	local x,y,z = spGetUnitPiecePosDir(unitID, piece)
	local height = spGetGroundHeight(x,z) - y
	if height < -SUSPENSION_BOUND then
		height = -SUSPENSION_BOUND
	end
	if height > SUSPENSION_BOUND then
		height = SUSPENSION_BOUND
	end
	return height
end

local function Roll()
	Sleep(500)
	if not moving then
		StopSpin(rwheel1, x_axis)
		StopSpin(rwheel2, x_axis)
		StopSpin(lwheel1, x_axis)
		StopSpin(lwheel2, x_axis)
		runSpin = false
	end
end

function StopMoving()
	moving = false
	StartThread(Roll)
end


function StartMoving()
	runSpin = true
	moving = true
	
	local x,y,z = spGetUnitVelocity(unitID)
	wheelTurnSpeed = math.sqrt(x*x+y*y+z*z)*WHEEL_TURN_MULT
	
	Spin(rwheel1, x_axis, wheelTurnSpeed)
	Spin(rwheel2, x_axis, wheelTurnSpeed)
	Spin(lwheel1, x_axis, wheelTurnSpeed)
	Spin(lwheel2, x_axis, wheelTurnSpeed)
end


local function AnimControl() 
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)
	
	local lastHeading, currHeading, diffHeading, turnAngle
	lastHeading = GetUnitValue(COB.HEADING)*GG.Script.headingToRad
	while true do 
	
		--pivot
		currHeading = GetUnitValue(COB.HEADING)*GG.Script.headingToRad
		diffHeading = (currHeading - lastHeading)
		
		-- Fix wrap location
		if diffHeading > math.pi then
			diffHeading = diffHeading - 2*math.pi
		end
		if diffHeading < -math.pi then
			diffHeading = diffHeading + 2*math.pi
		end
		
		-- Bound maximun pivot
		turnAngle = diffHeading
		
		turnTilt = -turnAngle*0.007
		lastHeading = currHeading
		Sleep(ANIM_PERIOD)
	end
end

function Suspension()
	local x, y, z, height
	local s1r, s2r = 0, 0
	local s1l, s2l = 0, 0
	local xtilt, xtiltv, xtilta = 0, 0, 0
	local ztilt, ztiltv, ztilta = 0, 0, 0
	local ya, yv, yp = 0, 0, 0
	local speed = 0
	
	while true do 
		speed = select(4,spGetUnitVelocity(unitID))
		wheelTurnSpeed = speed*WHEEL_TURN_MULT
	
		if moving then
			if speed <= 0.05 then
				StopMoving()
			end
		else
			if speed > 0.05 then
				StartMoving()
			end
		end
		
		if speed > 0.05 then
			settleTimer = 0
		elseif settleTimer < SETTLE_PERIODS then
			settleTimer = settleTimer + 1
		end
		
		if speed > 0.05 or (settleTimer < SETTLE_PERIODS) then
			x,y,z = spGetUnitPosition(unitID)
			height = spGetGroundHeight(x,z)
			
			if y - height < 1 then -- If I am on the ground
				s1r = GetWheelHeight(gs1r)
				s2r = GetWheelHeight(gs2r)
				s1l = GetWheelHeight(gs1l)
				s2l = GetWheelHeight(gs2l)
				
				--xtilta = (s3r + s3l - s1l - s1r)/6000	
				--xtiltv = xtiltv*0.99 + xtilta
				--xtilt = xtilt*0.98 + xtiltv

				ztilta = (s1r + s2r - s1l - s2l)/10000 + turnTilt
				ztiltv = ztiltv*0.99 + ztilta
				ztilt = ztilt*0.98 + ztiltv

				ya = (s1r + s2r + s1l + s2l)/1000
				yv = yv*0.99 + ya
				yp = yp*0.98 + yv

				Move(rockbase, y_axis, yp, 9000)
				--Turn(rockbase, x_axis, xtilt, math.rad(9000))
				Turn(rockbase, z_axis, -ztilt, math.rad(9000))

				Move(rwheel1, y_axis, s1r, 20)
				Move(rwheel2, y_axis, s2r, 20)
											
				Move(lwheel1, y_axis, s1l, 20)
				Move(lwheel2, y_axis, s2l, 20)

				Spin(rwheel1, x_axis, wheelTurnSpeed)
				Spin(rwheel2, x_axis, wheelTurnSpeed)
				Spin(lwheel1, x_axis, wheelTurnSpeed)
				Spin(lwheel2, x_axis, wheelTurnSpeed)
			end
		end
		Sleep(ANIM_PERIOD)
	end 
end

function script.Create()
	moving = false
	runSpin = false
	StartThread(Suspension)
	StartThread(AnimControl)
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

-- Weapons
function script.AimFromWeapon()
	return firepoint
end

function script.QueryWeapon()
	return firepoint
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/730
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 290.1, 40 * distMult)
	end
	return false
end

function script.AimWeapon()
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	
	if severity <= 0.25 then
		Explode(rwheel2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(turret, SFX.NONE)
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(lwheel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(lwheel2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(turret, SFX.SHATTER)
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= 0.99 then
		Explode(rwheel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(lwheel2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(lwheel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(turret, SFX.SHATTER)
		Explode(body, SFX.NONE)
		return 2
	end

	Explode(rwheel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rwheel2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lwheel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(lwheel2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(body, SFX.SHATTER)
	return 2
end
