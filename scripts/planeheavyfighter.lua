include "constants.lua"

--pieces
local base = piece "base"
local wingR, wingL, wingtipR, wingtipL = piece("wingr", "wingl", "wingtip1", "wingtip2")
local engineR, engineL, thrust1, thrust2, thrust3 = piece("jetr", "jetl", "thrust1", "thrust2", "thrust3")
local missR, missL = piece("m1", "m2")

local smokePiece = {base, engineL, engineR}
local LOS_ACCESS = {inlos = true}

--constants

--variables
local gun = false
local weaponBlocked = false

local RESTORE_DELAY = 150
local FIRE_SLOWDOWN = tonumber(UnitDef.customParams.combat_slowdown)

local ROTATION_FACTOR = tonumber(UnitDef.customParams.boost_turn_mult)
local ROTATION_DURATION = tonumber(UnitDef.customParams.boost_duration) / 30
local ROTATION_RELOAD_PER_FRAME = 1 / tonumber(UnitDef.customParams.specialreloadtime)

local maxElevator = UnitDefs[unitDefID].maxElevator
local maxAileron = UnitDefs[unitDefID].maxAileron
local maxPitch = UnitDefs[unitDefID].maxPitch
local maxBank = UnitDefs[unitDefID].maxBank
local turnRadius = UnitDefs[unitDefID].turnRadius

--signals
local SIG_RESTORE = 2

----------------------------------------------------------
----------------------------------------------------------

local CMD_ONECLICK_WEAPON = Spring.Utilities.CMD.ONECLICK_WEAPON

local function RetreatThread()
	Sleep(100)
	local specialReloadState = Spring.GetUnitRulesParam(unitID,"specialReloadFrame")
	if (not specialReloadState or (specialReloadState <= Spring.GetGameFrame())) then
		Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD_ONECLICK_WEAPON, CMD.OPT_INTERNAL,}, CMD.OPT_ALT)
	end
end

function RetreatFunction()
	StartThread(RetreatThread)
end

----------------------------------------------------------
----------------------------------------------------------

local function GetState()
	local state = Spring.GetUnitStates(unitID)
	return state and state.active
end

function script.StartMoving()
	Turn(engineL, z_axis, -1.57, 1)
	Turn(engineR, z_axis, 1.57, 1)
	Turn(engineL, y_axis, -1.57, 1)
	Turn(engineR, y_axis, 1.57, 1)
	Turn(engineL, x_axis, 0, 1)
	Turn(engineR, x_axis, 0, 1)
end

function script.StopMoving()
	Turn(engineL, z_axis, 0, 1)
	Turn(engineR, z_axis, 0, 1)
	Turn(engineL, y_axis, 0, 1)
	Turn(engineR, y_axis, 0, 1)
	Turn(engineL, x_axis, 0, 1)
	Turn(engineR, x_axis, 0, 1)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	
	Sleep(RESTORE_DELAY)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)

	-- Don't ask me why this must be called twice for planes, Spring is crazy
	GG.UpdateUnitAttributes(unitID)
	GG.UpdateUnitAttributes(unitID)
	
	if GetState() then
		script.StartMoving()
	else
		script.StopMoving()
	end
end

----------------------------------------------------------
----------------------------------------------------------

local function RotationBoostThread()
	Signal(SIG_RESTORE)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxAileron", maxAileron * ROTATION_FACTOR)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxElevator", maxElevator * ROTATION_FACTOR)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxPitch", 0.6)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxBank", 1.2)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxBank", turnRadius / 2)
	
	Sleep(1000 * ROTATION_DURATION)
	
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxAileron", maxAileron)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxElevator", maxElevator)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxPitch", maxPitch)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxBank", maxBank)
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxBank", turnRadius)
	
	weaponBlocked = false
	StartThread(RestoreAfterDelay)
	
	local reloadRemaining = 1 -- Synced to specialReloadRemaining because nothing else changes it.
	while reloadRemaining > 0 do
		Sleep(33)
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		if not stunnedOrInbuild then
			local reloadSpeedMult = (GG.att_ReloadChange[unitID] or 1)
			if reloadSpeedMult > 0 then
				reloadRemaining = reloadRemaining - ROTATION_RELOAD_PER_FRAME*reloadSpeedMult
				if reloadRemaining < 0 then
					reloadRemaining = 0
				end
				Spring.SetUnitRulesParam(unitID, "specialReloadRemaining", reloadRemaining, IN_LOS)
			end
		end
	end
end

function RotationBoost()
	if (Spring.MoveCtrl.GetTag(unitID) ~= nil) then
		return false
	end
	weaponBlocked = true
	Spring.SetUnitRulesParam(unitID, "specialReloadRemaining", 1, LOS_ACCESS)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
	
	Turn(engineL, z_axis, 3.14, 8)
	Turn(engineR, z_axis, 3.14, 8)
	Turn(engineL, y_axis, -2.82, 6)
	Turn(engineR, y_axis, 2.82, 6)
	Turn(engineL, x_axis, 0.42, 5)
	Turn(engineR, x_axis, 0.42, 5)

	StartThread(RotationBoostThread)
end

----------------------------------------------------------
----------------------------------------------------------

function script.Create()
	Turn(thrust1, x_axis, -math.rad(90), 1)
	Turn(thrust2, x_axis, -math.rad(90), 1)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.QueryWeapon(num)
	if gun then
		return missR
	else
		return missL
	end
end

function script.AimFromWeapon(num)
	return base
end

function script.AimWeapon(num, heading, pitch)
	return not (GetUnitValue(COB.CRASHING) == 1)
end

function script.EndBurst(num)
	gun = not gun
end

function script.BlockShot(num)
	if GetUnitValue(GG.Script.CRASHING) == 1 or weaponBlocked then
		return true
	else
		if Spring.GetUnitRulesParam(unitID, "selfMoveSpeedChange") ~= FIRE_SLOWDOWN then
			Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", FIRE_SLOWDOWN)
			Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1/FIRE_SLOWDOWN)
			GG.UpdateUnitAttributes(unitID)
		end
		StartThread(RestoreAfterDelay)
		return false
	end
end

function OnLoadGame()
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.25 then
		Explode(base, SFX.NONE)
		Explode(wingL, SFX.NONE)
		Explode(wingR, SFX.NONE)
		return 1
	elseif severity < 0.5 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(base, SFX.NONE)
		Explode(engineL, SFX.SMOKE)
		Explode(engineR, SFX.SMOKE)
		Explode(wingL, SFX.NONE)
		Explode(wingR, SFX.NONE)
		return 1
	elseif severity < 0.75 then
		Explode(engineL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(engineR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wingL, SFX.FALL + SFX.SMOKE)
		Explode(wingR, SFX.FALL + SFX.SMOKE)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(engineL, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(engineR, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(wingL, SFX.SMOKE + SFX.EXPLODE)
		Explode(wingR, SFX.SMOKE + SFX.EXPLODE)
		return 2
	end
end
