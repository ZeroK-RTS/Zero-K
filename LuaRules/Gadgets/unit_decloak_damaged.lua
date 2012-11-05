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
local spAreTeamsAllied = Spring.AreTeamsAllied

local spSetUnitCloak = Spring.SetUnitCloak
local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local recloakUnit = {}
local recloakUnits = 0
local recloakUnitID = {}

local noFFWeaponDefs = {}
for i=1,#WeaponDefs do
  local wd = WeaponDefs[i]
  if wd.customParams and wd.customParams.nofriendlyfire then
    noFFWeaponDefs[i] = true
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function GG.PokeDecloakUnit(unitID, duration)
	duration = duration or 10
	if recloakUnitID[unitID] then
		recloakUnit[recloakUnitID[unitID]].frames = duration
	else
		local cloak = Spring.GetUnitIsCloaked(unitID)
		if cloak then
			recloakUnits = recloakUnits + 1
			recloakUnit[recloakUnits] = {id = unitID, frames = duration}
			recloakUnitID[unitID] = recloakUnits
			Spring.SetUnitCloak(unitID, false, 10000)
		end
	end

end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
	
	if damage > 0 and
		not (attackerTeam and
		weaponID and
		noFFWeaponDefs[weaponID] and
		attackerID ~= unitID and
		spAreTeamsAllied(unitTeam, attackerTeam)) then
		
		GG.PokeDecloakUnit(unitID)
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
