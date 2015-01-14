--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Overkill Prevention",
    desc      = "Prevents some units from firing at units which are going to be killed by incoming missiles.",
    author    = "Google Frog",
    date      = "14 Jan 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spValidUnitID    = Spring.ValidUnitID
local spSetUnitTarget = Spring.SetUnitTarget
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame  = Spring.GetGameFrame

local FAST_SPEED = 5.5*30 -- Speed which is considered fast.
local fastUnitDefs = {}
for i, ud in pairs(UnitDefs) do
	if ud.speed > FAST_SPEED then
		fastUnitDefs[i] = true
	end
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local incomingDamage = {}

function GG.OverkillPrevention_IsDoomed(targetID)
	local frame = spGetGameFrame()
	if incomingDamage[targetID] then
		local health = spGetUnitHealth(targetID)
		if health < incomingDamage[targetID].damage then
			if incomingDamage[targetID].timeout > frame then
				return true
			end
		end
	end
	return false
end

function GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, timeout, troubleVsFast)
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		if troubleVsFast then
			local unitDefID = Spring.GetUnitDefID(targetID)
			if fastUnitDefs[unitDefID] then
				damage = 0
			end
		end
		
		local frame = spGetGameFrame()
		if incomingDamage[targetID] then
			local health = spGetUnitHealth(targetID)
			if health < incomingDamage[targetID].damage then
				if incomingDamage[targetID].timeout > frame then
					spSetUnitTarget(unitID,0)
					return true
				else
					incomingDamage[targetID].damage = damage
				end
			else
				incomingDamage[targetID].damage = incomingDamage[targetID].damage + damage
			end
			incomingDamage[targetID].timeout = math.max(incomingDamage[targetID].timeout, frame + timeout)
		else
			incomingDamage[targetID] = {
				damage = damage,
				timeout = frame + timeout,
			}
		end
	end
	return false
end

function gadget:UnitDestroyed(unitID)
	if incomingDamage[unitID] then
		incomingDamage[unitID] = nil
	end
end