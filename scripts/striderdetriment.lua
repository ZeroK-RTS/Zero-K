include 'constants.lua'

local AngleAverageShortest  = Spring.Utilities.Vector.AngleAverageShortest
local AngleSubtractShortest = Spring.Utilities.Vector.AngleSubtractShortest

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- pieces

local pelvis, torso, head, shouldercannon, shoulderflare = piece('pelvis', 'torso', 'head', 'shouldercannon', 'shoulderflare')
local aaturret, aagun, aaflare1, aaflare2, headlaser1, headlaser2, headlaser3 = piece('AAturret', 'AAguns', 'AAflare1', 'AAflare2', 'headlaser1', 'headlaser2', 'headlaser3')
local larm, larmcannon, larmbarrel1, larmflare1, larmbarrel2, larmflare2, larmbarrel3, larmflare3 = piece('larm', 'larmcannon', 'larmbarrel1', 'larmflare1',
	'larmbarrel2', 'larmflare2', 'larmbarrel3', 'larmflare3')
local rarm, rarmcannon, rarmbarrel1, rarmflare1, rarmbarrel2, rarmflare2, rarmbarrel3, rarmflare3 = piece('rarm', 'rarmcannon', 'rarmbarrel1', 'rarmflare1',
	'rarmbarrel2', 'rarmflare2', 'rarmbarrel3', 'rarmflare3')
local lupleg, lmidleg, lleg, lfoot, lftoe, lbtoe = piece('lupleg', 'lmidleg', 'lleg', 'lfoot', 'lftoe', 'lbtoe')
local rupleg, rmidleg, rleg, rfoot, rftoe, rbtoe = piece('rupleg', 'rmidleg', 'rleg', 'rfoot', 'rftoe', 'rbtoe')
local leftLeg = { thigh=piece'lupleg', knee=piece'lmidleg', shin=piece'lleg', foot=piece'lfoot', toef=piece'lftoe', toeb=piece'lbtoe' }
local rightLeg = { thigh=piece'rupleg', knee=piece'rmidleg', shin=piece'rleg', foot=piece'rfoot', toef=piece'rftoe', toeb=piece'rbtoe' }

local smokePiece = { torso, head, shouldercannon }

local gunFlares = {
	{larmflare1, larmflare2, larmflare3},
	{rarmflare1, rarmflare2, rarmflare3},
	{shoulderflare},
	{aaflare1, aaflare2},
	{headlaser1, headlaser2, headlaser3},
	{lfoot},
	{lfoot},
	{lfoot}
}

local barrels = {
	{larmbarrel1, larmbarrel2, larmbarrel3},
	{rarmbarrel1, rarmbarrel2, rarmbarrel3},
}
local aimpoints = {larmcannon, rarmcannon, aaturret, headlaser2, shouldercannon, lfoot, lfoot, lfoot}

local gunIndex = {1,1,1,1,1,1,1,1}
local gunFixEmit = {true, true, false, false, false, false, false, false}

local gunFlareCount = {}
for i = 1, #gunFlares do
	gunFlareCount[i] = #gunFlares[i]
end

local lastTorsoHeading = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--signals
local SIG_Restore = 1
local SIG_Walk = 2

local PACE = 0.8

-- four leg positions - front to straight, then to back, then to bent (then front again)
local LEG_FRONT_ANGLES    = { thigh=math.rad(-40), knee=math.rad(-10), shin=math.rad(50), foot=math.rad(0), toef=math.rad(0), toeb=math.rad(15) }
local LEG_FRONT_SPEEDS    = { thigh=math.rad(60)*PACE, knee=math.rad(60)*PACE, shin=math.rad(110)*PACE, foot=math.rad(90)*PACE, toef=math.rad(90)*PACE, toeb=math.rad(30)*PACE }

local LEG_STRAIGHT_ANGLES = { thigh=math.rad(-10), knee=math.rad(-20), shin=math.rad(30), foot=math.rad(0), toef=math.rad(0), toeb=math.rad(0) }
local LEG_STRAIGHT_SPEEDS = { thigh=math.rad(60)*PACE, knee=math.rad(30)*PACE, shin=math.rad(40)*PACE, foot=math.rad(90)*PACE, toef=math.rad(90)*PACE, toeb=math.rad(30)*PACE }

local LEG_BACK_ANGLES     = { thigh=math.rad(10), knee=math.rad(-5), shin=math.rad(15), foot=math.rad(0), toef=math.rad(-20), toeb=math.rad(-10) }
local LEG_BACK_SPEEDS     = { thigh=math.rad(30)*PACE, knee=math.rad(60)*PACE, shin=math.rad(90)*PACE, foot=math.rad(90)*PACE, toef=math.rad(40)*PACE, toeb=math.rad(60)*PACE }

local LEG_BENT_ANGLES     = { thigh=math.rad(-15), knee=math.rad(20), shin=math.rad(-20), foot=math.rad(0), toef=math.rad(0), toeb=math.rad(0) }
local LEG_BENT_SPEEDS     = { thigh=math.rad(60)*PACE, knee=math.rad(90)*PACE, shin=math.rad(90)*PACE, foot=math.rad(90)*PACE, toef=math.rad(90)*PACE, toeb=math.rad(90)*PACE }

local LEG_STEP_ANGLES     = { thigh=math.rad(-9), knee=math.rad(30), shin=math.rad(-22), foot=math.rad(8), toef=math.rad(0), toeb=math.rad(0) }
local LEG_STEP_SPEEDS     = { thigh=math.rad(15)*PACE, knee=math.rad(50)*PACE, shin=math.rad(50)*PACE, foot=math.rad(50)*PACE, toef=math.rad(50)*PACE, toeb=math.rad(50)*PACE }

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(15)*PACE
local TORSO_TILT_ANGLE = math.rad(15)
local TORSO_TILT_SPEED = math.rad(15)*PACE

local PELVIS_LIFT_HEIGHT = 11.5
local PELVIS_LIFT_SPEED = 14
local PELVIS_LOWER_HEIGHT = 6.5
local PELVIS_LOWER_SPEED = 15

local ARM_FRONT_ANGLE = math.rad(-15)
local ARM_FRONT_SPEED = math.rad(35) * PACE
local ARM_BACK_ANGLE = math.rad(5)
local ARM_BACK_SPEED = math.rad(30) * PACE

local leftTorsoHeading = false
local rightTorsoHeading = false
local lastGunAverageHeading = false

local JUMP_TURN_SPEED = math.pi/80 -- matches jump_delay_turn_scale in unitdef

local isFiring = false
-- Effects
local dirtfling = 1024
local muzzle_flash = 1025
local shells = 1026
local muzzle_flash_large = 1027
local muzzle_smoke_large = 1028
local jetfeet = 1029
local jetfeet_fire = 1030

-- Weapons
local landing_explosion = 4101 --Weapon 6
local footcrater = 4102 --Weapon 7
local takeoff_explosion = 4103 --Weapon 8

local unitDefID = Spring.GetUnitDefID(unitID)
local wd = UnitDefs[unitDefID].weapons[3] and UnitDefs[unitDefID].weapons[3].weaponDef
local reloadTime = wd and WeaponDefs[wd].reload*30 or 30

wd = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTimeShort = wd and WeaponDefs[wd].reload*30 or 30

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function script.Create()
	Turn(larm, z_axis, -0.1)
	Turn(rarm, z_axis, 0.1)
	Turn(shoulderflare, x_axis, math.rad(-90))
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitMaxRange(unitID, 510)
end

local function Step(frontLeg, backLeg, impactFoot, pelvisMult)
	-- contact: legs fully extended in stride
	for i,p in pairs(frontLeg) do
		Turn(frontLeg[i], x_axis, LEG_FRONT_ANGLES[i], LEG_FRONT_SPEEDS[i])
		Turn(backLeg[i], x_axis, LEG_BACK_ANGLES[i], LEG_BACK_SPEEDS[i])
	end

	-- swing arms and body
	if not(isFiring) then
		if (frontLeg == leftLeg) then
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(larmcannon, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(rarm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
		else
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(larm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(rarmcannon, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(rarm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
		end
	end
	
	Move(pelvis, y_axis, PELVIS_LOWER_HEIGHT, PELVIS_LOWER_SPEED*pelvisMult)
	Turn(torso, x_axis, TORSO_TILT_ANGLE, TORSO_TILT_SPEED)

	for i, p in pairs(frontLeg) do
		WaitForTurn(frontLeg[i], x_axis)
		WaitForTurn(backLeg[i], x_axis)
	end

	-- passing (front foot flat under body, back foot passing with bent knee)
	for i, p in pairs(frontLeg) do
		Turn(frontLeg[i], x_axis, LEG_STRAIGHT_ANGLES[i], LEG_STRAIGHT_SPEEDS[i])
		Turn(backLeg[i], x_axis, LEG_BENT_ANGLES[i], LEG_BENT_SPEEDS[i])
	end
	--EmitSfx(impactFoot, dirtfling)
	--EmitSfx(impactFoot, footcrater)
	Move(pelvis, y_axis, PELVIS_LIFT_HEIGHT, PELVIS_LIFT_SPEED*pelvisMult)
	Turn(torso, x_axis, 0, TORSO_TILT_SPEED)

	for i, p in pairs(frontLeg) do
		WaitForTurn(frontLeg[i], x_axis)
		WaitForTurn(backLeg[i], x_axis)
	end
	Sleep(0)
end

local function StepInPlace(leftLeg, rightLeg)
	Move(pelvis, y_axis, 2, 6)
	for i, p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0.8*LEG_STEP_ANGLES[i], LEG_STEP_SPEEDS[i]*1.4)
		Turn(rightLeg[i], x_axis, -0.5*LEG_STEP_ANGLES[i], LEG_STEP_SPEEDS[i])
	end
	Sleep(400)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	local first = true
	while (true) do
		Step(leftLeg, rightLeg, lfoot, (first and 2) or 1)
		Step(rightLeg, leftLeg, rfoot, (first and 1.2) or 1)
		first = false
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	Move(torso, y_axis, 0, 1)
	for i,p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0, LEG_STRAIGHT_SPEEDS[i])
		Turn(rightLeg[i], x_axis, 0, LEG_STRAIGHT_SPEEDS[i])
	end
	Turn(pelvis, z_axis, 0, math.rad(30))
	Turn(torso, x_axis, 0, math.rad(30))
	if not(isFiring) then
		Turn(torso, y_axis, 0, math.rad(30))
	end
	Move(pelvis, y_axis, 0, 20)
	Turn(rarm, x_axis, 0, math.rad(30))
	Turn(larm, x_axis, 0, math.rad(10))
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

-- Jumping
local function PreJumpThread(turn, lineDist, flightDist, duration)
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	local heading = -Spring.GetUnitHeading(unitID)*GG.Script.headingToRad
	Spring.MoveCtrl.SetRotation(unitID, 0, heading, 0) -- keep current heading
	
	local rotationRequired = -turn*GG.Script.headingToRad
	local rotationFrames = math.ceil(math.abs(rotationRequired/JUMP_TURN_SPEED)/12)*12

	--Spring.MoveCtrl.SetRotation(unitID, 0, heading + rotationRequired, 0) -- keep current heading
	--Sleep(2000)
	
	Spring.MoveCtrl.SetRotationVelocity(unitID, 0, rotationRequired/rotationFrames, 0)
	while true do
		StepInPlace(leftLeg, rightLeg)
		rotationFrames = rotationFrames - 12
		if rotationFrames <= 0 then
			break
		end
		
		Move(pelvis, y_axis, 4, 7)
		Sleep(400)
		rotationFrames = rotationFrames - 12
		if rotationFrames <= 0 then
			break
		end
		
		StepInPlace(rightLeg, leftLeg)
		rotationFrames = rotationFrames - 12
		if rotationFrames <= 0 then
			break
		end
		
		Move(pelvis, y_axis, 4, 7)
		Sleep(400)
		rotationFrames = rotationFrames - 12
		if rotationFrames <= 0 then
			break
		end
	end
	
	Spring.MoveCtrl.SetRotationVelocity(unitID, 0, 0, 0)
	
	for i,p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0, LEG_STEP_SPEEDS[i])
		Turn(rightLeg[i], x_axis, 0, LEG_STEP_SPEEDS[i])
	end
	Move(pelvis, y_axis, 0, 8)
	Sleep(600)
	
	for i,p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0.8*LEG_STEP_ANGLES[i], LEG_STEP_SPEEDS[i]*1.4)
		Turn(rightLeg[i], x_axis, 0.8*LEG_STEP_ANGLES[i], LEG_STEP_SPEEDS[i]*1.4)
	end
	Move(torso, y_axis, 0, 1)
	Move(pelvis, y_axis, -8, 18)
	
	Turn(pelvis, z_axis, 0, math.rad(30))
	Turn(torso, x_axis, 0, math.rad(30))
	if not(isFiring) then
		Turn(torso, y_axis, 0, math.rad(140))
		WaitForTurn(torso, y_axis)
	end
	Turn(rarm, x_axis, ARM_BACK_ANGLE, ARM_FRONT_SPEED)
	Turn(larm, x_axis, ARM_BACK_ANGLE, ARM_FRONT_SPEED)
	--EmitSfx(lfoot, jetfeet)
	--EmitSfx(rfoot, jetfeet)
end

local function EndJumpThread()
	EmitSfx(lfoot, landing_explosion)
	EmitSfx(lfoot, dirtfling)
	Turn(torso, x_axis, -30, math.rad(500))
	Turn(larm, x_axis,  math.rad(-60), math.rad(500))
	Turn(rarm, x_axis,  math.rad(-60), math.rad(500))
	WaitForTurn(torso, x_axis)
	WaitForTurn(larm, x_axis)
	WaitForTurn(rarm, x_axis)
	Sleep(200)
	Turn(torso, x_axis, 0, math.rad(35))
	Turn(larm, x_axis, 0, math.rad(35))
	Turn(rarm, x_axis, 0, math.rad(35))
	WaitForTurn(torso, x_axis)
	WaitForTurn(larm, x_axis)
	WaitForTurn(rarm, x_axis)
end

function preJump(turn,lineDist,flightDist,duration)
	StartThread(PreJumpThread, turn,lineDist,flightDist,duration)
end

function beginJump()
	for i,p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0, LEG_STEP_SPEEDS[i])
		Turn(rightLeg[i], x_axis, 0, LEG_STEP_SPEEDS[i])
	end
	local x,y,z = Spring.GetUnitPosition(unitID, true)
	GG.PlayFogHiddenSound("DetrimentJump", 15, x, y, z)
end

function jumping(jumpPercent)
	if jumpPercent < 30 then
		GG.PokeDecloakUnit(unitID, 50)
		EmitSfx(lfoot, jetfeet_fire)
		EmitSfx(rfoot, jetfeet_fire)
	end

	if jumpPercent > 95 and not landing then
		landing = true	
	end
end

function halfJump()
end

function endJump()
	landing = false
	StartThread(EndJumpThread)
end

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(2000)
	Turn(head, y_axis, 0, 2)
	Move(head, y_axis, -6, 10)
	Move(head, z_axis, -4, 10)
	Turn(torso, y_axis, 0, math.rad(70))
	Turn(larm, x_axis, 0, math.rad(30))
	Turn(larmcannon, y_axis, 0, math.rad(10))
	Turn(rarm, x_axis, 0, math.rad(30))
	Turn(rarmcannon, y_axis, 0, math.rad(10))
	Turn(shouldercannon, x_axis, 0, math.rad(90))
	isFiring = false
	lastTorsoHeading = 0
end

function script.AimFromWeapon(num)
	return aimpoints[num]
end

function script.QueryWeapon(num)
	return gunFlares[num][ gunIndex[num] ]
end

function script.AimWeapon(num, heading, pitch)
	local SIG_AIM = 2^(num+1)

	isFiring = true
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	StartThread(RestoreAfterDelay)

	if num == 1 then  -- Left gunpod
		leftTorsoHeading = heading
		if rightTorsoHeading then
			heading = AngleAverageShortest(rightTorsoHeading, leftTorsoHeading)
			rightTorsoHeading = false
		end
		lastGunAverageHeading = heading
		
		local armAngle = leftTorsoHeading - heading
		if armAngle > 3 then
			armAngle = armAngle - 2*math.pi
		end
		armAngle = math.min(0.2, math.max(-0.2, armAngle))
		
		Turn(torso, y_axis, heading, math.rad(140))
		Turn(larmcannon, y_axis, armAngle, math.rad(20))
		Turn(larm, x_axis, -pitch, math.rad(40))
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
	elseif num == 2 then -- Right gunpod
		rightTorsoHeading = heading
		if leftTorsoHeading then
			heading = AngleAverageShortest(rightTorsoHeading, leftTorsoHeading)
			leftTorsoHeading = false
		end
		lastGunAverageHeading = heading
		
		local armAngle = rightTorsoHeading - heading
		if armAngle > 3 then
			armAngle = armAngle - 2*math.pi
		end
		
		-- The right arm avoids aiming if there is too much conflict between the arms.
		if math.abs(armAngle) > 0.7 then
			lastGunAverageHeading = false
			rightTorsoHeading = false
			return false
		end
		
		armAngle = math.min(0.2, math.max(-0.2, armAngle))
		
		Turn(torso, y_axis, heading, math.rad(140))
		Turn(rarmcannon, y_axis, armAngle, math.rad(20))
		Turn(rarm, x_axis, -pitch, math.rad(40))
		WaitForTurn(torso, y_axis)
		WaitForTurn(rarm, x_axis)
	elseif num == 3 then -- Shoulder Cannon
		Turn(torso, y_axis, heading, math.rad(90))
		WaitForTurn(torso, y_axis)
		Turn(shouldercannon, x_axis, -pitch+math.rad(90),  math.rad(90))
		Move(shouldercannon, y_axis, -2, 0.7)
		WaitForTurn(shouldercannon, x_axis)
	elseif num == 4 then
		Turn(aaturret, y_axis, heading - lastTorsoHeading, math.rad(360))
		Turn(aagun, x_axis, -pitch, math.rad(240))
		WaitForTurn(aaturret, y_axis)
		WaitForTurn(aagun, x_axis)
		return true
	elseif num == 5 then -- Face laser
		if lastGunAverageHeading then
			heading = lastGunAverageHeading
			lastGunAverageHeading = false
		end
		Turn(torso, y_axis, heading, math.rad(90))
		Move(head, y_axis, 0, 10)
		Move(head, z_axis, 0, 10)
		WaitForTurn(torso, y_axis)
	end
	lastTorsoHeading = heading
	return true
end

local function BumpGunNum(num)
	gunIndex[num] = gunIndex[num] + 1
	if gunIndex[num] > gunFlareCount[num] then
		gunIndex[num] = 1
	end
end

local function Recoil(num)
	Sleep(33)
	EmitSfx(gunFlares[num][gunIndex[num]], muzzle_flash_large)
	Move(barrels[num][gunIndex[num]], z_axis, -40)
	Move(barrels[num][gunIndex[num]], z_axis, 0, 30)
	BumpGunNum(num)
end

function script.Shot(num)
	-- Left
	if num == 1 or num == 2 then
		StartThread(Recoil, num, true)
	end

	-- Shoulder cannon
	if num == 3 then
		Move(shouldercannon, z_axis, -30)
		Turn(torso, x_axis, math.rad(-5))
		EmitSfx(shoulderflare, muzzle_flash_large)
		Turn(torso, x_axis, 0, math.rad(10))
		Move(shouldercannon, z_axis, 0, 50)
		Turn(shouldercannon, x_axis, 0, math.rad(10))
	end

	if gunFixEmit[num] then
		StartThread(BumpGunNum, num, true)
	else
		BumpGunNum(num)
	end
end

function script.BlockShot(num, targetID)
	if not targetID then
		return false
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .5) then
		Explode(torso, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(rarmcannon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(larmcannon, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(larm, SFX.SHATTER)
	
		return 1 -- corpsetype
	else
		Explode(torso, SFX.SHATTER)
		Explode(head, SFX.SMOKE + SFX.FIRE)
		Explode(pelvis, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
