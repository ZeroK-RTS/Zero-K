--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Decloak when damaged",
    desc      = "Decloaks units when they are damged",
    author    = "Google Frog",
    date      = "Nov 25, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring = Spring

local spSetUnitCloak = Spring.SetUnitCloak
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local recloakUnit = {}
local recloakUnits = 0
local recloakUnitID = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
					
	if recloakUnitID[unitID] then
		recloakUnit[recloakUnitID[unitID]].frames = 10
	else
		local cloak = Spring.GetUnitIsCloaked(unitID)
		if cloak then
			recloakUnits = recloakUnits + 1
			recloakUnit[recloakUnits] = {id = unitID, frames = 10}
			recloakUnitID[unitID] = recloakUnits
			Spring.SetUnitCloak(unitID, false, 10000)
		end
	end
	
end

function gadget:GameFrame(n)
 
	local i = 1
	while i <= recloakUnits do
		recloakUnit[i].frames = recloakUnit[i].frames - 1
		if recloakUnit[i].frames <= 0 then
			Spring.SetUnitCloak(recloakUnit[i].id, false, false)

			-- remove current unit and move last one to current position

			-- delete index
			recloakUnitID[recloakUnit[i].id] = nil

			-- do not to move if last element
            if i < recloakUnits then
				-- override
				recloakUnit[i] = recloakUnit[recloakUnits]

				-- update recloakUnitID for moved unit
				recloakUnitID[recloakUnit[i].id] = i
			end

			-- remove last
			recloakUnit[recloakUnits] = nil
			recloakUnits = recloakUnits - 1
		else
			i = i + 1
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
