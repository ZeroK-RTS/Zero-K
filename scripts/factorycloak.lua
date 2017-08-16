include "constants.lua"

-- pieces
local base = piece "base"
local door = piece "door"
local arm1 = piece "arm1"
local arm2 = piece "arm2"
local claw1 = piece "claw1"
local claw2 = piece "claw2"
local lid1 = piece "lid1"
local lid2 = piece "lid2"
local pipesh1 = piece "pipeh1"
local pipesh2 = piece "pipeh2"
local pipesl = piece "pipesl"
local pipesr = piece "pipesr"

-- action pieces
local nanoPieces = { claw1 }
local smokePiece = { door, arm1, arm2 }

local function Open ()
	SetSignalMask (1)

	-- move the pieces
	Move (door, y_axis, -30, 15)
	Turn (lid1, z_axis, math.rad( 90), math.rad(45))
	Turn (lid2, z_axis, math.rad(-90), math.rad(45))
	
	Turn (arm1, x_axis, math.rad(20), math.rad(50))
	Turn (arm2, x_axis, math.rad(-75), math.rad(50))

	Move (pipesl, y_axis, 0, 20)
	Move (pipesr, y_axis, 0, 20)

	-- wait for them to move
	WaitForMove (door, y_axis)
	
	WaitForTurn (arm1, x_axis)
	WaitForTurn (arm2, x_axis)

	WaitForMove (pipesl, y_axis)
	WaitForMove (pipesr, y_axis)

	-- set values
	SetUnitValue (COB.YARD_OPEN, 1)
	SetUnitValue (COB.INBUILDSTANCE, 1)
	SetUnitValue (COB.BUGGER_OFF, 1)
end

local function Close()
	Signal (1)

	-- set values
	SetUnitValue (COB.YARD_OPEN, 0)
	SetUnitValue (COB.BUGGER_OFF, 0)
	SetUnitValue (COB.INBUILDSTANCE, 0)

	-- move pieces back to original spots
	Move (door, y_axis, 0, 15)
	Turn (lid1, z_axis, 0, math.rad(45))
	Turn (lid2, z_axis, 0, math.rad(45))

	Turn (arm1, x_axis, 0, math.rad(50))
	Turn (arm2, x_axis, 0, math.rad(50))

	Move (pipesl, y_axis, 35, 20)
	Move (pipesr, y_axis, 35, 20)

end

function script.Create()
	Turn (pipesh1, z_axis, math.rad(-56))
	Turn (pipesh2, z_axis, math.rad( 56))
	Move (pipesl, y_axis, 35)
	Move (pipesr, y_axis, 35)

	StartThread (SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
end

function script.QueryNanoPiece ()
	GG.LUPS.QueryNanoPiece (unitID, unitDefID, Spring.GetUnitTeam(unitID), claw1)
	return claw1
end

function script.Activate ()
	StartThread (Open) -- animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ()
	StartThread (Close)
end

function script.QueryBuildInfo ()
	return base
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)

	local explodables = {arm1, arm2, claw1, claw2, door}
	for i = 1, #explodables do
		if (2 * severity) > math.random() then
			Explode(explodables[i], sfxExplode + (brutal and (sfxSmoke + sfxFire + sfxExplodeOnHit) or 0))
		end
	end

	if not brutal then
		return 1
	else
		Explode (base, sfxShatter)
		return 2
	end
end
