include "constants.lua"

--pieces
local base, flare1, flare2, nozzle1, nozzle2, missile, rgun, lgun, rwing, lwing, rjet, ljet, body
	= piece("base", "flare1", "flare2", "nozzle1", "nozzle2", "missile", "rgun", "lgun", "rwing", "lwing", "rjet", "ljet", "body")

local smokePiece = {base, rwing, lwing}

--variables
local shotCycle = 0
local flare = {
	[0] = flare1,
	[1] = flare2,
}

local SPEEDUP_FACTOR = tonumber (UnitDef.customParams.boost_speed_mult)
local BOOSTUP_FACTOR = tonumber (UnitDef.customParams.boost_accel_mult)
local SPEEDUP_DURATION = tonumber (UnitDef.customParams.boost_duration)

----------------------------------------------------------

local CMD_ONECLICK_WEAPON = Spring.Utilities.CMD.ONECLICK_WEAPON

local function RetreatThread()
	Sleep(800)
	local specialReloadState = Spring.GetUnitRulesParam(unitID,"specialReloadFrame")
	if (not specialReloadState or (specialReloadState <= Spring.GetGameFrame())) then
		Spring.GiveOrderToUnit(unitID, CMD.INSERT, {0, CMD_ONECLICK_WEAPON, CMD.OPT_INTERNAL,}, CMD.OPT_ALT)
	end
end

function RetreatFunction()
	StartThread(RetreatThread)
end

----------------------------------------------------------

function SprintThread()
	for i=1, SPEEDUP_DURATION do
		EmitSfx(ljet, 1027)
		EmitSfx(rjet, 1027)
		Sleep(33)
	end
	while (Spring.MoveCtrl.GetTag(unitID) ~= nil) do --is true when unit_refuel_pad_handler.lua is MoveCtrl-ing unit, wait until MoveCtrl disabled before restore speed.
		Sleep(33)
	end
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	-- Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxAcc", 0.5)
	GG.UpdateUnitAttributes(unitID)
	
	Turn(rwing, y_axis, 0, math.rad(100))
	Turn(lwing, y_axis, 0, math.rad(100))
end

function Sprint()
	Turn(rwing, y_axis, math.rad(65), math.rad(300))
	Turn(lwing, y_axis, math.rad(-65), math.rad(300))

	StartThread(SprintThread)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", SPEEDUP_FACTOR)
	-- Spring.MoveCtrl.SetAirMoveTypeData(unitID, "maxAcc", 3)
	GG.UpdateUnitAttributes(unitID)
end

function OnLoadGame()
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

----------------------------------------------------------

local WING_DISTANCE = 8

local function activate()
	Move(rwing, x_axis, 0, 10)
	Move(lwing, x_axis, 0, 10)
end

local function deactivate()
	Move(rwing, x_axis, WING_DISTANCE, 10)
	Move(lwing, x_axis, -WING_DISTANCE, 10)
	Turn(rwing, y_axis, 0, math.rad(30))
	Turn(lwing, y_axis, 0, math.rad(30))
end

function script.Create()
	Move(rwing, x_axis, WING_DISTANCE)
	Move(lwing, x_axis, -WING_DISTANCE)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.StartMoving()
	activate()
end

function script.StopMoving()
	deactivate()
end

function script.QueryWeapon(num)
	if num == 1 then
		return flare[shotCycle]
	elseif num == 2 then
		return flare2
	end
end

function script.AimFromWeapon(num)
	return base
end

function script.AimWeapon(num, heading, pitch)
	return not (GetUnitValue(COB.CRASHING) == 1)
end

function script.FireWeapon(num)
	if num == 1 then
		shotCycle = 1 - shotCycle
		EmitSfx(flare[shotCycle], GG.Script.UNIT_SFX3)
	elseif num == 2 then
		EmitSfx(flare2, GG.Script.UNIT_SFX3)
	elseif num == 3 then
		EmitSfx(missile, GG.Script.UNIT_SFX2)
	end
end

function script.BlockShot(num, targetID)
	if (GetUnitValue(COB.CRASHING) == 1) then
		return true
	end
	if num == 2 then
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 133, 35)
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth)
	if severity < 0.5 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(base, SFX.NONE)
		Explode(rwing, SFX.NONE)
		Explode(lwing, SFX.NONE)
		Explode(rjet, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.SHATTER + SFX.EXPLODE_ON_HIT)
		Explode(ljet, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.SHATTER + SFX.EXPLODE_ON_HIT)
		return 1
	else
		Explode(base, SFX.NONE)
		Explode(rwing, SFX.NONE)
		Explode(lwing, SFX.NONE)
		Explode(rjet, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.SHATTER + SFX.EXPLODE_ON_HIT)
		Explode(ljet, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE + SFX.SHATTER + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
