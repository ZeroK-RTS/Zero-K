include "constants.lua"

local AttachUnit = Spring.UnitScript.AttachUnit
local DropUnit = Spring.UnitScript.DropUnit
-- pieces
local base, platform, fan = piece("base", "platform", "fan")
local wake1, wake2 = piece("wake1", "wake2")
local load_arm, load_shoulder = piece("load_arm", "load_shoulder")
local slot1 = piece "slot1"

-- constants
local LOAD_SPEED_XZ = 200
local LOAD_SPEED_Y = 80


-- local vars
smokePieces = { base }
local loaded = false

local function Wake()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		EmitSfx( wake1,  2 )
		EmitSfx( wake2,  2 )
		Sleep( 200)
	end
end

function script.TransportPickup(passengerID)
	-- no napping!
	local passengerTeam = Spring.GetUnitTeam(passengerID)
	local ourTeam = Spring.GetUnitTeam(unitID)
	if not Spring.AreTeamsAllied(passengerTeam, ourTeam) then
		return
	end
	
	if loaded then return end
	SetUnitValue(COB.BUSY, 1)
	local px1, py1, pz1 = Spring.GetUnitBasePosition(unitID)
	local px2, py2, pz2 = Spring.GetUnitBasePosition(passengerID)
	local dx, dy , dz = px2 - px1, py2 - py1, pz2 - pz1
	local heading = (Spring.GetHeadingFromVector(dx, dz) - Spring.GetUnitHeading(unitID))/32768*math.pi
	local dist = (dx^2 + dy^2)^0.5
	
	Turn(load_shoulder, y_axis, heading)
	Move(load_shoulder, y_axis, dy)
	Move(load_arm, z_axis, dist)
	AttachUnit(load_arm, passengerID)
	
	Move(load_arm, z_axis, 0, LOAD_SPEED_XZ)
	Move(load_shoulder, y_axis, 0, LOAD_SPEED_Y )
	WaitForMove(load_arm, z_axis)
	WaitForMove(load_shoulder, y_axis)	
	AttachUnit(slot1, passengerID)
	loaded = true
	SetUnitValue(COB.BUSY, 0)
end

-- note x, y z is in worldspace
function script.TransportDrop(passengerID, x, y, z)
	if not loaded then return end
	SetUnitValue(COB.BUSY, 1)
	y = y - Spring.GetUnitHeight(passengerID) - 10
	local px1, py1, pz1 = Spring.GetUnitBasePosition(unitID)
	local dx, dy , dz = x - px1, y - py1, z - pz1
	local heading = (Spring.GetHeadingFromVector(dx, dz) - Spring.GetUnitHeading(unitID))/32768*math.pi
	local dist = (dx^2 + dy^2)^0.5
	local angleV = math.atan(dy/dist)
	dist = dist/math.cos(angleV)	-- convert 2d distance (adjacent) to 3d dist (hypotenuse)
	
	AttachUnit(load_arm, passengerID)
	Turn(load_shoulder, y_axis, heading)
	Move(load_shoulder, y_axis, dy, LOAD_SPEED_Y )
	Move(load_arm, z_axis, dist, LOAD_SPEED_XZ)
	WaitForMove(load_arm, z_axis)
	WaitForMove(load_shoulder, y_axis)
	
	DropUnit(passengerID)
	loaded = false
	Move(load_arm, z_axis, 0)
	Move(load_shoulder, y_axis, 0)
	SetUnitValue(COB.BUSY, 0)	
end

function script.StartMoving()
	StartThread(Wake)
end

function script.StopMoving()
	Signal(SIG_Move)
end

local function PingHeading()
	while true do
		Spring.Echo(Spring.GetUnitHeading(unitID))
		Sleep(2000)
	end
end

function script.Create()
	StartThread(SmokeUnit)
	--StartThread(PingHeading)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(fan, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, sfxNone)
		Explode(fan, sfxShatter)	
		return 1 -- corpsetype
	else
		Explode(base, sfxShatter)
		Explode(fan, sfxExplode)	
		return 2 -- corpsetype
	end
end
