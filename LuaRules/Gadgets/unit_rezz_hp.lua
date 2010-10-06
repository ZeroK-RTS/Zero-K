-- $Id: unit_terraform.lua 3299 2008-11-25 07:25:57Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Rezz Hp changer",
    desc      = "Sets rezzed units to full hp ",
    author    = "Google Frog",
    date      = "Nov 30, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  no unsynced code
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Speedups

local spSetUnitHealth = Spring.SetUnitHealth
local spGetUnitHealth = Spring.GetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local units = {}
local unitsCount = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--It looks like rezzed units HP is set just after UnitCreated so their HP has to be changed 1 frame latter

local terraunitDefID = UnitDefNames["terraunit"].id

function gadget:UnitCreated(unitID, unitDefID)
	local health, maxHealth = spGetUnitHealth(unitID)
	if (health > 5) and unitDefID ~= terraunitDefID then
		spSetUnitHealth(unitID, maxHealth)
		unitsCount = unitsCount+1
		units[unitsCount] = {id = unitID, hp = maxHealth}
	end
  
end

function gadget:GameFrame(n)
 
	if (unitsCount ~= 0) then
		for i=1, unitsCount do
			local health, maxHealth = spGetUnitHealth(units[i].id)
			if health then
				local hpercent = health/units[i].hp
				if hpercent > 0.045 and hpercent < 0.055 then
					spSetUnitHealth(units[i].id, units[i].hp)
				end
			end
			units[i] = nil
		end
		
		unitsCount = 0
	
	end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------