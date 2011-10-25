include "constants.lua"

local spSetUnitShieldState = Spring.SetUnitShieldState

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base'
local torso = piece 'torso' 
local uparmR = piece 'upperarmr' 
local uparmL = piece 'upperarml' 
local flareR = piece 'flarer' 
local snout = piece 'snout' 
local pelvis = piece 'pelvis' 
local flareL = piece 'flarel' 
local thighL = piece 'thighl' 
local thighR = piece 'thighr' 
local forearmL = piece 'forearml' 
local forearmR = piece 'forearmr' 
local shinR = piece 'shinr' 
local shinL = piece 'shinl' 

smokePiece = {torso}

local flares = {[0] = flareL, [1] = flareR}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_RESTORE = 8
local SIG_AIM = 2
local SIG_DGUN = 4

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)
local FOREARM_SPEED_PITCH = math.rad(240)

local PACE = 1.75
local BASE_VELOCITY = UnitDefNames.armcom1.speed or 1.375*30
local VELOCITY = UnitDefs[unitDefID].speed or BASE_VELOCITY
PACE = PACE * VELOCITY/BASE_VELOCITY

--[[
local baseHeight = UnitDefNames.armcom1.modelHeight
local height = UnitDefs[unitDefID].modelHeight
if height and baseHeight then
	PACE = PACE * baseHeight/height
	Spring.Echo("Stride length compensation")
end
]]--

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
local FOREARM_FRONT_ANGLE = -math.rad(40)
local FOREARM_FRONT_SPEED = math.rad(45) * PACE
local FOREARM_BACK_ANGLE = math.rad(10)
local FOREARM_BACK_SPEED = math.rad(45) * PACE
--[[
local FOREARM_FRONT_ANGLE = -math.rad(15)
local FOREARM_FRONT_SPEED = math.rad(40) * PACE
local FOREARM_BACK_ANGLE = -math.rad(10)
local FOREARM_BACK_SPEED = math.rad(40) * PACE
]]--

local TORSO_ANGLE_MOTION = math.rad(10)
local TORSO_SPEED_MOTION = math.rad(15)*PACE


local RESTORE_DELAY = 4000

local rightAngle = math.rad(90)

local doubleWep = true
local udef = UnitDefs[unitDefID]
local wepdef = udef.weapons[3].weaponDef
if WeaponDefs[wepdef].name == "noweapon" then
	doubleWep = false
end

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local isMoving, armsFree, shieldOn = false, true, true
local gun_num = 0

local flamers = {}
local wepTable = UnitDefs[unitDefID].weapons
wepTable.n = nil
for index, weapon in pairs(wepTable) do
	local weaponDef = WeaponDefs[weapon.weaponDef]
	if weaponDef.type == "Flame" then
		flamers[index] = true
	end
end
wepTable = nil

--local hasFlamer = (GG.LUPS and GG.LUPS.FlameShot) and GetFlamer()

--------------------------------------------------------------------------------
-- funcs
--------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--left leg up, right leg back
		Turn(thighL, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(shinL, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(thighR, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(shinR, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		if armsFree then
			--left arm back, right arm front
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(uparmL, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(uparmR, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(forearmL, x_axis, FOREARM_BACK_ANGLE, FOREARM_BACK_SPEED)
			Turn(forearmR, x_axis, FOREARM_FRONT_ANGLE, FOREARM_FRONT_SPEED)
		end
		WaitForTurn(thighL, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(thighL, x_axis,  THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(shinL, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(thighR, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(shinR, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		if armsFree then
			--left arm front, right arm back
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(uparmL, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(uparmR, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(forearmL, x_axis, FOREARM_FRONT_ANGLE, FOREARM_FRONT_SPEED)
			Turn(forearmR, x_axis, FOREARM_BACK_ANGLE, FOREARM_BACK_SPEED)			
		end
		WaitForTurn(thighR, x_axis)		
		Sleep(0)
	end
end

local function RestorePose()
	Move(pelvis , y_axis, 0 , 1 )
	Turn(thighR , x_axis, 0, math.rad(200) )
	Turn(shinR , x_axis, 0, math.rad(200) )
	Turn(thighL , x_axis, 0, math.rad(200) )
	Turn(shinL , x_axis, 0, math.rad(200) )
	Turn(uparmL, x_axis, 0, math.rad(120))
	Turn(uparmR, x_axis, 0, math.rad(120))
end

function script.Create()
	Move(flareL, y_axis, -2)
	Move(flareR, y_axis, -2)
	Turn(flareL, x_axis, rightAngle)
	Turn(flareR, x_axis, rightAngle)
	StartThread(SmokeUnit)
end

function script.StartMoving() 
	isMoving = true
	StartThread(Walk)
end

function script.StopMoving() 
	isMoving = false
	Signal(SIG_WALK)
	StartThread(RestorePose)
end

function script.AimFromWeapon(num)
	return torso
end

function script.QueryWeapon(num)
	if not doubleWep then
		return flares[gun_num]
	elseif num == 3 then 
		return flareR 
	elseif num == 2 or num == 4 then
		return torso
	end
	return flareL
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	Turn( uparmL , x_axis, 0, ARM_SPEED_PITCH/2 )
	Turn( uparmR , x_axis, 0, ARM_SPEED_PITCH/2 )
	Turn( forearmL , x_axis, 0, FOREARM_SPEED_PITCH/2 )
	Turn( forearmR , x_axis, 0, FOREARM_SPEED_PITCH/2 )
	Turn(torso, y_axis, 0, TORSO_SPEED_YAW/2)
	armsFree = true
end

function script.AimWeapon(num, heading, pitch)
	if num >= 5 then
		Signal( SIG_AIM)
		SetSignalMask( SIG_AIM)
		armsFree = false
		Turn( torso , y_axis, heading, TORSO_SPEED_YAW )
		Turn( uparmL , x_axis, -pitch, ARM_SPEED_PITCH )
		Turn( forearmL , x_axis, -rightAngle, FOREARM_SPEED_PITCH )
		if not doubleWep then
			Turn( uparmR , x_axis, -pitch, ARM_SPEED_PITCH )
			Turn( forearmR , x_axis, -rightAngle, FOREARM_SPEED_PITCH )
		end
		WaitForTurn(torso, y_axis)
		WaitForTurn(uparmL, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 3 then
		Signal( SIG_DGUN)
		SetSignalMask( SIG_DGUN)
		armsFree = false
		Turn( torso , y_axis, heading, TORSO_SPEED_YAW )
		Turn( uparmL , x_axis, -pitch, ARM_SPEED_PITCH )
		Turn( uparmR , x_axis, -pitch, ARM_SPEED_PITCH )
		Turn( forearmL , x_axis, -rightAngle, FOREARM_SPEED_PITCH )
		Turn( forearmR , x_axis, -rightAngle, FOREARM_SPEED_PITCH )
		WaitForTurn(torso, y_axis)
		WaitForTurn(uparmR, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif num == 2 or num == 4 then
		Sleep(100)
		return (shieldOn)
	end
	return false
end

function script.Activate()
	--spSetUnitShieldState(unitID, true)
end

function script.Deactivate()
	--spSetUnitShieldState(unitID, false)
end

function script.Shot(num)
	if not doubleWep then
		EmitSfx(flares[gun_num], 1025)
		gun_num = 1 - gun_num
	elseif num == 5 then
		EmitSfx(flareL, 1025)
	elseif num == 3 then
		EmitSfx(flareR, 1027)
	end
	if flamers[num] then
		GG.LUPS.FlameShot(unitID, unitDefID, _, num)
	end	
end

function script.FireWeapon(num)
	if not doubleWep then
		EmitSfx(flares[gun_num], 1024)
	elseif num == 5 then
		EmitSfx(flareL, 1024)
	elseif num == 3 then
		EmitSfx(flareR, 1026)
	end
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreAfterDelay)
end

function script.StartBuilding(heading, pitch) 
	Turn( torso , y_axis, heading, ARM_SPEED_PITCH )
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),snout)
	return snout
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, sfxNone)
		Explode(uparmL, sfxNone)
		Explode(uparmR, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(thighL, sfxNone)
		Explode(thighR, sfxNone)
		Explode(forearmL, sfxNone)
		Explode(forearmR, sfxNone)
		Explode(shinR, sfxNone)
		Explode(shinL, sfxNone)
		return 1
	else
		Explode(torso, sfxShatter)
		Explode(uparmL, sfxSmoke + sfxFire + sfxExplode)
		Explode(uparmR, sfxSmoke + sfxFire + sfxExplode)
		Explode(pelvis, sfxShatter)
		Explode(thighL, sfxShatter)
		Explode(thighR, sfxShatter)
		Explode(forearmL, sfxSmoke + sfxFire + sfxExplode)
		Explode(forearmR, sfxSmoke + sfxFire + sfxExplode)
		Explode(shinR, sfxShatter)
		Explode(shinL, sfxShatter)
		return 2
	end
end
