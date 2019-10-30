include "constants.lua"

local spSetUnitShieldState = Spring.SetUnitShieldState

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local torso = piece 'torso'
local ruparm = piece 'ruparm'
local luparm = piece 'luparm'
local rbigflash = piece 'rbigflash'
local nanospray = piece 'nanospray'
local pelvis = piece 'pelvis'
local lfirept = piece 'lfirept'
local head = piece 'head'
local lthigh = piece 'lthigh'
local rthigh = piece 'rthigh'
local nanolath = piece 'nanolath'
local biggun = piece 'biggun'
local rleg = piece 'rleg'
local lleg = piece 'lleg'
local ground = piece 'ground'

local smokePiece = {torso}
local nanoPieces = {nanospray}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_RESTORE = 8
local SIG_LASER = 2
local SIG_DGUN = 4

-- what are these for?
--local ACT_DGUN = 4
--local ACT_LASER = 2

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local PACE = 2
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
local ARM_PERPENDICULAR = math.rad(90)
--[[
local FOREARM_FRONT_ANGLE = -math.rad(15)
local FOREARM_FRONT_SPEED = math.rad(40) * PACE
local FOREARM_BACK_ANGLE = -math.rad(10)
local FOREARM_BACK_SPEED = math.rad(40) * PACE
]]--

local TORSO_ANGLE_MOTION = math.rad(10)
local TORSO_SPEED_MOTION = math.rad(15)*PACE


local RESTORE_DELAY_LASER = 4000
local RESTORE_DELAY_DGUN = 2500

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local isLasering, isDgunning, shieldOn = false, false, true
local restoreHeading, restorePitch = 0, 0

local starBLaunchers = {}
local wepTable = UnitDefs[unitDefID].weapons
wepTable.n = nil
for index, weapon in pairs(wepTable) do
	local weaponDef = WeaponDefs[weapon.weaponDef]
	if weaponDef.type == "StarburstLauncher" then
		starBLaunchers[index] = true
	end
end
wepTable = nil

--------------------------------------------------------------------------------
-- funcs
--------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(nanolath, x_axis, math.rad(-40), ARM_SPEED_PITCH)
	Turn(biggun, x_axis, math.rad(-62.5), ARM_SPEED_PITCH)
	
	Turn(ground, x_axis, math.rad(10), math.rad(30))
	while true do
		--left leg up, right leg back
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		if not(isLasering or isDgunning) then
			--left arm back, right arm front
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(luparm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
			Turn(ruparm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
		end
		WaitForTurn(lthigh, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED)
		if not(isLasering or isDgunning) then
			--left arm front, right arm back
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION)
			Turn(luparm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
			Turn(ruparm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
		end
		WaitForTurn(rthigh, x_axis)
		Sleep(0)
	end
end

local function RestorePose()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	Turn(ground, x_axis, 0, math.rad(60))
	Move(pelvis, y_axis, 0, 1)
	Turn(rthigh, x_axis, 0, math.rad(200))
	Turn(rleg, x_axis, 0, math.rad(200))
	Turn(lthigh, x_axis, 0, math.rad(200))
	Turn(lleg, x_axis, 0, math.rad(200))
	Turn(luparm, x_axis, 0, math.rad(120))
	Turn(ruparm, x_axis, 0, math.rad(120))
end

function script.Create()
	Hide(ground)
	Hide(rbigflash)
	Hide(lfirept)
	Hide(nanospray)
	Turn(lfirept, x_axis, math.rad(145))
	Turn(rbigflash, x_axis, math.rad(145))
	
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestorePose)
end

function script.AimFromWeapon(num)
	return torso
end

function script.QueryWeapon(num)
	if num == 3 then
		return rbigflash
	elseif num == 2 or num == 4 then
		return torso
	end
	return lfirept
end

local function RestoreLaser()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY_LASER)
	isLasering = false
	isDgunning = false
	Turn(luparm, x_axis, restorePitch, ARM_SPEED_PITCH)
	if (not isDgunning) then Turn(torso, y_axis, restoreHeading, TORSO_SPEED_YAW) end
end

local function RestoreDgun()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY_DGUN)
	isLasering = false
	isDgunning = false
	Turn(ruparm, x_axis, 0, ARM_SPEED_PITCH)
	if (not isLasering) then Turn(torso, y_axis, restoreHeading, TORSO_SPEED_YAW) end
end

function script.AimWeapon(num, heading, pitch)
	if num >= 5 then
		Signal(SIG_LASER)
		SetSignalMask(SIG_LASER)
		isLasering = true
		if not isDgunning then
			Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		end
		Turn(nanolath, x_axis, math.rad(-40), ARM_SPEED_PITCH)
		Turn(luparm, x_axis, math.rad(-50) - pitch, ARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(luparm, x_axis)
		StartThread(RestoreLaser)
		return true
	elseif num == 3 then
		if starBLaunchers[num] then
			pitch = ARM_PERPENDICULAR
		end
		Signal(SIG_DGUN)
		SetSignalMask(SIG_DGUN)
		isDgunning = true
		Turn(biggun, x_axis, math.rad(-62.5), ARM_SPEED_PITCH)
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(ruparm, x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(ruparm, x_axis)
		StartThread(RestoreDgun)
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

function script.FireWeapon(num)
	if num == 5 then
		EmitSfx(lfirept, 1024)
	elseif num == 3 then
		EmitSfx(rbigflash, 1026)
	end
end

function script.Shot(num)
	if num == 5 then
		EmitSfx(lfirept, 1025)
	elseif num == 3 then
		EmitSfx(rbigflash, 1027)
	end
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	restoreHeading, restorePitch = 0, 0
	StartThread(RestoreLaser)
end

function script.StartBuilding(heading, pitch)
	if not isLasering then
		Turn(luparm, x_axis, math.rad(-60) - pitch, ARM_SPEED_PITCH)
		if not (isDgunning) then Turn(torso, y_axis, heading, TORSO_SPEED_YAW) end
	end
	restoreHeading, restorePitch = heading, pitch
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanospray)
	return nanospray
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, SFX.NONE)
		Explode(luparm, SFX.NONE)
		Explode(ruparm, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(nanolath, SFX.NONE)
		Explode(biggun, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(lleg, SFX.NONE)
		return 1
	else
		Explode(torso, SFX.SHATTER)
		Explode(luparm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(ruparm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.SHATTER)
		Explode(lthigh, SFX.SHATTER)
		Explode(rthigh, SFX.SHATTER)
		Explode(nanolath, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(biggun, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rleg, SFX.SHATTER)
		Explode(lleg, SFX.SHATTER)
		return 2
	end
end
