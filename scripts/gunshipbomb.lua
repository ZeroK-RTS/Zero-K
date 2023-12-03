
-- by Chris Mackey
include "constants.lua"

--pieces
local base = piece "base"
local missile = piece "missile"
local l_wing = piece "l_wing"
local l_fan = piece "l_fan"
local r_wing = piece "r_wing"
local r_fan = piece "r_fan"

local smokePiece = { base, l_wing, r_wing }

local SIG_BURROW = 1
local burrowed = false

local bombDefID = WeaponDefNames["gunshipbomb_gunshipbomb_bomb"].id

local function UnBurrow()
	Signal(SIG_BURROW)
	burrowed = false
	Turn(base, x_axis, 0, 5)
	Turn(l_wing, x_axis, 0, 5)
	Turn(r_wing, x_axis, 0, 5)
	Move(base, y_axis, 0, 10)
end

local function Burrow()
	Signal(SIG_BURROW)
	SetSignalMask(SIG_BURROW)
	
	local x,y,z = Spring.GetUnitPosition(unitID)
	local height = math.max(Spring.GetGroundHeight(x,z) or 0, 0)
	
	while height + 35 < y do
		Sleep(500)
		x,y,z = Spring.GetUnitPosition(unitID)
		height = math.max(Spring.GetGroundHeight(x,z) or 0, 0)
	end
	burrowed = true

	Turn(base, x_axis, math.rad(-90), 5)
	Turn(l_wing, x_axis, math.rad(90), 5)
	Turn(r_wing, x_axis, math.rad(90), 5)
	Move(base, y_axis, 8, 16)
	Sleep(600)
	
	local x,y,z, speed = Spring.GetUnitVelocity(unitID)
	if speed > 0.01 then
		UnBurrow()
	end
end

local function ThrowBomb()
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	if not vz then
		return
	end
	local px, py, pz = Spring.GetUnitPosition(unitID)
	local params = {
		pos = {px, py, pz},
		speed = {vx, vy + 0.3, vz},
		team = Spring.GetUnitTeam(unitID),
		owner = unitID,
		gravity = -0.12,
	}
	Spring.SpawnProjectile(bombDefID, params)
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
		if burrowed and (select(4, Spring.GetUnitVelocity(unitID)) or 0.02) < 0.02 then
			GG.SetWantedCloaked(unitID, 1)
		else
			GG.SetWantedCloaked(unitID, 0)
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

function script.Deactivate()
	StartThread(Burrow)
end

function script.StopMoving()
	StartThread(Burrow)
end

function script.Killed(recentDamage, maxHealth)
	ThrowBomb()
	Explode(base, SFX.FALL + SFX.EXPLODE + SFX.FIRE + SFX.SMOKE)
	Explode(l_wing, SFX.FALL + SFX.EXPLODE)
	Explode(r_wing, SFX.FALL + SFX.EXPLODE)
	
	--Explode(l_fan, SFX.EXPLODE)
	--Explode(r_fan, SFX.EXPLODE)
	
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
