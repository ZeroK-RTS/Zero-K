include "constants.lua"
include "plates.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, house, pad = piece('base', 'house', 'pad')
local head1, head2, nano1, nano2, nano3, nano4 = piece('head1', 'head2', 'nano1', 'nano2', 'nano3', 'nano4')

--local vars
local nanoPieces = {nano1, nano2, nano3, nano4}
local smokePiece = {house, head1, head2}

local SIG_Open = 1
local SIG_Close = 2

--opening animation of the factory
local function Open()
	Signal(SIG_Close)
	--SetSignalMask(SIG_Open)

	Sleep(200)
	
	--SetUnitValue(COB.BUGGER_OFF, 1)
	SetInBuildDistance(true)
end

--closing animation of the factory
local function Close()
	Signal(SIG_Open) --kill the opening animation if it is in process
	SetSignalMask(SIG_Close) --set the signal to kill the closing animation

--	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetInBuildDistance(false)
end

function script.Create()
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do
		Sleep(400)
	end
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
		Explode(house, SFX.NONE)
		Explode(head1, SFX.NONE)
		Explode(head2, SFX.NONE)
		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode(house, SFX.NONE)
		Explode(head1, SFX.SHATTER)
		Explode(head2, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(house, SFX.SHATTER)
		Explode(head1, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(head2, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
