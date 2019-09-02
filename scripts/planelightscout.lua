include 'constants.lua'
include "fixedwingTakeOff.lua"

--------------------------------------------------------------------
-- constants/vars
--------------------------------------------------------------------
local fuselage, KRisaravinglunatic, canardl, canardr, wingl, wingtipl, wingr, wingtipr, enginel, exhaustl, enginer, exhaustr = piece(
	"fuselage", "KRisaravinglunatic", "canardl", "canardr", "wingl", "wingtipl", "wingr", "wingtipr", "enginel", "exhaustl", "enginer", "exhaustr")
local smokePiece = {KRisaravinglunatic}

local SIG_TAKEOFF = 2
local takeoffHeight = UnitDefNames["planelightscout"].wantedHeight
--------------------------------------------------------------------
-- functions
--------------------------------------------------------------------

function script.StopMoving()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

function script.Create()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(wingr, SFX.EXPLODE)
		Explode(wingl, SFX.EXPLODE)
		Explode(fuselage, SFX.FALL)
		return 1
	else
		Explode(wingr, SFX.SHATTER)
		Explode(wingl, SFX.SHATTER)
		Explode(fuselage, SFX.SHATTER + SFX.SMOKE)
		return 2
	end
end
