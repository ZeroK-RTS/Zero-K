--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Gunship Climb",
		desc      = "Controls gunship climb speed",
		author    = "GoogleFrog",
		date      = "13 January 2018",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local UPDATE_PERIOD = 2

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Shared functions
local spGetUnitDefID = Spring.GetUnitDefID
local getMovetype = Spring.Utilities.getMovetype

local gunshipDef = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if getMovetype(ud) == 1 then -- Only ground or sea units
		gunshipDef[i] = {
			maxClimb = ud.verticalSpeed*UPDATE_PERIOD,
			speedCap = math.min(12, ud.verticalSpeed*0.8),
		}
	end
end

local gunships = IterableMap.New()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Climb Handling

local function CheckClimb(unitID, unitData)
	local _,_,_, x, y, z = Spring.GetUnitPosition(unitID, true)
	if not x then
		return true -- Remove
	end
	
	local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	
	if y - unitData.y > unitData.def.maxClimb or Spring.GetGroundHeight(x + vx*UPDATE_PERIOD, z + vz*UPDATE_PERIOD) > y + math.max(0, vy*UPDATE_PERIOD) then
		unitData.x, unitData.y, unitData.z = x, y + unitData.def.speedCap, z
		Spring.SetUnitVelocity(unitID, vx*0.1, unitData.def.speedCap, vz*0.1)
		return
	end
	
	unitData.x, unitData.y, unitData.z = x, y, z
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if gunshipDef[unitDefID] then
		local _,_,_, x, y, z = Spring.GetUnitPosition(unitID, true)
		gunships.Add(unitID,
			{
				unitDefID = unitDefID,
				def = gunshipDef[unitDefID],
				x = x,
				y = y,
				z = z
			}
		)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	gunships.Remove(unitID)
end

function gadget:Initialize()
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
end

function gadget:GameFrame(n)
	if n%UPDATE_PERIOD == 0 then
		gunships.Apply(CheckClimb)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
