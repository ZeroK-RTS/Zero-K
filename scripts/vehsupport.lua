include "constants.lua"

local base, aim, rockbase, body, turret, arms, firepoint1, firepoint2, exhaust1, exhaust2, gun, cab, connection,
	rwheel1, rwheel2, rwheel3,
	lwheel1, lwheel2, lwheel3,
	gs1r, gs2r, gs3r,
	gs1l, gs2l, gs3l 
= piece(
	"base", "aim", "rockbase", "body", "turret", "arms", "firepoint1", "firepoint2", "exhaust1", "exhaust2", "gun", "cab", "connection",
	"rwheel1", "rwheel2", "rwheel3",
	"lwheel1", "lwheel2", "lwheel3", 
	"gs1r", "gs2r", "gs3r",
	"gs1l", "gs2l", "gs3l"
)

local smokePiece = {turret, body}

local moving, runSpin, wheelTurnSpeed

local deployed = false

local gunPieces = {
	[1] = {firepoint = firepoint1, exhaust = exhaust1},
	[2] = {firepoint = firepoint2, exhaust = exhaust2}
}
local shot = 1

local spGetGroundHeight = Spring.GetGroundHeight
local spGetPiecePosition = Spring.GetUnitPiecePosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir

-- Signal definitions
local SIG_AIM = 1
local SIG_DEPLOY = 2
local SIG_RESTORE = 4

local SUSPENSION_BOUND = 6

local RESTORE_DELAY = 3000

local TURRET_TURN_SPEED = math.rad(240)
local GUN_TURN_SPEED = math.rad(60)
local ARMS_RAISE_SPEED = 10
local ARMS_LOWER_SPEED = 10
local WHEEL_TURN_MULT = 1.5

local ANIM_PERIOD = 50
local PIVOT_MOD = 3 --appox. equal to MAX_PIVOT / turnrate
local MAX_PIVOT = math.rad(24)
local MIN_PIVOT = math.rad(-24)
local PIVOT_SPEED = math.rad(60)

local CMD_ATTACK = CMD.ATTACK
local CMD_FIGHT = CMD.FIGHT

local turnTilt = 0

local lastShotFrame = false
local FIGHT_FIRE_TIME = 45

local SETTLE_PERIODS = 15
local settleTimer = 0

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, TURRET_TURN_SPEED/2)
	Turn(gun, x_axis, 0, GUN_TURN_SPEED/2)
end

local function SetDeploy(wantDeploy)
	Signal(SIG_DEPLOY)
	SetSignalMask(SIG_DEPLOY)
	if wantDeploy then
		Move(arms, y_axis, 10, ARMS_RAISE_SPEED)
		WaitForMove(arms, y_axis)
		deployed = true
	else
		Turn(turret, y_axis, 0, TURRET_TURN_SPEED/2)
		Turn(gun, x_axis, 0,GUN_TURN_SPEED/2)
		Move(arms, y_axis, 0, ARMS_LOWER_SPEED)
		deployed = false
	end
end

local ableToMove = true
local function SetAbleToMove(newMove)
	if ableToMove == newMove then
		return
	end
	ableToMove = newMove
	
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", (ableToMove and 1) or 0)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", (ableToMove and 1) or 0)
	GG.UpdateUnitAttributes(unitID)
end

local function KeepStatic()
	while true do
		local gameFrame = Spring.GetGameFrame()
		if lastShotFrame and (lastShotFrame > gameFrame) then
			local cmd = Spring.GetCommandQueue(unitID, 2)
			SetAbleToMove(not (cmd and cmd[1] and (cmd[1].id == CMD_ATTACK) and (#cmd[1].params == 1) and cmd[2] and (cmd[2].id == CMD_FIGHT) and (#cmd[2].params == 6)))
		else
			SetAbleToMove(true)
		end
		Sleep(300)
	end
end

function Roll()
	Sleep(500)
	if not moving then
		StopSpin(rwheel1, x_axis)
		StopSpin(rwheel2, x_axis)
		StopSpin(rwheel3, x_axis)
		StopSpin(lwheel1, x_axis)
		StopSpin(lwheel2, x_axis)
		StopSpin(lwheel3, x_axis)
	
		runSpin = false
	end
end

local function AnimControl() 
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)
	
	local lastHeading, currHeading, diffHeading, pivotAngle
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
		pivotAngle = diffHeading * PIVOT_MOD
		if pivotAngle > MAX_PIVOT then 
			pivotAngle = MAX_PIVOT 
		end
		if pivotAngle < MIN_PIVOT then 
			pivotAngle = MIN_PIVOT 
		end
		
		
		turnTilt = -pivotAngle*0.007
		-- Turn slowly for small course corrections
		if math.abs(diffHeading) < 0.02 then
			Turn(cab, y_axis, pivotAngle*2, PIVOT_SPEED*0.5)
			Turn(rockbase, y_axis, -pivotAngle*0.2, PIVOT_SPEED*0.5)
		else
			Turn(cab, y_axis, pivotAngle*2, PIVOT_SPEED)
			Turn(rockbase, y_axis, -pivotAngle*0.2, PIVOT_SPEED)
		end
		
		lastHeading = currHeading
		Sleep(ANIM_PERIOD)
	end
end

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

function StopMoving()
	StartThread(SetDeploy,true)
	moving = false
	StartThread(Roll)
end

function StartMoving()
	runSpin = true
	moving = true
	StartThread(SetDeploy,false)
	
	local x,y,z = spGetUnitVelocity(unitID)
	wheelTurnSpeed = math.sqrt(x*x+y*y+z*z)*WHEEL_TURN_MULT
	
	Spin(rwheel1, x_axis, wheelTurnSpeed)
	Spin(rwheel2, x_axis, wheelTurnSpeed)
	Spin(rwheel3, x_axis, wheelTurnSpeed)
	Spin(lwheel1, x_axis, wheelTurnSpeed)
	Spin(lwheel2, x_axis, wheelTurnSpeed)
	Spin(lwheel3, x_axis, wheelTurnSpeed)
end

function Suspension()
	local x, y, z, height
	local s1r, s2r, s3r = 0, 0, 0
	local s1l, s2l, s3l = 0, 0, 0
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
				s3r = GetWheelHeight(gs3r)
				s1l = GetWheelHeight(gs1l)
				s2l = GetWheelHeight(gs2l)
				s3l = GetWheelHeight(gs3l)
				
				--xtilta = (s3r + s3l - s1l - s1r)/6000	
				--xtiltv = xtiltv*0.99 + xtilta
				--xtilt = xtilt*0.98 + xtiltv

				ztilta = (s1r + s2r + s3r - s1l - s2l - s3l)/10000 + turnTilt
				ztiltv = ztiltv*0.99 + ztilta
				ztilt = ztilt*0.98 + ztiltv

				ya = (s1r + s2r + s3r + s1l + s2l + s3l)/1000
				yv = yv*0.99 + ya
				yp = yp*0.98 + yv

				Move(rockbase, y_axis, yp, 9000)
				--Turn(rockbase, x_axis, xtilt, math.rad(9000))
				Turn(rockbase, z_axis, -ztilt, math.rad(9000))

				Move(rwheel1, y_axis, s1r, 20)
				Move(rwheel2, y_axis, s2r, 20)
				Move(rwheel3, y_axis, s3r, 20)
											
				Move(lwheel1, y_axis, s1l, 20)
				Move(lwheel2, y_axis, s2l, 20)
				Move(lwheel3, y_axis, s3l, 20)

				Spin(rwheel1, x_axis, wheelTurnSpeed)
				Spin(rwheel2, x_axis, wheelTurnSpeed)
				Spin(rwheel3, x_axis, wheelTurnSpeed)
				Spin(lwheel1, x_axis, wheelTurnSpeed)
				Spin(lwheel2, x_axis, wheelTurnSpeed)
				Spin(lwheel3, x_axis, wheelTurnSpeed)
			end
		end
		Sleep(ANIM_PERIOD)
	end 
end

function script.Create()
	moving = false
	runSpin = false
	StartThread(SetDeploy,true)
	StartThread(Suspension)
	StartThread(AnimControl)
	StartThread(GG.Script.SmokeUnit, smokePiece)
	--StartThread(KeepStatic)
	
	Move(aim, y_axis, 10)
	
	Turn(exhaust1, x_axis, math.rad(180))
	Turn(exhaust2, x_axis, math.rad(180))
end

-- Weapons
function script.AimFromWeapon()
	return aim
end

function script.QueryWeapon()
	return gunPieces[shot].firepoint
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	if moving then
		return false
	else
		Turn(turret, y_axis, heading, TURRET_TURN_SPEED)
		Turn(gun, x_axis, -pitch, GUN_TURN_SPEED)
		WaitForTurn(turret, y_axis)
		WaitForTurn(gun, y_axis)
		StartThread(RestoreAfterDelay)

		return deployed
	end
end

function script.Shot()
	shot = 3 - shot
	EmitSfx(gunPieces[shot].firepoint, GG.Script.UNIT_SFX1)
	EmitSfx(gunPieces[shot].exhaust, GG.Script.UNIT_SFX2)
	lastShotFrame = Spring.GetGameFrame() + FIGHT_FIRE_TIME
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/600
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 38, 25 * distMult)
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(gun, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(gun, SFX.FALL)
		Explode(turret, SFX.SHATTER)
		Explode(body, SFX.NONE)
		return 1
	elseif severity <= 1 then
		Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(turret, SFX.SHATTER)
		Explode(body, SFX.NONE)
		return 2
	else
		Explode(gun, SFX.SHATTER)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(body, SFX.SHATTER)
		return 2
	end
end
