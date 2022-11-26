include "constants.lua"
include "plates.lua"

local base, body, crane, wheel, railbottom, railtop, train, nanos, nano1, nano2, pad = piece (
	'base', 'body', 'crane', 'wheel', 'railbottom', 'railtop', 'train', 'nanos', 'nano1', 'nano2', 'pad')

local nanoPieces  = { nano1, nano2 }
local smokePiece  = { body, wheel }
local explodables = { crane, wheel, railbottom, railtop, train}

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
