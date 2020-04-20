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
	{larmflare1, larmflare2, larmflare3},	
	{rarmflare1, rarmflare2, rarmflare3},		
	{shoulderflare},	
	{lfoot}
}

local barrelsL = {larmbarrel1, larmbarrel2, larmbarrel3}
local barrelsR = {rarmbarrel1, rarmbarrel2, rarmbarrel3}
local aimpoints = {larm, rarm, shoulderflare, lfoot}

local gunIndex = {1,1,1,1}
local gunFixEmit = {true, true, false, false}

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
local lgunpod_not_aimed = true
local rgunpod_not_aimed = true

local CHARGE_TIME = 60	-- frames
local FIRE_TIME = 120



local sp1 = 1.2
local sp2 = 1
local lf_angle = math.rad(25)
local rf_angle = math.rad(-25)
local lb_angle = math.rad(-65)
local rb_angle = math.rad(65)

local p_angle = -.3
local th_angle = -.3
local th_speed = 1.1
local sh_angle = .4
local sh_speed = 1
local drop = .8

local dirtfling = 1024
local muzzle_flash = 1025
local shells = 1026
local muzzle_flash_large = 1027
local muzzle_smoke_large = 1028
local jetfeet = 1029
local jetfeet_fire = 1030
local crater = 4099 --Weapon 4


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
	Move(pelvis, y_axis, 0, 1)
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

local function BeginJumpThread()
	Signal(SIG_Walk)	
	EmitSfx(lfoot, jetfeet)
	EmitSfx(rfoot, jetfeet)
	local x,y,z = Spring.GetUnitPosition(unitID, true)	
	GG.PlayFogHiddenSound("DetrimentJump", 15, x, y, z)	
end

local function EndJumpThread()
	EmitSfx(lfoot, crater)	
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

function preJump(turn,distance)
	StartThread(StopWalk)	
end

function beginJump()	
	StartThread(BeginJumpThread)
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
	Turn(torso, y_axis, 0, math.rad(70))
	Turn(larm, x_axis, 0, math.rad(30))
	Turn(rarm, x_axis, 0, math.rad(30))
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
		lgunpod_not_aimed = true
		Turn(torso, y_axis, heading, math.rad(140))
		Turn(larm, x_axis, math.rad(-10)-pitch, math.rad(40))		
		WaitForTurn(torso, y_axis)
		WaitForTurn(larm, x_axis)
		lgunpod_not_aimed = false
	elseif num == 2 then -- Right gunpod
		rgunpod_not_aimed = true
		Turn(torso, y_axis, heading, math.rad(140))		
		Turn(rarm, x_axis, math.rad(-10)-pitch, math.rad(40))
		WaitForTurn(torso, y_axis)
		WaitForTurn(rarm, x_axis)	
		rgunpod_not_aimed = false			
	elseif num == 3 then
		Turn(torso, y_axis, heading, math.rad(90))
		WaitForTurn(torso, y_axis)
	end
	lastTorsoHeading = heading
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
	-- Plasma Left
	if num == 1 then		
		EmitSfx(larmflare3, muzzle_smoke_large2)		
		Move(barrelsL[gunIndex[1]], z_axis, -40)		
		EmitSfx(larmflare3, muzzle_flash_large)
		Move(barrelsL[gunIndex[1]], z_axis, 0, 15)
	end
	
	-- Plasma right
	if num == 2 then	
		EmitSfx(rarmflare3, muzzle_smoke_large2)		
		Move(barrelsR[gunIndex[2]], z_axis, -40)		
		EmitSfx(rarmflare3, muzzle_flash_large)
		Move(barrelsR[gunIndex[2]], z_axis, 0, 15)
	end
	
	if gunFixEmit[num] then
		StartThread(BumpGunNum, num, true)
	else
		BumpGunNum(num)
	end
end

function script.BlockShot(num, targetID)
	if num == 1 and lgunpod_not_aimed then
		return true
	end
	if num == 2 and rgunpod_not_aimed then
		return true
	end	
	
	if not targetID then
		return false
	end
	
	if GG.DontFireRadar_CheckBlock(unitID, targetID) then
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
