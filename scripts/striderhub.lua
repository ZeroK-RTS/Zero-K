include "constants.lua"
include "nanoaim.h.lua"

--pieces
local body = piece "body"
local aim = piece "aim"
local emitnano = piece "emitnano"

local ALLY_ACCESS = {allied = true}
--local vars
local smokePiece = { piece "aim", piece "body" }
local nanoPieces = { piece "aim" }

local nanoTurnSpeedHori = 0.5 * math.pi
local nanoTurnSpeedVert = 0.3 * math.pi

local powered = true

function Stunned(stun_type)
	if powered and stun_type == 4 then -- Power
		powered = false
		SetUnitValue(COB.INBUILDSTANCE, 0)
		Spring.SetUnitRulesParam(unitID, "selfIncomeChange", 0, ALLY_ACCESS)
		GG.UpdateUnitAttributes(unitID)
	end
end

function Unstunned(stun_type)
	if (not powered) and stun_type == 4 then -- Power
		powered = true
		SetUnitValue(COB.INBUILDSTANCE, 1)
		Spring.SetUnitRulesParam(unitID, "selfIncomeChange", 1, ALLY_ACCESS)
		GG.UpdateUnitAttributes(unitID)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(GG.NanoAim.UpdateNanoDirectionThread, unitID, nanoPieces, 1000, nanoTurnSpeedHori, nanoTurnSpeedVert)
	Spring.SetUnitNanoPieces(unitID, {emitnano})
	
	local lowPower = (Spring.GetUnitRulesParam(unitID, "lowpower") == 1)
	if lowPower then
		Stunned(4)
	else
		Unstunned(4)
	end
end

function script.StartBuilding()
	GG.NanoAim.UpdateNanoDirection(unitID, nanoPieces, nanoTurnSpeedHori, nanoTurnSpeedVert)
	if powered then
		Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1);
	end
end

function script.StopBuilding()
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 0);
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity < 0.25 then
		return 1
	elseif severity < 0.50 then
		Explode (aim, SFX.FALL)
		return 1
	elseif severity < 0.75 then
		Explode (aim, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	else
		Explode (body, SFX.SHATTER)
		Explode (aim, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
