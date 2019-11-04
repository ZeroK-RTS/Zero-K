include "constants.lua"

local dyncomm = include('dynamicCommander.lua')
_G.dyncomm = dyncomm

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
local shieldEmit = piece 'shieldemit'

local smokePiece = {torso}
local nanoPieces = {snout}

local jets = {piece 'jet1', piece 'jet2', piece 'jet3', piece 'jet4'}

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
local BASE_VELOCITY = UnitDefNames.cremcom1.speed or 1.375*30
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
local ARM_PERPENDICULAR = math.rad(90)
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

--[[
local doubleWep = true
local udef = UnitDefs[unitDefID]
local wepdef = udef.weapons[3].weaponDef
if WeaponDefs[wepdef].name == "noweapon" then
	doubleWep = false
end
]]
--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local armsFree = true
local restoreHeading = 0
local gun_num = 0

local starBLaunchers = {}
local wepTable = UnitDefs[unitDefID].weapons
wepTable.n = nil
for index, weapon in pairs(wepTable) do
	local weaponDef = WeaponDefs[weapon.weaponDef]
	if weaponDef.type == "StarburstLauncher" then
		starBLaunchers[index] = true
		--Spring.Echo("sbl found")
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
		local speedMult = (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)*dyncomm.GetPace()
		
		--left leg up, right leg back
		Turn(thighL, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED * speedMult)
		Turn(shinL, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED * speedMult)
		Turn(thighR, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED * speedMult)
		Turn(shinR, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED * speedMult)
		if armsFree then
			--left arm back, right arm front
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION * speedMult)
			Turn(uparmL, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED * speedMult)
			Turn(uparmR, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED * speedMult)
			Turn(forearmL, x_axis, FOREARM_BACK_ANGLE, FOREARM_BACK_SPEED * speedMult)
			Turn(forearmR, x_axis, FOREARM_FRONT_ANGLE, FOREARM_FRONT_SPEED * speedMult)
		end
		WaitForTurn(thighL, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(thighL, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED * speedMult)
		Turn(shinL, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED * speedMult)
		Turn(thighR, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED * speedMult)
		Turn(shinR, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED * speedMult)
		if armsFree then
			--left arm front, right arm back
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION * speedMult)
			Turn(uparmL, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED * speedMult)
			Turn(uparmR, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED * speedMult)
			Turn(forearmL, x_axis, FOREARM_FRONT_ANGLE, FOREARM_FRONT_SPEED * speedMult)
			Turn(forearmR, x_axis, FOREARM_BACK_ANGLE, FOREARM_BACK_SPEED * speedMult)
		end
		WaitForTurn(thighR, x_axis)
		Sleep(0)
	end
end

local function RestorePose()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Move(pelvis, y_axis, 0, 1)
	Turn(thighR, x_axis, 0, math.rad(200))
	Turn(shinR, x_axis, 0, math.rad(200))
	Turn(thighL, x_axis, 0, math.rad(200))
	Turn(shinL, x_axis, 0, math.rad(200))
	Turn(uparmL, x_axis, 0, math.rad(120))
	Turn(uparmR, x_axis, 0, math.rad(120))
end

function script.Create()
	Move(flareL, y_axis, -2)
	Move(flareR, y_axis, -2)
	Turn(flareL, x_axis, rightAngle)
	Turn(flareR, x_axis, rightAngle)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestorePose)
end

function beginJump()
	script.StopMoving()
	GG.PokeDecloakUnit(unitID, 50)
end

function jumping()
	GG.PokeDecloakUnit(unitID, 50)
	for i=1,4 do
		EmitSfx(jets[i], 1028)
	end
end

function halfJump()
end

function endJump()
	script.StopMoving()
	EmitSfx(base, 1029)
end

function script.AimFromWeapon(num)
	if dyncomm.IsManualFire(num) then
		if dyncomm.GetWeapon(num) == 1 then
			return flareL
		elseif dyncomm.GetWeapon(num) == 2 then
			return flareR
		end
	end
	return torso
end

function script.QueryWeapon(num)
	if dyncomm.GetWeapon(num) == 1 then
		return flareL
	elseif dyncomm.GetWeapon(num) == 2 then
		return flareR
	end
	return shieldEmit
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	Turn(uparmL, x_axis, 0, ARM_SPEED_PITCH/2)
	Turn(uparmR, x_axis, 0, ARM_SPEED_PITCH/2)
	Turn(forearmL, x_axis, 0, FOREARM_SPEED_PITCH/2)
	Turn(forearmR, x_axis, 0, FOREARM_SPEED_PITCH/2)
	Turn(torso, y_axis, restoreHeading, TORSO_SPEED_YAW/2)
	WaitForTurn(torso, y_axis)
	armsFree = true
end

function script.AimWeapon(num, heading, pitch)
	local weaponNum = dyncomm.GetWeapon(num)
	
	if weaponNum == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		armsFree = false
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(uparmL, x_axis, -pitch, ARM_SPEED_PITCH)
		Turn(forearmL, x_axis, -rightAngle, FOREARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(uparmL, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif weaponNum == 2 then
		if starBLaunchers[num] then
			pitch = ARM_PERPENDICULAR
		end
		Signal(SIG_DGUN)
		SetSignalMask(SIG_DGUN)
		armsFree = false
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(uparmR, x_axis, -pitch, ARM_SPEED_PITCH)
		Turn(forearmR, x_axis, -rightAngle, FOREARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(uparmR, x_axis)
		WaitForTurn(forearmR, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif weaponNum == 3 then
		return true
	end
	return false
end

function script.Activate()
end

function script.Deactivate()
end

function script.Shot(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponShotSfx(flareL, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponShotSfx(flareR, num)
	end
end
	
function script.FireWeapon(num)
	local weaponNum = dyncomm.GetWeapon(num)
	if weaponNum == 1 then
		dyncomm.EmitWeaponFireSfx(flareL, num)
	elseif weaponNum == 2 then
		dyncomm.EmitWeaponFireSfx(flareR, num)
	end
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	restoreHeading= 0
	StartThread(RestoreAfterDelay)
end

function script.StartBuilding(heading, pitch)
	restoreHeading = heading
	Turn(torso, y_axis, heading, ARM_SPEED_PITCH)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),snout)
	return snout
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, SFX.NONE)
		Explode(uparmL, SFX.NONE)
		Explode(uparmR, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(thighL, SFX.NONE)
		Explode(thighR, SFX.NONE)
		Explode(forearmL, SFX.NONE)
		Explode(forearmR, SFX.NONE)
		Explode(shinR, SFX.NONE)
		Explode(shinL, SFX.NONE)
		return 1
	else
		Explode(torso, SFX.SHATTER)
		Explode(uparmL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(uparmR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.SHATTER)
		Explode(thighL, SFX.SHATTER)
		Explode(thighR, SFX.SHATTER)
		Explode(forearmL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(forearmR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(shinR, SFX.SHATTER)
		Explode(shinL, SFX.SHATTER)
		return 2
	end
end
