include "constants.lua"

local base = piece 'base'
local emit = piece 'emit'
local leftwing = piece 'leftwing'
local rightwing = piece 'rightwing'
local thrustb = piece 'thrustb' 

local smokePiece = {base, emit, thrustb}
local nanoPieces = {emit}

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),emit)
	return nano
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(rightwing, sfxSmoke)
		Explode(leftwing, sfxSmoke)
		return 1
	else
		Explode(base, sfxShatter + sfxFire)
		Explode(rightwing, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(leftwing, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
	end
end
