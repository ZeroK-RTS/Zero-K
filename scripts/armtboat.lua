include "constants.lua"

local AttachUnit = Spring.UnitScript.AttachUnit
local DropUnit = Spring.UnitScript.DropUnit
-- pieces
local base, platform, fan = piece("base", "platform", "fan")
local wake1, wake2 = piece("wake1", "wake2")
local load_arm, load_shoulder = piece("load_arm", "load_shoulder")
local slot1 = piece "slot1"

-- constants
local SIG_Move = 1

local LOAD_SPEED_XZ = 200
local LOAD_SPEED_Y = 80


-- local vars
local smokePiece = { base }
local loadedUnitID = nil
local emptyTable = {}

local function Wake()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		EmitSfx(wake1,  2)
		EmitSfx(wake2,  2)
		Sleep(200)
	end
end

function ForceDropUnit()
	if not loadedUnitID then return end
	
	local x,y,z = Spring.GetUnitPosition(loadedUnitID) --cargo position
	local _,ty = Spring.GetUnitPosition(unitID) --transport position
	local vx,vy,vz = Spring.GetUnitVelocity(unitID) --transport speed
	DropUnit(loadedUnitID) --detach cargo
	local transRadius = Spring.GetUnitRadius(unitID)
	Spring.SetUnitPosition(loadedUnitID, x,math.min(y, ty-transRadius),z) --set cargo position below transport
	Spring.AddUnitImpulse(loadedUnitID,0,4,0) --hax to prevent teleport to ground
	Spring.AddUnitImpulse(loadedUnitID,0,-4,0) --hax to prevent teleport to ground
	Spring.SetUnitVelocity(loadedUnitID,0,0,0) --remove any random velocity caused by collision with transport (especially Spring 91)
	Spring.AddUnitImpulse(loadedUnitID,vx,vy,vz) --readd transport momentum
		
	loadedUnitID = nil
end

function script.TransportPickup(passengerID)
	-- no napping!
	local passengerTeam = Spring.GetUnitTeam(passengerID)
	local ourTeam = Spring.GetUnitTeam(unitID)
	if not Spring.AreTeamsAllied(passengerTeam, ourTeam) then
		return
	end
	
	if loadedUnitID then return end
	SetUnitValue(COB.BUSY, 1)
	local px1, py1, pz1 = Spring.GetUnitBasePosition(unitID)
	local px2, py2, pz2 = Spring.GetUnitBasePosition(passengerID)
	local dx, dy, dz = px2 - px1, py2 - py1, pz2 - pz1
	local heading = (Spring.GetHeadingFromVector(dx, dz) - Spring.GetUnitHeading(unitID))/32768*math.pi
	local sqDist2D = dx*dx + dz*dz
	local dist2D = math.sqrt(sqDist2D)
	local dist3D = math.sqrt(sqDist2D + dy*dy)
	
	Turn(load_shoulder, y_axis, heading)
	Move(load_shoulder, y_axis, dy)
	Move(load_arm, z_axis, dist2D)
	
	if (dist3D > 0) then
		local xzSpeed = LOAD_SPEED_XZ * dist2D / dist3D
		local  ySpeed = LOAD_SPEED_XZ * math.abs(dy) / dist3D
		Move(load_arm, z_axis, 0, xzSpeed) -- has to be called before AttachUnit, because in some cases calling Move doesn't work while the piece has an unit attached to it
		Move(load_shoulder, y_axis, 0, ySpeed)
	end
	AttachUnit(load_arm, passengerID)
	
	WaitForMove(load_arm, z_axis)
	WaitForMove(load_shoulder, y_axis)
	AttachUnit(slot1, passengerID)
	loadedUnitID = passengerID
	SetUnitValue(COB.BUSY, 0)
end

-- note x, y z is in worldspace
function script.TransportDrop(passengerID, x, y, z)
	if not loadedUnitID then return end
	
	local px1, py1, pz1 = Spring.GetUnitBasePosition(unitID)
	local surfaceY = math.max(0, Spring.GetGroundHeight(px1, pz1))
	if (py1 - surfaceY > 10) then return end -- don't allow unloading when flying
	
	SetUnitValue(COB.BUSY, 1)
	Spring.MoveCtrl.Enable(unitID) -- freeze in place during unloading to make sure the passenger gets unloaded at the right place
	
	y = y - Spring.GetUnitHeight(passengerID) - 10
	local dx, dy, dz = x - px1, y - py1, z - pz1
	local heading = (Spring.GetHeadingFromVector(dx, dz) - Spring.GetUnitHeading(unitID))/32768*math.pi
	local sqDist2D = dx*dx + dz*dz
	local dist2D = math.sqrt(sqDist2D)
	local dist3D = math.sqrt(sqDist2D + dy*dy)
	
	AttachUnit(load_arm, passengerID)
	Turn(load_shoulder, y_axis, heading)
	if (dist3D > 0) then
		local xzSpeed = LOAD_SPEED_XZ * dist2D / dist3D
		local  ySpeed = LOAD_SPEED_XZ * math.abs(dy) / dist3D
		Move(load_shoulder, y_axis, dy, ySpeed)
		Move(load_arm, z_axis, dist2D, xzSpeed)
		WaitForMove(load_arm, z_axis)
		WaitForMove(load_shoulder, y_axis)
	end
	
	DropUnit(passengerID)
	loadedUnitID = nil
	Move(load_arm, z_axis, 0)
	Move(load_shoulder, y_axis, 0)
	
	Spring.MoveCtrl.Disable(unitID)
	SetUnitValue(COB.BUSY, 0)
	Spring.GiveOrderToUnit(unitID, CMD.WAIT, emptyTable, 0)	-- WAITWAIT magic to make unit continue with any orders it has
	Spring.GiveOrderToUnit(unitID, CMD.WAIT, emptyTable, 0)
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
	StartThread(SmokeUnit, smokePiece)
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
