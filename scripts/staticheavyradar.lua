local base = piece 'base' 
local spinner = piece 'spinner' 
local arm = piece 'arm' 
local ant = piece 'ant' 
local dish = piece 'dish' 
local float1 = piece 'float1' 
local float2 = piece 'float2' 

include "constants.lua"

local smokePiece = { ant, base}

local spGetUnitIsStunned = Spring.GetUnitIsStunned

local SIG_CLOSE = 1
local SIG_OPEN = 2

function script.Create()
	if not GG.Script.onWater(unitID) then
		--Hide(float1)
		--Hide(float2)
	end
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

local function Activate()

	Signal(SIG_CLOSE)
	SetSignalMask(SIG_OPEN)
	
	Sleep(1000)
	Move(dish, y_axis, 30, 7)
	WaitForMove(dish, y_axis)
	Turn(ant, z_axis, math.rad(-100), math.rad(60))
	Turn(arm, z_axis, math.rad(30), math.rad(40))
	Spin(spinner, y_axis, math.rad(20), math.rad(20))
	WaitForTurn(ant, z_axis)
	Spin(dish, y_axis, math.rad(20), math.rad(20))
end

local function Deactivate()
	
	Signal(SIG_OPEN)
	SetSignalMask(SIG_CLOSE)

	if spGetUnitIsStunned(unitID) then
		Spring.UnitScript.StopSpin(dish, y_axis, math.rad(10))
		Spring.UnitScript.StopSpin(spinner, y_axis, math.rad(10))
	else
		Spin(dish, y_axis, math.rad(0), math.rad(20))
		Turn(ant, z_axis, math.rad(0), math.rad(60))
		Turn(arm, z_axis, math.rad(0), math.rad(40))
		WaitForTurn(ant, z_axis)
		Move(dish, y_axis, 0, 7)
		WaitForMove(dish, y_axis)
		Spin(spinner, y_axis, math.rad(0), math.rad(3))
	end
end

function script.Activate()
	StartThread(Activate)
end

function script.Deactivate()
	StartThread(Deactivate)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(arm, SFX.FIRE)
		Explode(ant, SFX.FIRE)
		Explode(base, SFX.FIRE)
		Explode(dish, SFX.EXPLODE)
		Explode(spinner, SFX.EXPLODE)
		return 1
	elseif severity <= 0.50 then
		Explode(arm, SFX.FALL)
		Explode(ant, SFX.FALL)
		Explode(base, SFX.SHATTER)
		Explode(dish, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(spinner, SFX.SHATTER)
		return 1
	else
		Explode(arm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(ant, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(base, SFX.SHATTER)
		Explode(dish, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(spinner, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
