include "constants.lua"
include "plates.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, body, bodyl, bodyr, turret, barrel, pad, nano = piece('base', 'body', 'bodyl', 'bodyr', 'turret', 'barrel', 'pad', 'nano')

local nanoPieces = { nano }
local smokePiece = { body, bodyl, bodyr }

local function Open ()
	Signal (1)
	SetSignalMask (1)
	
	SetUnitValue(COB.YARD_OPEN, 1)
	SetInBuildDistance(true)
	--SetUnitValue(COB.BUGGER_OFF, 1)
end

local function Close()
	Signal (1)
	SetSignalMask (1)

	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetInBuildDistance(false)
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
end

function script.Activate ()
	StartThread (Open)
end

function script.Deactivate ()
	StartThread (Close)
end

function script.QueryBuildInfo ()
	return pad
end

local explodables = {turret, barrel, bodyl, bodyr}
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (severity > math.random()) then Explode(explodables[i], SFX.SMOKE + SFX.FIRE) end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (body, SFX.SHATTER)
		return 2
	end
end
