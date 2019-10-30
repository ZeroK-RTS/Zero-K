include "constants.lua"

local spSetUnitShieldState = Spring.SetUnitShieldState

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local pieceMap = Spring.GetUnitPieceMap(unitID)
local HAS_GATTLING = pieceMap.rgattlingflare and true or false
local HAS_BONUS_CANNON = pieceMap.bonuscannonflare and true or false

local torso = piece 'torso'

local rcannon_flare= HAS_GATTLING and piece('rgattlingflare') or piece('rcannon_flare')
local barrels= HAS_GATTLING and piece 'barrels' or nil
local lcannon_flare = HAS_BONUS_CANNON and piece('bonuscannonflare') or piece('lnanoflare')
local lnanoflare = piece 'lnanoflare'
local lnanohand = piece 'lnanohand'
local larm = piece 'larm'
local rarm = piece 'rarm'
local pelvis = piece 'pelvis'
local rupleg = piece 'rupleg'
local lupleg = piece 'lupleg'
local rhand = piece 'rhand'
local lleg = piece 'lleg'
local lfoot = piece 'lfoot'
local rleg = piece 'rleg'
local rfoot = piece 'rfoot'

local smokePiece = {torso}
local nanoPieces = {lnanoflare}
--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local SIG_MOVE = 1
local SIG_LASER = 2
local SIG_DGUN = 4
local SIG_RESTORE_LASER = 8
local SIG_RESTORE_DGUN = 16

local TORSO_SPEED_YAW = math.rad(300)
local ARM_SPEED_PITCH = math.rad(180)

local PACE = 3.4
local BASE_VELOCITY = UnitDefNames.benzcom1.speed or 1.25*30
local VELOCITY = UnitDefs[unitDefID].speed or BASE_VELOCITY
PACE = PACE * VELOCITY/BASE_VELOCITY

local THIGH_FRONT_ANGLE = -math.rad(60)
local THIGH_FRONT_SPEED = math.rad(40) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(40) * PACE
local SHIN_FRONT_ANGLE = math.rad(40)
local SHIN_FRONT_SPEED = math.rad(60) * PACE
local SHIN_BACK_ANGLE = math.rad(15)
local SHIN_BACK_SPEED = math.rad(60) * PACE

local ARM_FRONT_ANGLE = -math.rad(15)
local ARM_FRONT_SPEED = math.rad(14.5) * PACE
local ARM_BACK_ANGLE = math.rad(5)
local ARM_BACK_SPEED = math.rad(14.5) * PACE
local ARM_PERPENDICULAR = math.rad(90)
--[[
local FOREARM_FRONT_ANGLE = -math.rad(15)
local FOREARM_FRONT_SPEED = math.rad(40) * PACE
local FOREARM_BACK_ANGLE = -math.rad(10)
local FOREARM_BACK_SPEED = math.rad(40) * PACE
]]--

local TORSO_ANGLE_MOTION = math.rad(8)
local TORSO_SPEED_MOTION = math.rad(7)*PACE

local RESTORE_DELAY_LASER = 4000
local RESTORE_DELAY_DGUN = 2500

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local isLasering, isDgunning, gunLockOut, shieldOn = false, false, false, true
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
	while true do
		local speedMult = Spring.GetUnitRulesParam(unitID,"totalMoveSpeedChange") or 1
		--left leg up, right leg back
		Turn(lupleg, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED * speedMult)
		Turn(lleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED * speedMult)
		Turn(rupleg, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED * speedMult)
		Turn(rleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED * speedMult)
		if not(isLasering or isDgunning) then
			--left arm back, right arm front
			Turn(torso, y_axis, TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION * speedMult)
--			Turn(larm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
--			Turn(rarm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
		end
		WaitForTurn(rupleg, x_axis)
		Sleep(0)
		
		--right leg up, left leg back
		Turn(lupleg, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED * speedMult)
		Turn(lleg, x_axis, SHIN_BACK_ANGLE, SHIN_BACK_SPEED * speedMult)
		Turn(rupleg, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED * speedMult)
		Turn(rleg, x_axis, SHIN_FRONT_ANGLE, SHIN_FRONT_SPEED * speedMult)
		if not(isLasering or isDgunning) then
			--left arm front, right arm back
			Turn(torso, y_axis, -TORSO_ANGLE_MOTION, TORSO_SPEED_MOTION * speedMult)
--			Turn(larm, x_axis, ARM_FRONT_ANGLE, ARM_FRONT_SPEED)
--			Turn(rarm, x_axis, ARM_BACK_ANGLE, ARM_BACK_SPEED)
		end
		WaitForTurn(lupleg, x_axis)
		Sleep(0)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Move(pelvis, y_axis, 0, 1)
	Turn(rupleg, x_axis, 0, math.rad(200))
	Turn(rleg, x_axis, 0, math.rad(200))
	Turn(lupleg, x_axis, 0, math.rad(200))
	Turn(lleg, x_axis, 0, math.rad(200))
	Turn(torso, y_axis, 0, math.rad(200))
	Turn(larm, x_axis, 0, math.rad(200))
	Turn(rarm, x_axis, 0, math.rad(200))
end


function script.Create()
	Hide(rcannon_flare)
	Hide(lnanoflare)
	
--	Turn(larm, x_axis, math.rad(30))
--	Turn(rarm, x_axis, math.rad(-10))
--	Turn(rhand, x_axis, math.rad(41))
--	Turn(lnanohand, x_axis, math.rad(36))
	
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

local function RestoreLaser()
	Signal(SIG_RESTORE_LASER)
	SetSignalMask(SIG_RESTORE_LASER)
	Sleep(RESTORE_DELAY_LASER)
	isLasering = false
	Turn(larm, x_axis, 0, ARM_SPEED_PITCH)
	Turn(lnanohand, x_axis, 0, ARM_SPEED_PITCH)
	Turn(rarm, x_axis, restorePitch, ARM_SPEED_PITCH)
	Turn(rhand, x_axis, 0, ARM_SPEED_PITCH)
	Turn(torso, y_axis, restoreHeading, TORSO_SPEED_YAW)
	
	if HAS_GATTLING then
		Spin(barrels, z_axis, 100)
		Sleep(200)
		Turn(barrels, z_axis, 0, ARM_SPEED_PITCH)
	end
end

local function RestoreDGun()
	Signal(SIG_RESTORE_DGUN)
	SetSignalMask(SIG_RESTORE_DGUN)
	Sleep(RESTORE_DELAY_DGUN)
	isDgunning = false
	Turn(larm, x_axis, 0, ARM_SPEED_PITCH)
	Turn(lnanohand, x_axis, 0, ARM_SPEED_PITCH)
	Turn(rarm, x_axis, restorePitch, ARM_SPEED_PITCH)
	Turn(rhand, x_axis, 0, ARM_SPEED_PITCH)
	Turn(torso, y_axis, restoreHeading, TORSO_SPEED_YAW)
end

function script.AimWeapon(num, heading, pitch)


	if num >= 5 then
		Signal(SIG_LASER)
		SetSignalMask(SIG_LASER)
		isLasering = true
		Turn(rarm, x_axis, math.rad(0) -pitch, ARM_SPEED_PITCH)
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(rhand, x_axis, math.rad(0), ARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(rarm, x_axis)
		StartThread(RestoreLaser)
		return true
	elseif num == 3 then
		if starBLaunchers[num] then
			pitch = ARM_PERPENDICULAR
		end
		Signal(SIG_DGUN)
		SetSignalMask(SIG_DGUN)
		isDgunning = true
		Turn(larm, x_axis, math.rad(0) -pitch, ARM_SPEED_PITCH)
		Turn(torso, y_axis, heading, TORSO_SPEED_YAW)
		Turn(lnanohand, x_axis, math.rad(0), ARM_SPEED_PITCH)
		WaitForTurn(torso, y_axis)
		WaitForTurn(rarm, x_axis)
		StartThread(RestoreDGun)
		return true
	elseif num == 2 or num == 4 then
		Sleep(100)
		return (shieldOn)
	end
	return false
end

function script.FireWeapon(num)

	if num == 5 then
		EmitSfx(rcannon_flare, 1024)
	elseif num == 3 then
		EmitSfx(lcannon_flare, 1026)
	end

end

function script.Shot(num)
	if num == 5 then
		EmitSfx(rcannon_flare, 1025)
	elseif num == 3 then
		EmitSfx(lcannon_flare, 1027)
	end
end

function script.AimFromWeapon(num)
	return torso
end

function script.QueryWeapon(num)
	if num == 3 then
		return lcannon_flare
	elseif num == 2 or num == 4 then
		return pelvis
	end
	return rcannon_flare
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn(larm, x_axis, 0, ARM_SPEED_PITCH)
	restoreHeading, restorePitch = 0, 0
	StartThread(RestoreDGun)
end

function script.StartBuilding(heading, pitch)
	restoreHeading, restorePitch = heading, pitch
	Turn(larm, x_axis, math.rad(-30) - pitch, ARM_SPEED_PITCH)
	if not (isDgunning) then Turn(torso, y_axis, heading, TORSO_SPEED_YAW) end
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),lnanoflare)
	return lnanoflare
end

function script.Activate()
	--spSetUnitShieldState(unitID, 2, true)
end

function script.Deactivate()
	--spSetUnitShieldState(unitID, 2, false)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, SFX.NONE)
		Explode(larm, SFX.NONE)
		Explode(rarm, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(lupleg, SFX.NONE)
		Explode(rupleg, SFX.NONE)
		Explode(lnanoflare, SFX.NONE)
		Explode(rhand, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(rleg, SFX.NONE)
		return 1
	else
		Explode(torso, SFX.SHATTER)
		Explode(larm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rarm, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.SHATTER)
		Explode(lupleg, SFX.SHATTER)
		Explode(rupleg, SFX.SHATTER)
		Explode(lnanoflare, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rhand, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lleg, SFX.SHATTER)
		Explode(rleg, SFX.SHATTER)
		return 2
	end
end
