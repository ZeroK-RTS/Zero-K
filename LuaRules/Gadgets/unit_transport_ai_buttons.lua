-- $Id: unit_transport_ai_buttons.lua 3986 2009-02-22 01:56:11Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "TransportAIbuttons",
    desc      = "Adds buttons for transport AI widget",
    author    = "Licho",
    date      = "1.11.2007,30.3.2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--  �COMMON�  ------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  �SYNCED�  ------------------------------------------------------------------
--------------------------------------------------------------------------------


--Speed-ups
local FindUnitCmdDesc   = Spring.FindUnitCmdDesc;
local InsertUnitCmdDesc = Spring.InsertUnitCmdDesc;
local RemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc;
local GiveOrderToUnit   = Spring.GiveOrderToUnit;
local GetUnitDefID      = Spring.GetUnitDefID;
local GetTeamUnits      = Spring.GetTeamUnits;
local CMD_WAIT          = CMD.WAIT;
local CMD_ONOFF         = CMD.ONOFF;
local CMD_REPEAT        = CMD.REPEAT;
local CMD_MOVE_STATE    = CMD.MOVE_STATE;
local CMD_FIRE_STATE    = CMD.FIRE_STATE;
local CMD_ONOFF         = CMD.ONOFF

local gaiaID = Spring.GetGaiaTeamID();


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- commands

include("LuaRules/Configs/customcmds.h.lua")

local embarkCmdDesc = {
  id      = CMD_EMBARK, --defined in customcmds.h.lua
  type    = CMDTYPE.ICON,
  name    = 'Embark',
  cursor  = 'Attack', 
  action  = 'embark',
  tooltip = 'Transport to location, or queue Embark point (SHIFT)',
  params  = {"alt"}
}

local disembarkCmdDesc = {
  id      = CMD_DISEMBARK, --defined in customcmds.h.lua
  type    = CMDTYPE.ICON,
  name    = 'Disembark',
  cursor  = 'Attack', 
  action  = 'disembark',
  tooltip = 'Transport to location, or queue Disembark point (SHIFT)',
  params  = {"alt", "ctrl"}
}

local transportToCmdDesc = {
  id      = CMD_TRANSPORTTO, --defined in customcmds.h.lua
  type    = CMDTYPE.ICON_MAP, --has coordinate
  name    = 'TransportTo',
  hidden  = true,
  cursor  = 'Attack', 
  action  = 'transportto',
  tooltip = 'Transport To location.',
}

local transDefs = {
  [ UnitDefNames['corvalk'].id ] = true,
  [ UnitDefNames['corbtrans'].id ] = true,
}

local factDefs = {
  [ UnitDefNames['factorycloak'].id ] = true,
  [ UnitDefNames['factoryshield'].id ] = true,
  [ UnitDefNames['factoryspider'].id ] = true,
  [ UnitDefNames['factoryjump'].id ] = true,
  [ UnitDefNames['factoryhover'].id ] = true,
  [ UnitDefNames['factoryveh'].id ] = true,
  [ UnitDefNames['factorytank'].id ] = true,
  [ UnitDefNames['factoryamph'].id ] = true,
}

local hasTransports = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddCmdDesc(unitID)
  local insertID = 500
  InsertUnitCmdDesc(unitID, insertID+1, embarkCmdDesc);
  InsertUnitCmdDesc(unitID, insertID+2, disembarkCmdDesc);
  InsertUnitCmdDesc(unitID, insertID+3, transportToCmdDesc);
end

local function RemoveCmdDesc(unitID)
  local cmdEmbarkID = FindUnitCmdDesc(unitID, CMD_EMBARK)
  RemoveUnitCmdDesc(unitID, cmdEmbarkID);
  local cmdDisembarkID = FindUnitCmdDesc(unitID, CMD_DISEMBARK)
  RemoveUnitCmdDesc(unitID, cmdDisembarkID);
  local cmdTransportToID = FindUnitCmdDesc(unitID, CMD_TRANSPORTTO)
  RemoveUnitCmdDesc(unitID, cmdTransportToID);  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function IsTransportable(unitDefID)  
  ud = UnitDefs[unitDefID]
  if (ud == nil) then return false end
  udc = ud.springCategories
  return (udc~= nil and ud.speed > 0 and not ud.canFly)
end


function gadget:UnitCreated(unitID, unitDefID, teamID)
  if (hasTransports[teamID]) then 
    if (IsTransportable(unitDefID) or factDefs[unitDefID]) then AddCmdDesc(unitID) end
  elseif (transDefs[unitDefID]) then
    hasTransports[teamID] = true
    for _, id in pairs(GetTeamUnits(teamID)) do
      local def = GetUnitDefID(id)
      if (IsTransportable(def) or factDefs[def]) then AddCmdDesc(id) end
    end
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if (transDefs[unitDefID]) then
		local teamUnit =GetTeamUnits(teamID)
		local haveAnotherTransport =false
		for _, id in pairs(teamUnit) do
			local def = GetUnitDefID(id)
			if id~=unitID and (transDefs[def]) then
				haveAnotherTransport = true
				break
			end
		end
		if not haveAnotherTransport then
			hasTransports[teamID] = false
			for _, id in pairs(teamUnit) do
				local def = GetUnitDefID(id)
				if (IsTransportable(def) or factDefs[def]) then RemoveCmdDesc(id) end
			end
		end
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	gadget:UnitCreated(unitID, unitDefID, teamID) --add embark/disembark command
	gadget:UnitDestroyed(unitID, unitDefID, oldTeamID) --remove embark/disembark command
end



function gadget:UnitGiven(unitID) -- minor hack unrelated to transport ai - enable captured unit
    GiveOrderToUnit(unitID, CMD_ONOFF, { 1 }, { })
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  gadgetHandler:RegisterCMDID(CMD_EMBARK);
  gadgetHandler:RegisterCMDID(CMD_DISEMBARK);

  for _,unitID in pairs(Spring.GetAllUnits()) do
    local unitDefID = GetUnitDefID(unitID);
    gadget:UnitCreated(unitID, unitDefID, Spring.GetUnitTeam(unitID));
  end
  
  gadgetHandler:RegisterGlobal('taiEmbark', taiEmbark)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_EMBARK] = true, [CMD_DISEMBARK] = true, [CMD_TRANSPORTTO] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if (cmdID == CMD_EMBARK) or (cmdID == CMD_DISEMBARK) or (cmdID == CMD_TRANSPORTTO) then
	if cmdID == CMD_TRANSPORTTO and (cmdOptions.shift) then	return true end --transportTo cannot properly support queue, block when in SHIFT
    local opt = {"alt"}
	local embark =true
    if (cmdID == CMD_DISEMBARK and cmdOptions.shift) then 
		opt[#opt+1] = "ctrl"  --Note: Disembark only when in SHIFT mode ("ctrl" is used to mark disembark point)
		embark = false --prevent enter into priority queue
	end
	if (cmdOptions.shift) then opt[#opt+1] = "shift" end
	if cmdID == CMD_TRANSPORTTO then --only CMD_TRANSPORTTO have coordinate parameter.
		GiveOrderToUnit(unitID, CMD.MOVE, {cmdParams[1],cmdParams[2],cmdParams[3]}, opt) -- This move command determine transport_AI destination.
	end
	GiveOrderToUnit(unitID, CMD_WAIT, {}, opt) --Note: transport AI use CMD_WAIT to identify transport unit. "Ctrl" will flag enter/exit transport point.
	SendToUnsynced("taiEmbark", unitID, teamID, embark, cmdOptions.shift) --this will put unit into transport_AI's priority (see: unit_transport_ai.lua)
    return false
  end
  return true
end


--------------------------------------------------------------------------------
--  �SYNCED�  ------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  �UNSYNCED�  ----------------------------------------------------------------
--------------------------------------------------------------------------------

function WrapToLuaUI(_,unitID,teamID, embark, shift)
  if (Script.LuaUI('taiEmbark')) then
    Script.LuaUI.taiEmbark(unitID,teamID, embark, shift)
  end
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction('taiEmbark',WrapToLuaUI)
end

--------------------------------------------------------------------------------
--  �UNSYNCED�  ----------------------------------------------------------------
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  �COMMON�  ------------------------------------------------------------------
--------------------------------------------------------------------------------
