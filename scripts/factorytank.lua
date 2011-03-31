--by Andrew Rapp (luckywaldo7)

include "smokeunit.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--pieces
local base = piece "base"

local wing_1 = piece "wing_1"
local bay_1 = piece "bay_1"
local arm_1 = piece "arm_1"
local nano_1 = piece "nano_1"
local emit_1 = piece "emit_1"
local pow_1 = piece "pow_1"

local wing_2 = piece "wing_2"
local bay_2 = piece "bay_2"
local arm_2 = piece "arm_2"
local nano_2 = piece "nano_2"
local emit_2 = piece "emit_2"
local pow_2 = piece "pow_2"

local wing_3 = piece "wing_3"
local bay_3 = piece "bay_3"
local arm_3 = piece "arm_3"
local nano_3 = piece "nano_3"
local emit_3 = piece "emit_3"
local pow_3 = piece "pow_3"

local pipes = piece "pipes"

local blink_1 = piece "blink_1"
local blink_2 = piece "blink_2"

local pad = piece "pad"


--local vars
local nanoPieces = {emit_1,emit_2,emit_3}
local nanoIdx = 1
local smokePieces = { piece "wing_1", piece "wing_2", piece "wing_3" }

--opening animation of the factory
local function Open()
	Signal(2) --kill the closing animation if it is in process
	SetSignalMask(1) --set the signal to kill the opening animation

	Turn(wing_1, 3, -1.57, 1)
	Turn(wing_2, 1, -1.57, 1)
	Turn(wing_3, 3, 1.57, 1)

	WaitForTurn(wing_1,3)

	Turn(bay_1, 3, 1.57, 1)
	Turn(bay_2, 1, 1.57, 1)
	Turn(bay_3, 3, -1.57, 1)

	WaitForTurn(bay_1, 3)

	Turn(arm_1, 3, 2.25, 1)
	Turn(arm_2, 1, 2.25, 1)
	Turn(arm_3, 3, -2.25, 1)

	Turn(nano_1, 3, -1.85, 1)
	Turn(nano_2, 1, -1.85, 1)
	Turn(nano_3, 3, 1.85, 1)

	WaitForTurn(nano_1,3)

	Turn(pow_1, 3, 1.57, 1)
	Turn(pow_2, 1, 1.57, 1)
	Turn(pow_3, 3, -1.57, 1)

	WaitForTurn(pow_1, 3)
	Sleep( 300 )

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

	Turn(pow_1, 3, 0, 1)
	Turn(pow_2, 1, 0, 1)
	Turn(pow_3, 3, 0, 1)

	WaitForTurn(pow_1,3)

	Turn(arm_1, 3, 0, 1)
	Turn(arm_2, 1, 0, 1)
	Turn(arm_3, 3, 0, 1)

	Turn(nano_1, 3, 0, 1)
	Turn(nano_2, 1, 0, 1)
	Turn(nano_3, 3, 0, 1)

	WaitForTurn(arm_1, 3)

	Turn(bay_1, 3, 0, 1)
	Turn(bay_2, 1, 0, 1)
	Turn(bay_3, 3, 0, 1)

	WaitForTurn(bay_1,3)

	Turn(wing_1, 3, 0, 1)
	Turn(wing_2, 1, 0, 1)
	Turn(wing_3, 3, 0, 1)
end

function script.Create()
	StartThread(SmokeUnit, smokePieces)
end

function script.QueryNanoPiece()
	if (nanoIdx == 3) then
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
		Explode(bay_1, SFX.EXPLODE)
		Explode(bay_2, SFX.EXPLODE)
		Explode(bay_3, SFX.EXPLODE)

		Explode(arm_1, SFX.EXPLODE_ON_HIT)
		Explode(arm_2, SFX.EXPLODE_ON_HIT)
		Explode(arm_3, SFX.EXPLODE_ON_HIT)

		Explode(nano_1, SFX.EXPLODE_ON_HIT)
		Explode(nano_2, SFX.EXPLODE_ON_HIT)
		Explode(nano_3, SFX.EXPLODE_ON_HIT)

		Explode(pow_1, SFX.EXPLODE_ON_HIT)
		Explode(pow_2, SFX.EXPLODE_ON_HIT)
		Explode(pow_3, SFX.EXPLODE_ON_HIT)

		Explode(pipes, SFX.EXPLODE_ON_HIT)

		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode(base, SFX.SHATTER)

		Explode(wing_1, SFX.EXPLODE)
		Explode(wing_2, SFX.EXPLODE)
		Explode(wing_3, SFX.EXPLODE)

		Explode(bay_1, SFX.EXPLODE)
		Explode(bay_2, SFX.EXPLODE)
		Explode(bay_3, SFX.EXPLODE)

		Explode(arm_1, SFX.EXPLODE_ON_HIT)
		Explode(arm_2, SFX.EXPLODE_ON_HIT)
		Explode(arm_3, SFX.EXPLODE_ON_HIT)

		Explode(nano_1, SFX.EXPLODE_ON_HIT)
		Explode(nano_2, SFX.EXPLODE_ON_HIT)
		Explode(nano_3, SFX.EXPLODE_ON_HIT)

		Explode(pow_1, SFX.EXPLODE_ON_HIT)
		Explode(pow_2, SFX.EXPLODE_ON_HIT)
		Explode(pow_3, SFX.EXPLODE_ON_HIT)

		Explode(pipes, SFX.EXPLODE_ON_HIT)

		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)

		Explode(wing_1, SFX.SHATTER)
		Explode(wing_2, SFX.SHATTER)
		Explode(wing_3, SFX.SHATTER)

		Explode(bay_1, SFX.EXPLODE_ON_HIT)
		Explode(bay_2, SFX.EXPLODE_ON_HIT)
		Explode(bay_3, SFX.EXPLODE_ON_HIT)

		Explode(arm_1, SFX.EXPLODE_ON_HIT)
		Explode(arm_2, SFX.EXPLODE_ON_HIT)
		Explode(arm_3, SFX.EXPLODE_ON_HIT)

		Explode(nano_1, SFX.EXPLODE_ON_HIT)
		Explode(nano_2, SFX.EXPLODE_ON_HIT)
		Explode(nano_3, SFX.EXPLODE_ON_HIT)

		Explode(pow_1, SFX.EXPLODE_ON_HIT)
		Explode(pow_2, SFX.EXPLODE_ON_HIT)
		Explode(pow_3, SFX.EXPLODE_ON_HIT)

		Explode(pipes, SFX.EXPLODE_ON_HIT)

		return 2 -- corpsetype
	end
end