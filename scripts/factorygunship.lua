include "constants.lua"

local nanoPieces = {}
for i = 1, 4 do
	nanoPieces[i] = piece('nano' .. i)
end

local base, pad = piece ('base', 'pad')

local smokePieces = nanoPieces

local function Open ()
	-- no waits -> no signal
	Spin (pad, y_axis, math.rad(30))

	SetUnitValue (COB.YARD_OPEN, 1)
	SetUnitValue (COB.INBUILDSTANCE, 1)
	SetUnitValue (COB.BUGGER_OFF, 1)
end

local function Close()
	SetUnitValue (COB.YARD_OPEN, 0)
	SetUnitValue (COB.BUGGER_OFF, 0)
	SetUnitValue (COB.INBUILDSTANCE, 0)

	StopSpin (pad, y_axis)
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, unitID, smokePieces)
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
end

local lastNanopiece = 1
function script.QueryNanoPiece ()
	Spring.Echo("called at all? noice")
	lastNanopiece = 3 - lastNanopiece
	local nanoemit = nanoPieces[lastNanopiece]
	GG.LUPS.QueryNanoPiece (unitID, unitDefID, Spring.GetUnitTeam(unitID), nanoemit)
	return nanoemit
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

local explodables = smokePieces -- these are all empty pieces to generate smoke trails; ideally the whole model would not be a single object
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)
	local sfx = SFX

	local effect = sfx.FALL + (brutal and (sfx.SMOKE + sfx.FIRE) or 0)
	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], effect)
		end
	end

	if not brutal then
		return 1
	else
		Explode (base, sfx.SHATTER)
		return 2
	end
end
