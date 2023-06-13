--by Andrew Rapp (luckywaldo7)

include "constants.lua"

local spGetUnitTeam = Spring.GetUnitTeam

local base, elevator, turret, emit, barrel, pipe, pad = piece ("base", "elevator", "turret", "emit", "barrel", "pipe", "pad")

local spinners = {}
for i = 1, 4 do spinners[i] = piece ("spinner_" .. i) end

local lidh1, lidh2 = piece ("lid_h_1", "lid_h_2")
local lid1, lid2 = piece ("lid_1", "lid_2")
local track1, track2, track3 = piece ("track_1", "track_2", "track_3")

local open = false

local SIG_ANIM = 1

local function GetDisabled()
	return Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID,"disarmed") == 1)
end

local function Open()
	if open then
		return
	end
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)
	open = true

	while GetDisabled() do
		Sleep(500)
	end
	
	for i = 1, #spinners do
		Spin(spinners[i], x_axis, math.rad(180))
	end
	Turn(lidh1, z_axis, math.rad( 90), math.rad(100))
	Turn(lidh2, z_axis, math.rad(-90), math.rad(100))
	Move(track1, z_axis, -18, 36)

	WaitForMove (track1, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	Move(elevator, y_axis, 20, 20)
	Move(track2, z_axis, -22, 44)

	WaitForMove (track2, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	Move(track3, z_axis, -26, 52)
	Move(barrel, z_axis, 8, 16)

	WaitForTurn (lidh1, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	Move(lid1, x_axis, -13, 28)
	Move(lid2, x_axis, 13, 28)
	
	WaitForMove (track3, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	for i = 1, #spinners do
		StopSpin(spinners[i], x_axis)
	end
	
	--SetUnitValue(COB.BUGGER_OFF, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	SetUnitValue(COB.YARD_OPEN, 1)
	GG.Script.UnstickFactory(unitID)
end

local function Close()
	if not open then
		return
	end
	Signal(SIG_ANIM)
	SetSignalMask(SIG_ANIM)
	open = false

	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)
	SetUnitValue(COB.YARD_OPEN, 0)
	
	while GetDisabled() do
		Sleep(500)
	end

	for i = 1, #spinners do
		Spin(spinners[i], x_axis, math.rad(-180))
	end

	Move(lid1, x_axis, 0, 28)
	Move(lid2, x_axis, 0, 28)
	
	Move(barrel, z_axis, 0, 16)
	Move(track3, z_axis, 0, 52)
	Move(elevator, y_axis, 0, 20)
	
	WaitForMove (lid1, x_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	Turn(lidh1, z_axis, 0, math.rad(100))
	Turn(lidh2, z_axis, 0, math.rad(100))

	WaitForMove (track3, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	Move(track2, z_axis, 0, 44)

	WaitForMove (track2, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	Move(track1, z_axis, 0, 36)

	WaitForMove (track1, z_axis)
	while GetDisabled() do
		Sleep(500)
	end
	
	for i = 1, #spinners do
		StopSpin(spinners[i], x_axis)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {pipe, lidh2, piece "smoke_1"})
	Spring.SetUnitNanoPieces(unitID, {emit})
	StartThread(Open)
end

function script.Activate ()
	StartThread(Open)
end

local firstDeactivate = true
function script.Deactivate()
	if firstDeactivate then
		firstDeactivate = false
		return
	end
	StartThread(Close)
end

function script.QueryBuildInfo()
	return pad
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

	local explodables = {barrel, turret, pipe, spinners[1], spinners[4], piece "lid_1"}
	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], SFX.FALL + (brutal and (SFX.SMOKE + SFX.FIRE) or 0))
		end
	end

	if not brutal then
		return 1
	else
		Explode (base, SFX.SHATTER)
		return 2
	end
end
