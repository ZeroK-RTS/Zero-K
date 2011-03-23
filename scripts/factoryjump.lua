include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, center1, center2, side1, side2, pad = piece('base', 'center1', 'center2', 'side1', 'side2', 'pad')
local head1, head2, nano1, nano2, nano3, nano4 = piece('head1', 'head2', 'nano1', 'nano2', 'nano3', 'nano4')

--local vars
local nanoPieces = {nano1, nano2, nano3, nano4}
local nanoIdx = 1
smokePiece = {base, head1, head2}

local SIG_Open = 1
local SIG_Close = 2

--opening animation of the factory
local function Open()
	Signal(SIG_Close)
	SetSignalMask(SIG_Open)

	Move(center1, z_axis, 0, 10)
	Move(center2, z_axis, 0, 10)
	Move(side1, z_axis, 0, 10)
	Move(side2, z_axis, 0, 10)
	WaitForMove(center1, z_axis)
	WaitForMove(center2, z_axis)
	
--	SetUnitValue(COB.YARD_OPEN, 1)  --Tobi said its not necessary
	SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

--closing animation of the factory
local function Close()
	Signal(1) --kill the opening animation if it is in process
	SetSignalMask(2) --set the signal to kill the closing animation

--	SetUnitValue(COB.YARD_OPEN, 0)
	SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)

	Move(center1, z_axis, 10, 10)
	Move(center2, z_axis, 10, 10)
	Move(side1, z_axis, 10, 10)
	Move(side2, z_axis, 10, 10)
end

function script.Create()
	Move(center1, z_axis, 10)
	Move(center2, z_axis, 10)
	Move(side1, z_axis, 10)
	Move(side2, z_axis, 10)
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do Sleep(400) end
	StartThread(SmokeUnit)
end

function script.QueryNanoPiece()
	if (nanoIdx == 4) then
		nanoIdx = 1
	else
		nanoIdx = nanoIdx + 1
	end

	local nano = nanoPieces[nanoIdx]

	--// send to LUPS
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,spGetUnitTeam(unitID),nano)

	return nano
end

function script.Activate ( )
	StartThread( Open ) --animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ( )
	StartThread( Close )
end

function script.QueryBuildInfo()
	return pad
end

--death and wrecks
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(center1, sfxNone)
		Explode(center2, sfxNone)
		Explode(head1, sfxNone)
		Explode(head2, sfxNone)
		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode(base, sfxNone)
		Explode(center1, sfxNone)
		Explode(center2, sfxNone)
		Explode(head1, sfxShatter)
		Explode(head2, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(base, sfxShatter)
		Explode(center1, sfxShatter)
		Explode(center2, sfxShatter)
		Explode(head1, sfxSmoke + sfxFire + sfxExplode)
		Explode(head2, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end