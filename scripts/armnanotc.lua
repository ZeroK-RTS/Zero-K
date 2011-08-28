include "smokeunit.lua"
include "nanoaim.h.lua"

--pieces
local body = piece "body"
local aim = piece "aim"
local emitnano = piece "emitnano"

--local vars
local smokePieces = { piece "aim", piece "body" }
local nanoPieces = { piece "aim" }

local nanoTurnSpeedHori = 0.5 * math.pi
local nanoTurnSpeedVert = 0.1 * math.pi

function script.Create()
	StartThread(SmokeUnit, smokePieces)
	StartThread(UpdateNanoDirectionThread, nanoPieces, 500, nanoTurnSpeedHori, nanoTurnSpeedVert)
end


function script.StartBuilding()
	UpdateNanoDirection(nanoPieces, nanoTurnSpeedHori, nanoTurnSpeedVert)
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1);
end


function script.StopBuilding()
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 0);
end


function script.QueryNanoPiece()
	--// send to LUPS
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),emitnano)

	return emitnano
end


function script.Killed(recentDamage, maxHealth)
	Explode( body, SFX.EXPLODE )
	Explode( aim, SFX.EXPLODE )
--[[
	if( severity <= 25 )
	{
		corpsetype = 1;
		explode body type BITMAPONLY | BITMAP1;
		explode aim type BITMAPONLY | BITMAP3;
		return (0);
	}
	if( severity <= 50 )
	{
		corpsetype = 2;
		explode body type FALL | BITMAP1;
		explode aim type FALL | BITMAP3;
		return (0);
	}
	if( severity <= 99 )
	{
		corpsetype = 3;
		explode body type FALL | SMOKE | FIRE | EXPLODE_ON_HIT | BITMAP1;
		explode aim type FALL | SMOKE | FIRE | EXPLODE_ON_HIT | BITMAP3;
		return (0);
	}
	corpsetype = 3;
	explode body type FALL | SMOKE | FIRE | EXPLODE_ON_HIT | BITMAP1;
	explode aim type SHATTER | EXPLODE_ON_HIT | BITMAP3;
--]]
end
