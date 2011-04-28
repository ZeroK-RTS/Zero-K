--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Mortal Shield",
    desc      = "Force-kills undying shield units",
    author    = "KingRaptor",
    date      = "Nov 25, 2010",
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitHealth = Spring.GetUnitHealth

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local shields = {
	"corthud",
	"core_spectre",
	"corjamt",
	"coradvcom",
	"chicken_shield",
	"chicken_tiamat",
}

local shieldUnits = {}
for _,name in pairs(shields) do
	if UnitDefNames[name] then 
		shieldUnits[UnitDefNames[name].id] = true 
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local stuffToDestroy = {count = 0, data = {}}

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if shieldUnits[unitDefID] then
		local health = spGetUnitHealth(unitID)
		if health < 0.1 then
			stuffToDestroy.count = stuffToDestroy.count + 1
			stuffToDestroy.data[stuffToDestroy.count] = unitID
			
		end
	end	
end

function gadget:GameFrame(n)
	if stuffToDestroy.count ~= 0 then
		for i = 1, stuffToDestroy.count do
			local unitID = stuffToDestroy.data[i]
			if Spring.ValidUnitID(unitID) then
				Spring.DestroyUnit(unitID)
			end
		end
		stuffToDestroy.count = 0
		stuffToDestroy.data = {}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
