include "constants.lua"

local base = piece "base"
local body = piece "cube1_sep2"
local beam = piece "beam"
local boom = piece "boom"
local neck = piece "neck"
local gun = piece "gun"
local ground1 = piece "ground1"
local wakes = {}
for i = 1, 8 do
	wakes[i] = piece ("wake"..i)
end

local curTerrainType = 0
local wobble_dir = true

local SIG_BUILD = 1

local function HoveringAnimations () -- wobbling, waves and dust clouds
	local i = 1
	while true do
		i = i + 1
		if i == 5 then
			if (wobble_dir) then Move (base, y_axis, 2, 5)
			else Move (base, y_axis, -2, 5) end
			wobble_dir = not wobble_dir
			i = 1
		end

		if not Spring.GetUnitIsCloaked(unitID) then
			if (curTerrainType == 1 or curTerrainType == 2) and select(2, Spring.GetUnitPosition(unitID)) == 0 then
				for j = 1, 8 do
					EmitSfx (wakes[j], 3)
				end
			else
				EmitSfx (ground1, 1025)
			end
		end
		Sleep (200)
	end
end

function script.Create()
	Hide (ground1)
	Turn(boom, z_axis, math.rad(180))
	Turn(boom, x_axis, math.rad(60))
	Turn(boom, y_axis, math.pi)
	Move(boom, y_axis, 12)
	Turn(neck, x_axis, -math.rad(120))
	StartThread(GG.Script.SmokeUnit, {base})
	StartThread(HoveringAnimations)
	Spring.SetUnitNanoPieces(unitID, {beam})
end

local function BuildAnim (heading)
	Turn(boom, y_axis, heading+math.pi, math.rad(200))
	WaitForTurn (boom, y_axis)
end

function script.StartBuilding(heading)
	Signal(SIG_BUILD)
	BuildAnim (heading)
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 0)
	SetSignalMask (SIG_BUILD)
	Sleep (5000)
	Turn(boom, y_axis, math.pi, math.rad(50))
end

function script.setSFXoccupy(num)
	curTerrainType = num
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),beam)
	return beam
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity < 0.25 then
		return 1
	elseif severity < 0.50 then
		Explode (neck, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (gun, SFX.FALL)
		return 1
	elseif severity < 0.75 then
		Explode (boom, SFX.FALL)
		Explode (neck, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	else
		Explode (body, SFX.SHATTER)
		Explode (boom, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (neck, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (boom, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
