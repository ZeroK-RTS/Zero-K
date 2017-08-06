include "constants.lua"

local pad = piece 'pad'
local body1, body2 = piece ('body1', 'body2')

local fan1, fan2, fan3 = piece ('fan1', 'fan2', 'fan3')

local top, top1, top2, top3 = piece ('top', 'top1', 'top2', 'top3')
local mid, mid1, mid2, mid3 = piece ('mid', 'mid1', 'mid2', 'mid3')
local bottom, bottom1, bottom2, bottom3 = piece ('bottom', 'bottom1', 'bottom2', 'bottom3')

local turret1, turret2 = piece ('turret1', 'turret2')
local nano1, nano2 = piece ('nano1', 'nano2')
local door1, door2 = piece ('door1', 'door2')
local beam1, beam2 = piece ('beam1', 'beam2')

local nanoPieces = { beam1, beam2 }
local smokePiece = { body1, body2, top1, top2, top3 }

local SIG_ANIM = 1

local function Open ()
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)

	Turn (top,    y_axis, math.rad(-90), math.rad(180))
	WaitForTurn (top,    y_axis)

	Turn (mid,    y_axis, math.rad( 90), math.rad(240))
	WaitForTurn (mid,    y_axis)

	Turn (bottom, y_axis, math.rad(180), math.rad(360))
	WaitForTurn (bottom, y_axis)

	Move (top1,    z_axis,  30, 30)
	Move (top3,    z_axis, -30, 30)
	Move (mid1,    z_axis, -30, 30)
	Move (mid3,    z_axis,  30, 30)
	Move (bottom1, x_axis,  30, 30)
	Move (bottom3, x_axis, -30, 30)
	Move (top2,    x_axis, -35, 35)
	Move (mid2,    x_axis,  35, 35)
	Move (bottom2, z_axis,  35, 35)
	WaitForMove (bottom2, z_axis)

	Turn (top1,    y_axis, -math.pi/2, math.pi*2)
	Turn (mid1,    y_axis, -math.pi/2, math.pi*2)
	Turn (bottom1, y_axis, -math.pi/2, math.pi*2)
	Turn (top3,    y_axis,  math.pi/2, math.pi*2)
	Turn (mid3,    y_axis,  math.pi/2, math.pi*2)
	Turn (bottom3, y_axis,  math.pi/2, math.pi*2)
	WaitForTurn (bottom3, y_axis)

	Turn (door1, y_axis, math.rad(-179), math.pi)
	Turn (door2, y_axis, math.rad( 179), math.pi)
	WaitForTurn (door1, y_axis)

	Move (turret1, z_axis,  6, 20)
	Move (turret2, z_axis, -6, 20)
	WaitForMove (turret1, z_axis)

	Turn (nano1, y_axis, math.rad( 45), math.rad(180))
	Turn (nano2, y_axis, math.rad(-45), math.rad(180))
	WaitForTurn (nano1, x_axis)

	SetUnitValue (COB.YARD_OPEN, 1)
	SetUnitValue (COB.INBUILDSTANCE, 1)
	SetUnitValue (COB.BUGGER_OFF, 1)
end

local function Close()
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)

	SetUnitValue (COB.YARD_OPEN, 0)
	SetUnitValue (COB.BUGGER_OFF, 0)
	SetUnitValue (COB.INBUILDSTANCE, 0)

	Turn (nano1, y_axis, 0, math.rad(180))
	Turn (nano2, y_axis, 0, math.rad(180))
	WaitForTurn (nano1, x_axis)

	Move (turret1, z_axis, 0, 20)
	Move (turret2, z_axis, 0, 20)
	WaitForMove (turret1, z_axis)

	Turn (door1, y_axis, 0, math.pi)
	Turn (door2, y_axis, 0, math.pi)
	WaitForTurn (door1, y_axis)

	Turn (top1,    y_axis, 0, math.pi*2)
	Turn (mid1,    y_axis, 0, math.pi*2)
	Turn (bottom1, y_axis, 0, math.pi*2)
	Turn (top3,    y_axis, 0, math.pi*2)
	Turn (mid3,    y_axis, 0, math.pi*2)
	Turn (bottom3, y_axis, 0, math.pi*2)
	WaitForTurn (bottom3, y_axis)

	Move (top1,    z_axis, 0, 30)
	Move (top3,    z_axis, 0, 30)
	Move (mid1,    z_axis, 0, 30)
	Move (mid3,    z_axis, 0, 30)
	Move (bottom1, x_axis, 0, 30)
	Move (bottom3, x_axis, 0, 30)
	Move (top2, x_axis,    0, 35)
	Move (mid2, x_axis,    0, 35)
	Move (bottom2, z_axis, 0, 35)
	WaitForMove (bottom2, z_axis)

	Turn (bottom, y_axis, 0, math.rad(360))
	WaitForTurn (bottom, y_axis)

	Turn (mid,    y_axis, 0, math.rad(240))
	WaitForTurn (mid,    y_axis)

	Turn (top,    y_axis, 0, math.rad(180))
	WaitForTurn (top,    y_axis)
end

function script.Create()
	Spin (fan1, x_axis, math.rad(720))
	Spin (fan2, z_axis, math.rad(720))
	Spin (fan3, x_axis, math.rad(720))

	StartThread (SmokeUnit, smokePiece, 5)
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
end

local left = true
function script.QueryNanoPiece ()
	left = not left
	if left then
		GG.LUPS.QueryNanoPiece (unitID, unitDefID, Spring.GetUnitTeam(unitID), beam1)
		return beam1
	else
		GG.LUPS.QueryNanoPiece (unitID, unitDefID, Spring.GetUnitTeam(unitID), beam2)
		return beam2
	end
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

local explodables = {nano1, nano2, door1, door2}
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (severity > math.random()) then Explode(explodables[i], sfxSmoke + sfxFire) end
	end

	if (severity <= .5) then
		return 1
	else
		Explode(body1, sfxShatter)
		Explode(body2, sfxShatter)
		return 2
	end
end
