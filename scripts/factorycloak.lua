include "constants.lua"

-- pieces
local base = piece "base"
local pad = piece "pad"
local doorl = piece "doorl"
local doorr = piece "doorr"
local roofl = piece "roofl"
local roofr = piece "roofr"
local arm1 = piece "arm1"
local arm2 = piece "arm2"
local claw1 = piece "claw1"
local claw2 = piece "claw2"
local pipesr = piece "pipesr"
local pipesl = piece "pipesl"

-- action pieces
local nanoPieces = { claw1 }
local smokePiece = { doorl, doorr, roofr, roofl, arm1, arm2 }

local function Open ()
	Signal (1)
	SetSignalMask (1)

	-- move the pieces
	Turn (roofl, z_axis, math.rad(-90), math.rad(90))
	Turn (roofr, z_axis, math.rad(90), math.rad(90))
	Turn (doorl, y_axis, math.rad(90), math.rad(150))
	Turn (doorr, y_axis, math.rad(-90), math.rad(150))
	
	Turn (arm1, x_axis, math.rad(20), math.rad(50))
	Turn (arm2, x_axis, math.rad(-75), math.rad(50))

	Move (pipesl, x_axis, -18.5, 18.5)
	Move (pipesr, x_axis, 18.5, 18.5)
	Move (pipesl, y_axis, 22, 22)
	Move (pipesr, y_axis, 22, 22)

	-- wait for them to move
	WaitForTurn (roofl, z_axis)
	WaitForTurn (roofr, z_axis)
	WaitForTurn (doorl, y_axis)
	WaitForTurn (doorr, y_axis)
	
	WaitForTurn (arm1, x_axis)
	WaitForTurn (arm2, x_axis)
		
	WaitForMove (pipesl, x_axis)
	WaitForMove (pipesr, x_axis)
	WaitForMove (pipesl, y_axis)
	WaitForMove (pipesr, y_axis)

	-- set values
	SetUnitValue(COB.YARD_OPEN, 1)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	--SetUnitValue(COB.BUGGER_OFF, 1)
	GG.Script.UnstickFactory(unitID)
end

local function Close()
	Signal (1)
	SetSignalMask (1)

	-- set values
	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetUnitValue(COB.INBUILDSTANCE, 0)

	-- move pieces back to original spots
	Turn (roofl, z_axis, 0, math.rad(30))
	Turn (roofr, z_axis, 0, math.rad(30))
	Turn (doorl, y_axis, 0, math.rad(50))
	Turn (doorr, y_axis, 0, math.rad(50))

	Turn (arm1, x_axis, 0, math.rad(50))
	Turn (arm2, x_axis, 0, math.rad(50))

	Move (pipesl, x_axis, 0, 3.7)
	Move (pipesr, x_axis, 0, 3.7)
	Move (pipesl, y_axis, 0, 4.4)
	Move (pipesr, y_axis, 0, 4.4)

end

function script.Create()
	Turn (pipesl, z_axis, math.rad(40))
	Turn (pipesr, z_axis, math.rad(-40))

	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces (unitID, nanoPieces)
end

function script.Activate ()
	StartThread (Open) -- animation needs its own thread because Sleep and WaitForTurn will not work otherwise
end

function script.Deactivate ()
	StartThread (Close)
end

function script.QueryBuildInfo ()
	return pad
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .5) then
		Explode (base, SFX.SHATTER)
		Explode (doorr, SFX.SHATTER)
		Explode (doorl, SFX.SHATTER)
		Explode (roofl, SFX.SHATTER)
		Explode (roofr, SFX.SHATTER)
		
		return 1
	else
		Explode (base, SFX.SHATTER)
		Explode (arm1, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (arm2, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (claw1, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (claw2, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (pipesl, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (pipesr, SFX.SMOKE + SFX.FALL + SFX.FIRE)

		-- giblets
		Explode (doorr, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (doorl, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (roofl, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (roofr, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)

		return 2
	end
end
