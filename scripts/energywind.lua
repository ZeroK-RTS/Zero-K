local base, fan, cradle, flaot = piece('base', 'fan', 'cradle', 'flaot')
include "constants.lua"

local baseDirection

local smokePiece = {base}

local hpi = math.pi*0.5

local UPDATE_PERIOD = 1000
local BUILD_PERIOD = 500

local turnSpeed = math.rad(20)

local isWind, baseWind, rangeWind

function BobTidal()
	baseDirection = baseDirection + math.random(0,math.rad(2))
	while true do
		Turn(cradle, y_axis, baseDirection, math.rad(1))
		
		Move(cradle, x_axis, math.random(-2,2), 0.2)
		Move(cradle, y_axis, math.random(-0.5,0.5) - 51, 0.05)
		Move(cradle, z_axis, math.random(-2,2), 0.2)
		Sleep(1000)
		
		if GG.Wind_SpinDisabled then
			StopSpin(fan, z_axis)
			return
		end
	end
end

local oldWindStrength, oldWindHeading
function SpinWind()
	while true do
		if select(5, Spring.GetUnitHealth(unitID)) < 1 then
			oldWindStrength = nil
			StopSpin(fan, z_axis)
			Sleep(BUILD_PERIOD)
		else
			if GG.WindStrength and ((oldWindStrength ~= GG.WindStrength) or (oldWindHeading ~= GG.WindHeading)) then
				oldWindStrength, oldWindHeading = GG.WindStrength, GG.WindHeading
				local st = baseWind + (GG.WindStrength or 0)*rangeWind
				Spin(fan, z_axis, -st*(0.94 + 0.08*math.random()))
				Turn(cradle, y_axis, GG.WindHeading - baseDirection + math.pi, turnSpeed)
			end
			Sleep(UPDATE_PERIOD + 200*math.random())
		end
		
		if GG.Wind_SpinDisabled then
			StopSpin(fan, z_axis)
			return
		end
	end
end

function InitializeWind()
	isWind, baseWind, rangeWind = GG.SetupWindmill(unitID)
	if isWind then
		StartThread(SpinWind)
	else
		StartThread(BobTidal)
		Hide(base)
		Hide(flaot)
		Move(cradle, y_axis, -51)
		Turn(fan, x_axis, math.rad(90))
		Move(fan, z_axis, 9)
		Move(fan, y_axis, -5)
		--[[ diagonal down, needs teamcolour
		Move(cradle, y_axis, -41)
		Move(cradle, z_axis, -10)
		Turn(cradle, z_axis, math.pi)
		Turn(cradle, x_axis, math.rad(-15))
		Turn(fan, x_axis, math.rad(50))
		Move(fan, x_axis, 0)
		Move(fan, z_axis, 14)
		Move(fan, y_axis, 18)
		--]]
		Spin(fan, z_axis, math.rad(30))
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	baseDirection = math.random(0,GG.Script.tau)
	Turn(base, y_axis, baseDirection)
	baseDirection = baseDirection + hpi * Spring.GetUnitBuildFacing(unitID)
	InitializeWind()
end

local function CreateTidalWreck()
	local x,y,z = Spring.GetUnitPosition(unitID)
	local heading = Spring.GetUnitHeading(unitID)
	local team = Spring.GetUnitTeam(unitID)
	local featureID = Spring.CreateFeature("energywind_deadwater", x, y, z, heading + baseDirection*65536/GG.Script.tau, team)
	Spring.SetFeatureResurrect(featureID, "energywind")
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if isWind then
		if severity <= 0.25 then
			Explode(base, SFX.SHATTER)
			Explode(fan, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
			Explode(base, SFX.SHATTER)
			return 1
		elseif severity <= 0.5 then
			Explode(base, SFX.SHATTER)
			Explode(fan, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
			Explode(cradle, SFX.SHATTER)
			return 1
		else
			Explode(base, SFX.SHATTER)
			Explode(fan, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
			Explode(cradle, SFX.SMOKE)
			return 2
		end
	else
		if severity <= 0.25 then
			--Explode(fan, SFX.SMOKE)
			--Explode(cradle, SFX.FIRE)
			CreateTidalWreck()
			return 3
		elseif severity <= 0.5 then
			--Explode(fan, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
			--Explode(cradle, SFX.SMOKE)
			CreateTidalWreck()
			return 3
		else
			Explode(fan, SFX.SHATTER)
			Explode(cradle, SFX.SHATTER)
			return 2
		end
	end
end
