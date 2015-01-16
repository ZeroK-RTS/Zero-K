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
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc

local FAST_SPEED = 5.5*30 -- Speed which is considered fast.
local fastUnitDefs = {}
for i, ud in pairs(UnitDefs) do
	if ud.speed > FAST_SPEED then
		fastUnitDefs[i] = true
	end
end

local canHandleUnit = {}
local units = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local HandledUnitDefIDs = {
	[UnitDefNames["corrl"].id] = true,
	[UnitDefNames["armcir"].id] = true,
	[UnitDefNames["nsaclash"].id] = true,
	[UnitDefNames["missiletower"].id] = true,
	[UnitDefNames["screamer"].id] = true,
	[UnitDefNames["amphaa"].id] = true,
	[UnitDefNames["puppy"].id] = true,
	[UnitDefNames["fighter"].id] = true,
}

include("LuaRules/Configs/customcmds.h.lua")

local preventOverkillCmdDesc = {
	id      = CMD_PREVENT_OVERKILL,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Overkill.",
	action  = 'preventoverkill',
	tooltip	= 'Enable to prevent units shooting at units which are already going to die.',
	params 	= {0, "Prevent Overkill", "Fire at anything"}
}


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local incomingDamage = {}

function GG.OverkillPrevention_IsDoomed(targetID)
	if incomingDamage[targetID] then
		local frame = spGetGameFrame()
		if incomingDamage[targetID].timeout > frame then
			return incomingDamage[targetID].doomed
		end
	end
	return false
end

function GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, timeout, troubleVsFast)
	if not units[unitID] then
		return false
	end
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		if troubleVsFast then
			local unitDefID = Spring.GetUnitDefID(targetID)
			if fastUnitDefs[unitDefID] then
				damage = 0
			end
		end
		
		local frame = spGetGameFrame()
		if incomingDamage[targetID] then
			if incomingDamage[targetID].doomed then
				if incomingDamage[targetID].timeout > frame then
					spSetUnitTarget(unitID,0)
					return true
				else
					incomingDamage[targetID].damage = damage
					incomingDamage[targetID].doomed = false
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
		
		local armor = select(2,Spring.GetUnitArmored(targetID)) or 1
		local health = spGetUnitHealth(targetID)/armor
		if incomingDamage[targetID].damage > health/armor then
			incomingDamage[targetID].doomed = true
		end
	end
	
	return false
end

function gadget:UnitDestroyed(unitID)
	if incomingDamage[unitID] then
		incomingDamage[unitID] = nil
	end
end

--------------------------------------------------------------------------------
-- Command Handling
local function PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
	if canHandleUnit[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PREVENT_OVERKILL)
		
		if (cmdDescID) then
			preventOverkillCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = preventOverkillCmdDesc.params})
		end
		if state == 1 then
			if not units[unitID] then
				units[unitID] = true
			end
		else
			if units[unitID] then
				units[unitID] = nil
			end
		end
	end
	
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_PREVENT_OVERKILL] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_PREVENT_OVERKILL) then
		return true  -- command was not used
	end
	PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if HandledUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		canHandleUnit[unitID] = true
		PreventOverkillToggleCommand(unitID, {1})
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_PREVENT_OVERKILL)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end