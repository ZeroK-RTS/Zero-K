include "constants.lua"
include "plates.lua"

-- pieces
local base = piece "base"
local house = piece "house"
local pad = piece "pad"
local arm1 = piece "arm1"
local arm2 = piece "arm2"
local claw1 = piece "claw1"
local claw2 = piece "claw2"
local nano = piece "nano"

-- action pieces
local nanoPieces = { claw1 }
local smokePiece = { house, base }

local function Open ()
	SetSignalMask (1)

	-- move the pieces
	Turn (arm1, x_axis, math.rad(20), math.rad(50))
	Turn (arm2, x_axis, math.rad(-75), math.rad(50))

	-- wait for them to move
	WaitForTurn (arm1, x_axis)
	WaitForTurn (arm2, x_axis)

	-- set values
	SetUnitValue(COB.YARD_OPEN, 1)
	SetInBuildDistance(true)
	--SetUnitValue(COB.BUGGER_OFF, 1)
end

local function Close()
	Signal (1)

	-- set values
	SetUnitValue(COB.YARD_OPEN, 0)
	--SetUnitValue(COB.BUGGER_OFF, 0)
	SetInBuildDistance(false)

	-- move pieces back to original spots
	Turn (arm1, x_axis, 0, math.rad(50))
	Turn (arm2, x_axis, 0, math.rad(50))
end

function script.Create()
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
		Explode (house, SFX.SHATTER)
		
		return 1
	else
		Explode (house, SFX.SHATTER)
		Explode (arm1, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (arm2, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (claw1, SFX.SMOKE + SFX.FALL + SFX.FIRE)
		Explode (claw2, SFX.SMOKE + SFX.FALL + SFX.FIRE)

		-- giblets
		Explode (arm1, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode (arm2, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)

		return 2
	end
end
