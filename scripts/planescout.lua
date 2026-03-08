include 'constants.lua'
include "fixedwingTakeOff.lua"

--------------------------------------------------------------------
-- constants/vars
--------------------------------------------------------------------
local base, nozzle = piece("base", "nozzle")
-- unused piece: 'thrust'
local smokePiece = {base}

local SIG_CLOAK = 1
local CLOAK_TIME = 5000

local SIG_TAKEOFF = 2
local takeoffHeight = UnitDefNames["planescout"].cruiseAltitude
--------------------------------------------------------------------
-- functions
--------------------------------------------------------------------
local function Decloak()
	Signal(SIG_CLOAK)
	SetSignalMask(SIG_CLOAK)
	Sleep(CLOAK_TIME)
	Spring.SetUnitCloak(unitID, false)
end

function Cloak()
	Spring.SetUnitCloak(unitID, 2)
	StartThread(Decloak)
end

function script.StopMoving()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

local function freeze()
	while true do
		local state = Spring.GetUnitMoveTypeData(unitID)
		local x, y, z = Spring.GetUnitVelocity(unitID)
		if state and state.aircraftState == "landing"
		and x == 0 and z == 0 then
			Spring.Echo("setting desired fly height for when the unit next takes off! (but actually just freezes the unit)")
			Spring.MoveCtrl.SetAirMoveTypeData(unitID, "wantedHeight", 1000)
			return
		end
		Sleep(33)
	end
end

function script.Create()
	StartThread(freeze)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(nozzle, SFX.FALL)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(nozzle, SFX.FALL + SFX.SMOKE)
		return 2
	end
end
