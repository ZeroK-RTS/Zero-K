
-- by Chris Mackey
include "constants.lua"

--pieces
local base = piece "base"
local toroid = piece "toroid"
local energyball = piece "energyball"
local nexus = piece "nexus"
local arm1 = piece "arm1"
local arm2 = piece "arm2"
local arm3 = piece "arm3"

local smokePiece = { piece "base", piece "arm1", piece "arm2", piece "arm3" }

local ballSize = 0
local is_stunned = true

local function SizeControl()
	local mag = math.random() + 1
	local period = math.random()*20 + 15
	local t = 0

	local sin = math.sin
	local spSetUnitPieceMatrix = Spring.SetUnitPieceMatrix
	local pieceTable = {Spring.GetUnitPieceMatrix(unitID, energyball)}

	while true do
		if is_stunned then
			if ballSize > 3 then
				ballSize = ballSize - 3
			else
				ballSize = 1
				Hide(energyball)
			end
		else
			if ballSize == 1 then
				Show(energyball)
			end
			if ballSize < 100 then
				ballSize = ballSize + 1
			end
		end

		local ballSwellFactor = 1.13^(sin(t/period)*mag) * (ballSize^2 / 11000)
		pieceTable[ 1] = ballSwellFactor
		pieceTable[ 6] = ballSwellFactor
		pieceTable[11] = ballSwellFactor
		spSetUnitPieceMatrix(unitID, energyball, pieceTable)

		t = t + 1
		Sleep(33)
	end
end

local function StartAnim()
	Spin(toroid, y_axis, 1, 0.25 / Game.gameSpeed)
	Spin(arm1, y_axis, -2, 0.5 / Game.gameSpeed)
	Spin(arm2, y_axis, -2, 0.5 / Game.gameSpeed)
	Spin(arm3, y_axis, -2, 0.5 / Game.gameSpeed)
	Spin(nexus, y_axis, -2, 0.5 / Game.gameSpeed)
end

local function StopAnim()
	StopSpin(toroid, y_axis, 1 / Game.gameSpeed)
	StopSpin(arm1, y_axis, 2 / Game.gameSpeed)
	StopSpin(arm2, y_axis, 2 / Game.gameSpeed)
	StopSpin(arm3, y_axis, 2 / Game.gameSpeed)
	StopSpin(nexus, y_axis, 2 / Game.gameSpeed)
end

local function Anim()
	local spGetUnitIsStunned = Spring.GetUnitIsStunned
	local was_stunned = true
	while true do
		is_stunned = spGetUnitIsStunned(unitID)
		if is_stunned ~= was_stunned then
			was_stunned = is_stunned
			if is_stunned then
				StopAnim()
			else
				StartAnim()
			end
		end
		Sleep(1000)
	end
end


function script.Create()
	Hide(energyball)

	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(Anim)
	StartThread(SizeControl)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.EXPLODE)
	Explode(toroid, SFX.EXPLODE)

	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
