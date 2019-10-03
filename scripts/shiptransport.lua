include "constants.lua"

local AttachUnit = Spring.UnitScript.AttachUnit
local DropUnit = Spring.UnitScript.DropUnit
-- pieces
local base, platform, fan = piece("base", "platform", "fan")
local wake1, wake2 = piece("wake1", "wake2")
local load_arm, load_shoulder = piece("load_arm", "load_shoulder")
local slot1 = piece "slot1"

local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitRulesParam = Spring.GetUnitRulesParam

-- constants
local SIG_Move = 1
local SIG_COPY = 2

local LOAD_SPEED_XZ = 200
local LOAD_SPEED_Y = 80

local PRIVATE = {private = true}
local DEFAULT_SIGHT = UnitDefs[unitDefID].losRadius

-- local vars
local smokePiece = { base }
local loadedUnitID = nil
local emptyTable = {}

local function Wake()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			EmitSfx(wake1, 2)
			EmitSfx(wake2, 2)
		end
		Sleep(200)
	end
end

local function ResetSensors()
	Signal(SIG_COPY)
	
	spSetUnitRulesParam(unitID, "radarRangeOverride", 0, PRIVATE)
	spSetUnitRulesParam(unitID, "sonarRangeOverride", 0, PRIVATE)
	spSetUnitRulesParam(unitID, "jammingRangeOverride", 0, PRIVATE)
	spSetUnitRulesParam(unitID, "sightRangeOverride", DEFAULT_SIGHT, PRIVATE)
	
	GG.UpdateUnitAttributes(unitID)
end

local function CopySensors(passengerID)
	if not (Spring.ValidUnitID(passengerID) and Spring.GetUnitIsTransporting(unitID)) then
		ResetSensors()
		return false
	end
	local pUnitDefID = Spring.GetUnitDefID(passengerID)
	if not pUnitDefID then
		ResetSensors()
		return false
	end
	local pUnitDef = UnitDefs[pUnitDefID]
	if not pUnitDef then
		ResetSensors()
		return false
	end
	
	local radarOverride = spGetUnitRulesParam(passengerID, "radarRangeOverride") or pUnitDef.radarRadius
	local sonarOverride = spGetUnitRulesParam(passengerID, "sonarRangeOverride") or pUnitDef.sonarRadius
	local jammerOverride = spGetUnitRulesParam(passengerID, "jammingRangeOverride") or pUnitDef.jammerRadius
	local sightOverride = spGetUnitRulesParam(passengerID, "sightRangeOverride") or pUnitDef.losRadius
	
	if (not Spring.GetUnitStates(passengerID).active) or (spGetUnitRulesParam(passengerID, "att_abilityDisabled") == 1) then
		radarOverride = 0
		sonarOverride = 0
		jammerOverride = 0
	end
	
	spSetUnitRulesParam(unitID, "radarRangeOverride", radarOverride, PRIVATE)
	spSetUnitRulesParam(unitID, "sonarRangeOverride", sonarOverride, PRIVATE)
	spSetUnitRulesParam(unitID, "jammingRangeOverride", jammerOverride, PRIVATE)
	spSetUnitRulesParam(unitID, "sightRangeOverride", math.max(sightOverride, DEFAULT_SIGHT), PRIVATE)
	
	GG.UpdateUnitAttributes(unitID)
	
	-- Need to repeat if the unit can change state
	return true
end

local function CopyTransportieeSensors(passengerID)
	Signal(SIG_COPY)
	SetSignalMask(SIG_COPY)
	
	while CopySensors(passengerID) do
		Sleep(500)
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
	
	if loadedUnitID then
		return
	end
	
	StartThread(CopyTransportieeSensors, passengerID)
	
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
		local ySpeed = LOAD_SPEED_XZ * math.abs(dy) / dist3D
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
	if not loadedUnitID then
		return
	end
	
	local px1, py1, pz1 = Spring.GetUnitBasePosition(unitID)
	local surfaceY = math.max(0, Spring.GetGroundHeight(px1, pz1))
	if (py1 - surfaceY > 10) then
		-- don't allow unloading when flying
		return
	end
	
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
		local ySpeed = LOAD_SPEED_XZ * math.abs(dy) / dist3D
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
	
	ResetSensors()
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
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	--StartThread(PingHeading)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		return 1 -- corpsetype
	elseif (severity <= 0.5) then
		Explode(fan, SFX.FALL)
		return 1 -- corpsetype
	else
		Explode(fan, SFX.FALL)
		return 2 -- corpsetype
	end
end
