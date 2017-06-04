include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

local base = piece "base"
local gate_r = piece "gate_r"
local nano = piece "nano"
local beam1 = piece "beam1"
local beam2 = piece "beam2"

--local vars
local nanoPieces = {nano, beam1, beam2}
local smokePiece = { beam1, beam2 }

local animSpeed = 4

local SIG_ANIM = 1

local function Open()
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)

	Turn (gate_r, x_axis, math.rad(-90), math.rad(135))
	Sleep (500)
	Move (nano, y_axis, 7.5, 15)
	WaitForTurn (gate_r, x_axis)

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

	Move (nano, y_axis, 0, 15)
	Sleep(200)
	Turn (gate_r, x_axis, 0, math.rad(135))
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

local beam_id = 1
function script.QueryNanoPiece()
	beam_id = (beam_id % 3) + 1
	local beam = nanoPieces[beam_id]
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,spGetUnitTeam(unitID),beam)
	return beam
end

function script.Activate ()
	StartThread(Open) --animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ()
	StartThread(Close)
end

function script.QueryBuildInfo()
	return base
end

local explodables = {gate_r, beam1, beam2} -- baw baw not enough real pieces, needs to use fake ones
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