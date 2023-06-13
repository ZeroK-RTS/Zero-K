include "constants.lua"
include "plates.lua"

local base, body, nano1, nano2, nano3, nano4, pad = piece (
	'base', 'body', 'nano1', 'nano2', 'nano3', 'nano4', 'pad')

local nanoPieces  = { nano1, nano2, nano3, nano4 }
local smokePiece  = { nano1, nano2, nano3, nano4 }
local explodables = { body}

local function Open ()
	Spin (pad, y_axis, math.rad(30))

	SetUnitValue(COB.YARD_OPEN, 1)
	SetInBuildDistance(true)
	--SetUnitValue(COB.BUGGER_OFF, 1)
end

local function Close()
	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetInBuildDistance(false)
	
	StopSpin (pad, y_axis)
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
