local base = piece 'base'
local body = piece 'body'
local jet = piece 'jet'
local wingtipl = piece 'wingtipl'
local wingtipr = piece 'wingtipr'

local smokePiece = {body, jet}

include "constants.lua"
include "bombers.lua"
include "fixedwingTakeOff.lua"

local SIG_TAKEOFF = 1
local takeoffHeight = UnitDefNames["bomberriot"].wantedHeight

local function Lights()
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do
		Sleep(400)
	end
	while true do
		EmitSfx(wingtipl, 1025)
		EmitSfx(wingtipr, 1026)
		Sleep(2000)
	end
end

function script.StopMoving()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

function script.Create()
	SetInitialBomberSettings()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	--StartThread(Lights)
end

function script.AimWeapon(num)
	return true
end

function script.QueryWeapon(num)
	return base
end

function script.BlockShot(num)
	return RearmBlockShot()
end

function script.FireWeapon(num)
	SetUnarmedAI()
	Sleep(400)
	Reload()
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(body, SFX.NONE)
		Explode(jet, SFX.NONE)
		return 1
	elseif severity <= .50 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(body, SFX.NONE)
		Explode(jet, SFX.SHATTER)
		return 1
	elseif severity <= .75 then
		Explode(body, SFX.SHATTER)
		Explode(jet, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	else
		Explode(body, SFX.SHATTER)
		Explode(jet, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
