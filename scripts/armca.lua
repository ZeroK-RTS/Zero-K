local base = piece 'base' 
local body = piece 'body' 
local engine1 = piece 'engine1' 
local engine2 = piece 'engine2' 
local nozzle = piece 'nozzle' 
local nano = piece 'nano' 

smokePiece = {body, engine1, engine2}
local nanoPieces = {nano}

include "constants.lua"

function script.Create()
	Turn(engine1, x_axis, rad(-45))	
	Turn(engine2, x_axis, rad(-45))	
	StartThread(SmokeUnit)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.Activate()
	Turn(engine1, x_axis, rad(0), rad(30))	
	Turn(engine2, x_axis, rad(0), rad(30))	
end

function script.Deactivate()
	Turn(engine1, x_axis, rad(-45), rad(60))	
	Turn(engine2, x_axis, rad(-45), rad(60))	
end

function script.StartBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 1)
	Move(nozzle, y_axis, rad(-1), rad(2))
	Move(nozzle, z_axis, rad(1), rad(2))
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Move(nozzle, y_axis, rad(0), rad(3))
	Move(nozzle, z_axis, rad(0), rad(3))
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nano)
	return nano
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(engine2, sfxFall)
		Explode(engine1, sfxFall)
		return 1
	elseif severity <= 0.50 then
		Explode(body, sfxShatter)
		Explode(engine2, sfxFall)
		Explode(engine1, sfxFall)
		return 1
	else
		Explode(body, sfxShatter)
		Explode(engine2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		Explode(engine1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		return 2
	end
end