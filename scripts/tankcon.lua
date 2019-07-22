include "constants.lua"

local base, nano, guns, doors, turret, shovel = piece ('base', 'nano', 'guns', 'doors', 'turret', 'shovel')

-- Construction

local nanos = { piece 'nano1', piece 'nano2' }
local SIG_BUILD = 1

function script.StartBuilding(heading)
	Signal (SIG_BUILD)
	Turn (doors, x_axis, math.rad(-100), math.rad(200))
	Move (nano, z_axis, 3, 12)
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 0)
	SetSignalMask (SIG_BUILD)
	Sleep (5000)
	Turn (doors, x_axis, 0, math.rad(200))
	Move (nano, z_axis, 0, 12)
end

local current_nano = 1
function script.QueryNanoPiece()
	current_nano = 3 - current_nano
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID), nanos[current_nano])
	return nanos[current_nano]
end

-- Weaponry

local flares = { piece 'flare1', piece 'flare2' }
local current_flare = 1
local SIG_AIM = 2

local function RestoreAfterDelay()
	SetSignalMask(SIG_AIM)

	Sleep(5000)

	Turn(turret, y_axis, 0, math.rad(15))
	Turn(guns,   x_axis, 0, math.rad(15))
end

function script.QueryWeapon(num)
	return flares[current_flare]
end

function script.AimFromWeapon(num)
	return turret
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	Turn(turret, y_axis, heading, math.rad(450))
	Turn(guns,   x_axis,  -pitch, math.rad(150))

	WaitForTurn(turret, y_axis)
	WaitForTurn(guns, x_axis)
	StartThread(RestoreAfterDelay)

	return true
end

function script.FireWeapon(num)
	EmitSfx(flares[current_flare], 1024)
	current_flare = 3 - current_flare
end

-- Misc

function script.Create()
	StartThread(GG.Script.SmokeUnit, {base})
	Spring.SetUnitNanoPieces(unitID, nanos)
end

local explodables = { turret, guns, shovel }
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

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