include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, center1, center2, side1, side2, pad = piece('base', 'center1', 'center2', 'side1', 'side2', 'pad')
local head1, head2, nano1, nano2, nano3, nano4 = piece('head1', 'head2', 'nano1', 'nano2', 'nano3', 'nano4')

--local vars
local nanoPieces = {nano1, nano2, nano3, nano4}
local smokePiece = {base, head1, head2}

local SIG_Open = 1

--opening animation of the factory
local function Open()
	Signal(SIG_Open)
	SetSignalMask(SIG_Open)

	Move(center1, z_axis, 0, 10)
	Move(center2, z_axis, 0, 10)
	Move(side1, z_axis, 0, 10)
	Move(side2, z_axis, 0, 10)
	WaitForMove(center1, z_axis)
	WaitForMove(center2, z_axis)
	--Sleep(500)
	
--	SetUnitValue(COB.YARD_OPEN, 1) --Tobi said its not necessary
	--SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	GG.Script.UnstickFactory(unitID)
end

--closing animation of the factory
local function Close()
	Signal(SIG_Open) --kill the opening animation if it is in process
	SetSignalMask(SIG_Open) --set the signal to kill the closing animation

--	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)

	Move(center1, z_axis, 20, 10)
	Move(center2, z_axis, 20, 10)
	Move(side1, z_axis, 20, 10)
	Move(side2, z_axis, 10, 10)
end

function script.Create()
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	Move(center1, z_axis, 20)
	Move(center2, z_axis, 20)
	Move(side1, z_axis, 20)
	Move(side2, z_axis, 10)
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do Sleep(400) end
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Activate ()
	StartThread(Open) --animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ()
	StartThread(Close)
end

function script.QueryBuildInfo()
	return pad
end

--death and wrecks
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		Explode(base, SFX.NONE)
		Explode(center1, SFX.NONE)
		Explode(center2, SFX.NONE)
		Explode(head1, SFX.NONE)
		Explode(head2, SFX.NONE)
		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode(base, SFX.NONE)
		Explode(center1, SFX.NONE)
		Explode(center2, SFX.NONE)
		Explode(head1, SFX.SHATTER)
		Explode(head2, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		Explode(center1, SFX.SHATTER)
		Explode(center2, SFX.SHATTER)
		Explode(head1, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(head2, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
