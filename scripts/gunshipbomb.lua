
-- by Chris Mackey
include "constants.lua"

--pieces 
local base = piece "base"
local missile = piece "missile"
local l_wing = piece "l_wing"
local l_fan = piece "l_fan"
local r_wing = piece "r_wing"
local r_fan = piece "r_fan"

local side = 1
local forward = 3
local up = 2

local RIGHT_ANGLE = math.rad(90)

local smokePiece = { base, l_wing, r_wing }
local burrowed = false

local SIG_BURROW = 1

local function Burrow()
	Signal(SIG_BURROW)
	SetSignalMask(SIG_BURROW)
	
	local x,y,z = Spring.GetUnitPosition(unitID)
	local height = Spring.GetGroundHeight(x,z)
	
	while height + 35 < y do
		Sleep(500)
		x,y,z = Spring.GetUnitPosition(unitID)
		height = Spring.GetGroundHeight(x,z)
	end
	
	burrowed = true
	
	--Spring.UnitScript.SetUnitValue(firestate, 0)
	Turn(base, side, -RIGHT_ANGLE, 5)
	Turn(l_wing, side, RIGHT_ANGLE, 5)
	Turn(r_wing, side, RIGHT_ANGLE, 5)
	Move(base, up, 8, 8)
	--Move(base, forward, -4, 5)
end

local function UnBurrow()
	Signal(SIG_BURROW)
	burrowed = false
	Spring.SetUnitCloak(unitID, 0)
	Spring.SetUnitStealth(unitID, false)
	--Spring.UnitScript.SetUnitValue(firestate, 2)
	Turn(base, side, 0, 5)
	Turn(l_wing, side,0, 5)
	Turn(r_wing, side, 0, 5)
	Move(base, up, 0, 10)
	--Move(base, forward, 0, 5)
end

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	if not Spring.GetUnitIsStunned(unitID) then
		Spring.SetUnitCloak(unitID, 2)
		Spring.SetUnitStealth(unitID, true)
		Burrow()
	end
end

function script.Activate()
	StartThread(UnBurrow)
end

function script.Deactivate()
	Spring.SetUnitCloak(unitID, 2)
	Spring.SetUnitStealth(unitID, true)
end

function script.StopMoving()
	StartThread(Burrow)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.EXPLODE + SFX.FIRE + SFX.SMOKE)
	Explode(l_wing, SFX.EXPLODE)
	Explode(r_wing, SFX.EXPLODE)
	
	Explode(missile, SFX.SHATTER)
	
	--Explode(l_fan, SFX.EXPLODE)
	--Explode(r_fan, SFX.EXPLODE)
	
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
