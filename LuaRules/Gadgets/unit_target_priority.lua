
function gadget:GetInfo()
  return {
	name 	= "Target Priority",
	desc	= "Controls target priority because the engine seems to be based on random numbers.",
	author	= "Google Frog",
	date	= "September 25 2011",
	license	= "GNU GPL, v2 or later",
	layer	= 0,
	enabled = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then --SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local baseUnitPriority = {}

for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	local hp = ud.health
	local cost = ud.metalCost
	baseUnitPriority[i] = {priority = hp/cost, name = ud.humanName}
end

--[[
-- Sorting here makes the gadget fail, it is just good for looking at the priorities
table.sort(baseUnitPriority, function(a,b) return (a.priority > b.priority) end)
for i=1, #baseUnitPriority do
	Spring.Echo(baseUnitPriority[i].name .. "  " .. baseUnitPriority[i].priority)
end
--]]

-- Low return number = more worthwhile target
-- This seems to override everything, will need to reimplement emp things, badtargetcats etc...
-- Callin occurs every 16 frames

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	local newPriority = defPriority or 10
	
	los = spGetUnitLosState(enemy,data.allyTeam,false)
	if los then
		los = los.los
	end
	enemyUnitDef = spGetUnitDefID(enemy)
	
	local hp, maxHP = Spring.GetUnitHealth(targetID)
	if hp and maxHP then
		newPriority = hp/maxHP
	end
	GG.UnitEcho(targetID, newPriority)
	return true, newPriority
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end -- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
