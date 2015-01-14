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
local spValidUnitID         = Spring.ValidUnitID
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitTeam         = Spring.GetUnitTeam
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitLosState     = Spring.GetUnitLosState
local spGetCommandQueue     = Spring.GetCommandQueue
local spSetUnitTarget       = Spring.SetUnitTarget
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitStates       = Spring.GetUnitStates

local CMD_ATTACK		= CMD.ATTACK
local CMD_OPT_INTERNAL 	= CMD.OPT_INTERNAL
local CMD_FIRE_STATE 	= CMD.FIRE_STATE
local CMD_INSERT 		= CMD.INSERT
local CMD_REMOVE 		= CMD.REMOVE

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local incomingDamage = {}

function GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, timeout)
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local frame = Spring.GetGameFrame()
		if incomingDamage[targetID] then
			local health = Spring.GetUnitHealth(targetID)
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