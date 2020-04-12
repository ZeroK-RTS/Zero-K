include 'constants.lua'

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
	{larmflare1, larmflare2, larmflare3, rarmflare1, rarmflare2, rarmflare3},
	{aaflare1, aaflare2},
	{shoulderflare},
	{headlaser1, headlaser2, headlaser3}
}
local barrels = {larmbarrel1, larmbarrel2, larmbarrel3, rarmbarrel1, rarmbarrel2, rarmbarrel3}
local aimpoints = {torso, aaturret, shoulderflare, head}

local gunIndex = {1,1,1,1}
local gunFixEmit = {true, false, false, false}

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

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(15)*PACE
local TORSO_TILT_ANGLE = math.rad(15)
local TORSO_TILT_SPEED = math.rad(15)*PACE

local PELVIS_LIFT_HEIGHT = 6
local PELVIS_LIFT_SPEED = 16
local PELVIS_LOWER_HEIGHT = 2
local PELVIS_LOWER_SPEED = 16

local ARM_FRONT_ANGLE = math.rad(-15)
local ARM_FRONT_SPEED = math.rad(35) * PACE
local ARM_BACK_ANGLE = math.rad(5)
local ARM_BACK_SPEED = math.rad(30) * PACE

local isFiring = false

local CHARGE_TIME = 60	-- frames
local FIRE_TIME = 120

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
end

local function Step(frontLeg, backLeg)

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

	Move(pelvis, y_axis, PELVIS_LOWER_HEIGHT, PELVIS_LOWER_SPEED)
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

	Move(pelvis, y_axis, PELVIS_LIFT_HEIGHT, PELVIS_LIFT_SPEED)
	Turn(torso, x_axis, 0, TORSO_TILT_SPEED)

	for i, p in pairs(frontLeg) do
		WaitForTurn(frontLeg[i], x_axis)
		WaitForTurn(backLeg[i], x_axis)
	end
	Sleep(0)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	while (true) do
		Step(leftLeg, rightLeg)
		Step(rightLeg, leftLeg)
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	Move(torso, y_axis, 0, 100)
	for i,p in pairs(leftLeg) do
		Turn(leftLeg[i], x_axis, 0, LEG_STRAIGHT_SPEEDS[i])
		Turn(rightLeg[i], x_axis, 0, 2)
	end
	Turn(pelvis, z_axis, 0, 1)
	Turn(torso, x_axis, 0, 1)
	if not(isFiring) then
		Turn(torso, y_axis, 0, 4)
	end
	Move(pelvis, y_axis, 0, 50)
	Turn(rarm, x_axis, 0, 1)
	Turn(larm, x_axis, 0, 1)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end


local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(5000)
	Turn(head, y_axis, 0, 2)
	Turn(torso, y_axis, 0, 1.5)
	Turn(larm, x_axis, 0, 2)
	Turn(rarm, x_axis, 0, 2)
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
	
	if num == 1 then
		Turn(torso, y_axis, heading, math.rad(180))
		Turn(larm, x_axis, -pitch, math.rad(120))
		Turn(rarm, x_axis, -pitch, math.rad(120))
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
	elseif num == 2 then
		Turn(aaturret, y_axis, heading - lastTorsoHeading, math.rad(360))
		Turn(aagun, x_axis, -pitch, math.rad(240))
		WaitForTurn(aaturret, y_axis)
		WaitForTurn(aagun, x_axis)
	--elseif num == 3 then
		--Turn(torso, y_axis, heading, math.rad(180))
		--Turn(shouldercannon, x_axis, math.rad(90) - pitch, math.rad(270))
		--WaitForTurn(torso, y_axis)
		--WaitForTurn(shouldercannon, x_axis)
	elseif num == 4 then
		Turn(torso, y_axis, heading, math.rad(180))
		WaitForTurn(torso, y_axis)
	end
	
	if num ~= 2 then
		lastTorsoHeading = heading
	end
	
	return true
end

local function BumpGunNum(num, doSleep)
	if doSleep then
		Sleep(33)
	end
	gunIndex[num] = gunIndex[num] + 1
	if gunIndex[num] > gunFlareCount[num] then
		gunIndex[num] = 1
	end
end

function script.Shot(num)
	if num == 1 then
		Move(barrels[gunIndex[1]], z_axis, -20)
		Move(barrels[gunIndex[1]], z_axis, 0, 20)
	end
	if gunFixEmit[num] then
		StartThread(BumpGunNum, num, true)
	else
		BumpGunNum(num)
	end
end

function script.BlockShot(num, targetID)
	if num ~= 3 then
		return false
	end
	if not targetID then
		return false
	end
	if GG.DontFireRadar_CheckBlock(unitID, targetID) then
		return true
	end
	-- Separation check is not required as the physics of the missile seems to result in a
	-- time to impact of between 140 and 150 frames in almost all cases.
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, 800.1, 150, false, false, true) then
		return true
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
