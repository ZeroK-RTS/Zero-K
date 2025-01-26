include 'constants.lua'
include "fixedwingTakeOff.lua"

--------------------------------------------------------------------
-- constants/vars
--------------------------------------------------------------------
local fuselage, KRisaravinglunatic, wingl, wingr = piece("fuselage", "KRisaravinglunatic", "wingl", "wingr")
-- unused pieces: canardl, canardr, enginer, enginel, exhaustl, exhaustr
local smokePiece = {KRisaravinglunatic}

local SIG_TAKEOFF = 2
local takeoffHeight = UnitDefNames["planelightscout"].cruiseAltitude

local SPEEDUP_FACTOR = tonumber(UnitDef.customParams.boost_speed_mult)
local ACCEL_FACTOR = tonumber(UnitDef.customParams.boost_accel_mult) or SPEEDUP_FACTOR
local SPEEDUP_DURATION = tonumber(UnitDef.customParams.boost_duration)

local denonateCharge = false

--------------------------------------------------------------------
-- functions
--------------------------------------------------------------------

function SprintThread()
	GG.PokeDecloakUnit(unitID, unitDefID)
	local cegCharge = 1
	for i = 1, SPEEDUP_DURATION do
		cegCharge = cegCharge + 0.2 + 0.3 * (denonateCharge or 0) / SPEEDUP_DURATION
		if cegCharge > 1 then
			EmitSfx(fuselage, 1024)
			cegCharge = cegCharge - 1
		end
		denonateCharge = (denonateCharge or 0) + 1
		Sleep(33)
	end
	
	-- Don't read cp.boost_detonate, because then we'd have to write a dead code path for post-boost
	Spring.DestroyUnit(unitID, true)
end

function SprintDetonate()
	if denonateCharge then
		return
	end
	Turn(wingl, y_axis, math.rad(65), math.rad(180))
	Turn(wingr, y_axis, math.rad(-65), math.rad(180))

	StartThread(SprintThread)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", SPEEDUP_FACTOR)
	Spring.SetUnitRulesParam(unitID, "selfMaxAccelerationChange", ACCEL_FACTOR / SPEEDUP_FACTOR)
	GG.UpdateUnitAttributes(unitID)
end

function script.StopMoving()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

function script.Create()
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local ux, _, uz = Spring.GetUnitPosition(unitID)
	local ud = UnitDefs[unitDefID]
	
	local scanFrames = ud.customParams.scan_frames and tonumber(ud.customParams.scan_frames) or 360
	local scanRadius = ud.customParams.scan_radius_base and tonumber(ud.customParams.scan_radius_base) or 400
	if ud.customParams.scan_radius_max then
		scanRadius = scanRadius + ((tonumber(ud.customParams.scan_radius_max) or 640) - scanRadius) * (denonateCharge or 0) / SPEEDUP_DURATION
	end
	
	GG.ScanSweep.AddArea("scoutPlane", Spring.GetUnitTeam(unitID), ux, uz, scanRadius, scanFrames)
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
