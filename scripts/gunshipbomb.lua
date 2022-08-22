
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
	
	--Spring.UnitScript.SetUnitValue(firestate, 0)
	Turn(base, side, -RIGHT_ANGLE, 5)
	Turn(l_wing, side, RIGHT_ANGLE, 5)
	Turn(r_wing, side, RIGHT_ANGLE, 5)
	Move(base, up, 8, 8)
	--Move(base, forward, -4, 5)
end

local function UnBurrow()
	Signal(SIG_BURROW)
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

local function BurrowThread()
	--[[ Ideally this would use events instead of polling,
	     but gunships don't receive Skidding events so hurling
	     it via gravguns would let it keep cloaked.

	     Note that the animation is still tied to events because
	     they produce better looks (transitions happen in flight). ]]
	while true do
		local _, _, _, v = Spring.GetUnitVelocity(unitID)
		if v < 0.02 then
			Spring.SetUnitCloak(unitID, 2)
			Spring.SetUnitStealth(unitID, true)
		else
			Spring.SetUnitCloak(unitID, 0)
			Spring.SetUnitStealth(unitID, false)
		end

		Sleep(200)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(BurrowThread)
	if not Spring.GetUnitIsStunned(unitID) then
		Burrow()
	end
end

function script.StartMoving()
	StartThread(UnBurrow)
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
