function gadget:GetInfo()
	return {
		name      = "Vertical Swarm",
		desc      = "Causes chickens to pop out of dense swarms.",
		author    = "Google Frog",
		date      = "15 April 2013",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- CONFIG

local CHECK_FREQUENCY = 120 -- How often a single chicken is checked in frames
local RADIUS = 70 -- The checking radius
local NEAR_REQ = 8 -- How many units have to be in range to swarm (ALL UNITS with the same teamID)
local SNAP_HEIGHT = 40 -- How far up a chicken is placed
local HORIZONTAL_IMPULSE = 2 -- Impulse applied after snap
local VERTICAL_IMPULSE = 1.2*Game.gravity/70 -- Impulse applied after snap
local MAGIC_Y_CONSTANT = 10

local SwarmUnitDefs = {
	[UnitDefNames["chicken"].id] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local checkFrames = {}
local toRemove = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameFrame(n)
	local frame = checkFrames[n%CHECK_FREQUENCY]
	if frame then
		local data = frame.data
		local i = 1
		while i <= frame.count do
			local unitID = data[i].unitID
			local teamID = data[i].teamID
			if toRemove[unitID] or (not Spring.ValidUnitID(unitID)) then
				data[i] = data[frame.count]
				frame.count = frame.count - 1
				toRemove[unitID] = nil
			else
				-- Do things
				local x,y,z = Spring.GetUnitPosition(unitID)
				local units = Spring.GetUnitsInCylinder(x,z,RADIUS,teamID)
				local near = #units
				if near >= NEAR_REQ then
					local dir = math.random(0,2*math.pi)
					Spring.AddUnitImpulse(unitID, 0,MAGIC_Y_CONSTANT,0)
					Spring.MoveCtrl.Enable(unitID)
					Spring.MoveCtrl.SetPosition(unitID, x, y+SNAP_HEIGHT, z)
					Spring.MoveCtrl.Disable(unitID)
					local xDir = math.cos(dir)
					local zDir = math.sin(dir)
					Spring.AddUnitImpulse(unitID, xDir*HORIZONTAL_IMPULSE,-MAGIC_Y_CONSTANT+VERTICAL_IMPULSE,zDir*HORIZONTAL_IMPULSE)
				end
				i = i + 1
			end
		end
	end
end

local function addCheck(unitID, teamID)
	local n = math.floor(math.random(0,CHECK_FREQUENCY-1))
	if not checkFrames[n] then
		checkFrames[n] = {count = 0, data = {}}
	end
	
	local frame = checkFrames[n]
	frame.count = frame.count + 1
	frame.data[frame.count] = {unitID = unitID, teamID = teamID}
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if SwarmUnitDefs[unitDefID] then
		if toRemove[unitID] then
			toRemove[unitID] = nil
		else
			addCheck(unitID, teamID)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if SwarmUnitDefs[unitDefID] then
		toRemove[unitID] = true
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
