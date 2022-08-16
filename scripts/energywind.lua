local base, fan, cradle, flaot = piece('base', 'fan', 'cradle', 'flaot')
include "constants.lua"

local baseDirection

local smokePiece = {base}

local hpi = math.pi*0.5

local UPDATE_PERIOD = 1000
local BUILD_PERIOD = 500

local turnSpeed = math.rad(20)
local waterFanSpin = math.rad(30)

local isWind, baseWind, rangeWind

local rand = math.random
local function BobTidal()
	-- Body movement models being somewhat free-floating upon the waves
	local bodySpinSpeed	= 0
	while true do
		bodySpinSpeed = 0.99*bodySpinSpeed + (rand() - 0.5) * 0.016
		Spin(cradle, y_axis, bodySpinSpeed)
		Spin(fan, z_axis, waterFanSpin + bodySpinSpeed)

		Move(cradle, x_axis, rand(-2,2), 0.3)
		Move(cradle, y_axis, rand(-2,2) * 0.5 - 51, 0.2)
		Move(cradle, z_axis, rand(-2,2), 0.3)
		Sleep(1000)

		if GG.Wind_SpinDisabled then
			StopSpin(fan, z_axis)
			StopSpin(cradle, y_axis)
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
				Spin(fan, z_axis, -st*(0.94 + 0.08*rand()))
				Turn(cradle, y_axis, GG.WindHeading - baseDirection + math.pi, turnSpeed)
			end
			Sleep(UPDATE_PERIOD + 200*rand())
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
		Turn(fan, x_axis, hpi)
		Move(fan, z_axis, 9)
		Move(fan, y_axis, -5)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	baseDirection = math.random() * GG.Script.tau
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
