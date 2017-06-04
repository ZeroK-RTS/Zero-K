--by Andrew Rapp (luckywaldo7)

include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

--pieces
local base = piece "base"

local wing_2 = piece "wing_2"
local bay_2 = piece "bay_2"
local arm_2 = piece "arm_2"
local nano_2 = piece "nano_2"
local emit_2 = piece "emit_2"
local pow_2 = piece "pow_2"

local pipes = piece "pipes"

local blink_1 = piece "blink_1"
local blink_2 = piece "blink_2"

local pad = piece "pad"


--local vars
local nanoPieces = {emit_2}
local smokePiece = { blink_1, blink_2, wing_2 }

local animSpeed = 4

local SIG_ANIM = 1

local function Open()
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)

	Turn(wing_2, x_axis, -1.57, animSpeed)
	WaitForTurn(wing_2, x_axis)

	Turn(bay_2, x_axis, 1.57, animSpeed)
	WaitForTurn(bay_2, x_axis)

	Turn(arm_2, x_axis, 2.25, animSpeed)
	Turn(nano_2, x_axis, -1.85, animSpeed)
	WaitForTurn(nano_2, x_axis)

	Turn(pow_2, x_axis, 1.57, animSpeed)
	WaitForTurn(pow_2, x_axis)

	Sleep(300/animSpeed)

	SetUnitValue(COB.YARD_OPEN, 1)
	SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

local function Close()
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)

	SetUnitValue(COB.YARD_OPEN, 0)
	SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)

	Turn(pow_2, x_axis, 0, animSpeed)
	WaitForTurn(pow_2, x_axis)

	Turn(arm_2, x_axis, 0, animSpeed)
	Turn(nano_2, x_axis, 0, animSpeed)
	WaitForTurn(arm_2, x_axis)

	Turn(bay_2, x_axis, 0, animSpeed)
	WaitForTurn(bay_2, x_axis)

	Turn(wing_2, x_axis, 0, animSpeed)
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,spGetUnitTeam(unitID),emit_2)
	return emit_2
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

local explodables = {wing_2, bay_2, arm_2, nano_2, pow_2}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

	for i = 1, #explodables do
		if math.random() < severity then
			Explode(explodables[i], sfxExplode + (brutal and (sfxSmoke + sfxFire + sfxExplodeOnHit) or 0))
		end
	end

	if not brutal then
		return 1
	else
		Explode(base, sfxShatter)
		return 2
	end
end