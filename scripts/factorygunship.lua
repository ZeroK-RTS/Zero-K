include "constants.lua"

local beam1, beam2 = piece ('beam1', 'beam2')
local door1, door2 = piece ('door1', 'door2')
local post1, post2 = piece ('post1', 'post2')
local nano1, nano2 = piece ('nano1', 'nano2')
local base, pad = piece ('base', 'pad')

local nanoPieces = { beam1, beam2 }
local smokePiece = { base }

local function Open ()
	Signal (1)
	SetSignalMask (1)

	Turn (door1, z_axis, math.rad(-90), math.rad(160))
	Turn (door2, z_axis, math.rad( 90), math.rad(160))
	WaitForTurn (door1, z_axis)

	Move (door1, y_axis, -4.5, 7)
	Move (door2, y_axis, -4.5, 7)
	WaitForMove (door1, y_axis)

	Move (post1, y_axis, 7, 21)
	Move (post1, y_axis, 7, 21)
	WaitForMove (post1, y_axis)

	Turn (nano1, z_axis, math.rad(-100), math.rad(175))
	Turn (nano2, z_axis, math.rad( 100), math.rad(175))
	WaitForTurn (nano1, z_axis)

	Spin (pad, y_axis, math.rad(30), math.rad(1))

	SetUnitValue (COB.YARD_OPEN, 1)
	SetUnitValue (COB.INBUILDSTANCE, 1)
	SetUnitValue (COB.BUGGER_OFF, 1)
end

local function Close()
	Signal (1)
	SetSignalMask (1)

	SetUnitValue (COB.YARD_OPEN, 0)
	SetUnitValue (COB.BUGGER_OFF, 0)
	SetUnitValue (COB.INBUILDSTANCE, 0)

	StopSpin (pad, y_axis, math.rad(1))

	Turn (nano1, z_axis, 0, math.rad(175))
	Turn (nano2, z_axis, 0, math.rad(175))
	WaitForTurn (nano1, z_axis)

	Move (post1, y_axis, 0, 21)
	Move (post1, y_axis, 0, 21)
	WaitForMove (post1, y_axis)

	Move (door1, y_axis, 0, 7)
	Move (door2, y_axis, 0, 7)
	WaitForMove (door1, y_axis)

	Turn (door1, z_axis, 0, math.rad(160))
	Turn (door2, z_axis, 0, math.rad(160))
	-- WaitForTurn (door1, z_axis)
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
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

local explodables = {nano1, nano2, post1, post2, door1, door2}
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
		Explode (pad, sfx.SHATTER)
		Explode (base, sfx.SHATTER)
		return 2
	end
end
