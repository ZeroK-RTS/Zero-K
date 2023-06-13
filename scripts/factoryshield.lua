include "constants.lua"

local base, turret, arm_1, arm_2, arm_3, nanobase, centre, rightpiece, leftpiece, nanoemit, pad, nozzle, cylinder, back = piece ('base', 'turret', 'arm_1', 'arm_2', 'arm_3', 'nanobase', 'centre', 'rightpiece', 'leftpiece', 'nanoemit', 'pad', 'nozzle', 'cylinder', 'back')

local nanoPieces = { nanoemit }
local smokePiece = { base }

local function Open ()
	Signal (1)
	SetSignalMask (1)

	Turn (leftpiece,  z_axis, math.rad(-90), math.rad(90))
	Turn (rightpiece, z_axis, math.rad( 90), math.rad(90))
	Turn (centre,     x_axis, math.rad(-90), math.rad(90))
	Move (leftpiece,  x_axis,  -15, 15)
	Move (rightpiece, x_axis,  15, 15)
	Turn (arm_1, x_axis, math.rad(-85), math.rad(85))
	Turn (arm_2, x_axis, math.rad(170), math.rad(170))
	Turn (arm_3, x_axis, math.rad(-60), math.rad(60))
	Turn (nanobase, x_axis, math.rad(10), math.rad(10))
	WaitForTurn (centre, x_axis)

	SetUnitValue(COB.YARD_OPEN, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	--SetUnitValue(COB.BUGGER_OFF, 1)
	GG.Script.UnstickFactory(unitID)
end

local function Close()
	Signal (1)
	SetSignalMask (1)

	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)

	Turn (leftpiece,  z_axis, 0, math.rad(36))
	Turn (rightpiece, z_axis, 0, math.rad(36))
	Turn (centre,     x_axis, 0, math.rad(36))
	Move (leftpiece,  x_axis, 0, 6)
	Move (rightpiece, x_axis, 0, 6)
	Turn (arm_1, x_axis, 0, math.rad(34))
	Turn (arm_2, x_axis, 0, math.rad(68))
	Turn (arm_3, x_axis, 0, math.rad(24))
	Turn (nanobase, x_axis, 0, math.rad(4))
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

local explodables = {nozzle, cylinder, arm_1, arm_2, arm_3}
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (severity > math.random()) then Explode(explodables[i], SFX.SMOKE + SFX.FIRE) end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (back, SFX.SHATTER)
		Explode (centre, SFX.SHATTER)
		Explode (leftpiece, SFX.SHATTER)
		Explode (rightpiece, SFX.SHATTER)
		return 2
	end
end
