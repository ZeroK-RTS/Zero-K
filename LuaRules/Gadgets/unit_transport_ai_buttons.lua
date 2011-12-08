-- $Id: unit_transport_ai_buttons.lua 3986 2009-02-22 01:56:11Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "TransportAIbuttons",
    desc      = "Adds buttons for transport AI widget",
    author    = "Licho",
    date      = "1.11.2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--  «COMMON»  ------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  «SYNCED»  ------------------------------------------------------------------
--------------------------------------------------------------------------------


--Speed-ups
local FindUnitCmdDesc   = Spring.FindUnitCmdDesc;
local InsertUnitCmdDesc = Spring.InsertUnitCmdDesc;
local GiveOrderToUnit   = Spring.GiveOrderToUnit;
local GetUnitDefID      = Spring.GetUnitDefID;
local GetTeamUnits      = Spring.GetTeamUnits;
local CMD_WAIT          = CMD.WAIT;
local CMD_CLOAK         = CMD.CLOAK;
local CMD_ONOFF         = CMD.ONOFF;
local CMD_REPEAT        = CMD.REPEAT;
local CMD_MOVE_STATE    = CMD.MOVE_STATE;
local CMD_FIRE_STATE    = CMD.FIRE_STATE;

local gaiaID = Spring.GetGaiaTeamID();


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- commands

include("LuaRules/Configs/customcmds.h.lua")

local embarkCmdDesc = {
  id      = CMD_EMBARK,
  type    = CMDTYPE.ICON,
  name    = 'Embark',
  cursor  = 'Attack', 
  action  = 'embark',
  tooltip = 'Embark unit into air transport',
  params  = {"alt"}
}

local disembarkCmdDesc = {
  id      = CMD_DISEMBARK,
  type    = CMDTYPE.ICON,
  name    = 'Disembark',
  cursor  = 'Attack', 
  action  = 'disembark',
  tooltip = 'Disembark unit from air transport',
  params  = {"alt", "ctrl"}
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
}

local hasTransports = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddCmdDesc(unitID)
  local insertID = 
    FindUnitCmdDesc(unitID, CMD_CLOAK)      or
    FindUnitCmdDesc(unitID, CMD_ONOFF)      or
    FindUnitCmdDesc(unitID, CMD_REPEAT)     or
    FindUnitCmdDesc(unitID, CMD_MOVE_STATE) or
    FindUnitCmdDesc(unitID, CMD_FIRE_STATE) or
    123456; -- back of the pack
  InsertUnitCmdDesc(unitID, insertID + 1, embarkCmdDesc);
  InsertUnitCmdDesc(unitID, insertID + 2, disembarkCmdDesc);
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function IsTransport(unitDefID) 
  ud = UnitDefs[unitDefID]
  return ((ud~= nil and ud.isTransport and ud.canFly))
end


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
    for _, id in ipairs(GetTeamUnits(teamID)) do
      local def = GetUnitDefID(id)
      if (IsTransportable(def) or factDefs[def]) then AddCmdDesc(id) end
    end
  end
end


function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	gadget:UnitCreated(unitID, unitDefID, teamID)
end



function gadget:UnitGiven(unitID) -- minor hack unrelated to transport ai - enable captured unit
    GiveOrderToUnit(unitID, CMD.ONOFF, { 1 }, { })
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  gadgetHandler:RegisterCMDID(CMD_EMBARK);
  gadgetHandler:RegisterCMDID(CMD_DISEMBARK);

  for _,unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = GetUnitDefID(unitID);
    gadget:UnitCreated(unitID, unitDefID, Spring.GetUnitTeam(unitID));
  end
  
  gadgetHandler:RegisterGlobal('taiEmbark', taiEmbark)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if (cmdID == CMD_EMBARK) then
    local opt = {"alt"}
    if (cmdOptions.shift) then table.insert(opt,"shift") end
    Spring.GiveOrderToUnit(unitID, CMD_WAIT, {}, opt)
    SendToUnsynced("taiEmbark", unitID, teamID, true, cmdOptions.shift)
    return false
  elseif (cmdID == CMD_DISEMBARK) then
    local opt = {"alt", "ctrl"}
    if (cmdOptions.shift) then table.insert(opt,"shift") end
    Spring.GiveOrderToUnit(unitID, CMD_WAIT, {}, opt)
    SendToUnsynced("taiEmbark", unitID, teamID, false, cmdOptions.shift)
    return false
  end
  return true
end


--------------------------------------------------------------------------------
--  «SYNCED»  ------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  «UNSYNCED»  ----------------------------------------------------------------
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
--  «UNSYNCED»  ----------------------------------------------------------------
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  «COMMON»  ------------------------------------------------------------------
--------------------------------------------------------------------------------
