-- $Id: dbg_debug.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    dbg_debug.lua
--  brief:   a gadget that prints debug data
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Debug",
    desc      = "Adds '." .. string.lower(Script.GetName()) ..
                " debug' and prints debug info  (for devs)",
    author    = "trepan",
    date      = "May 03, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local callIns = {
  'Shutdown',
  'Update',
  'AllowCommand',
  'CommandFallback',
  'UnitCreated',
  'UnitFinished',
  'UnitFromFactory',
  'UnitDestroyed',
  'UnitIdle',
  'UnitTaken',
  'UnitGiven',
}


local enabled = false
local origPrint = print

local function print(msg)
  Spring.Echo(Script.GetName() .. ': '.. msg)
end

--  one-shots
local printUpdate     = true
local printDrawWorld  = true
local printDrawScreen = true


local function SetState()
  for _,ciName in ipairs(callIns) do
    if (enabled) then
      gadgetHandler:UpdateCallIn(ciName)
    else
      gadgetHandler:RemoveCallIn(ciName)
    end
  end
end


local function DebugControl(cmd, line, words, playerID)
  if (playerID ~= 0) then
    Spring.SendMessageToPlayer(playerID, "Must be the host player")
    return true
  end

  if (#words <= 0) then
    enabled = not enabled
  else
    enabled = (words[1] == '1')
  end

  Spring.Echo('debugging is ' .. (enabled and 'enabled' or 'disabled'))

  SetState()

  return true
end


--------------------------------------------------------------------------------

function gadget:Initialize()
  if (not gadgetHandler:IsSyncedCode()) then
    gadgetHandler:RemoveGadget()
    return
  end

  print('DEBUG (Initialize)')
  cmd  = "debug"
  help = " [0|1]:  control call-in debug messages"
  gadgetHandler:AddChatAction(cmd, DebugControl, help)

  SetState()
end


function gadget:Shutdown()
  print('DEBUG (Shutdown)')
  gadgetHandler:RemoveChatAction("debug")
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Update()
  if (printUpdate) then
    printUpdate = false
    print('DEBUG (Update)')
  end
  return
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CmdName(id)
  if (id >= 0) then
    return CMD[id] or tostring(id)
  end
  local ud = UnitDefs[-id]
  if (ud) then
    return id .. ' <' .. ud.humanName .. '>'
  end
  return tostring(id)
end
    

function gadget:AllowCommand(unitID, unitDefID, unitTeam,
                             cmdID, cmdParams, cmdOptions)
  print('DEBUG (AllowCommand) '..unitID..' '.. CmdName(cmdID))
  return true
end


function gadget:CommandFallback(unitID, unitDefID, unitTeam,
                                cmdID, cmdParams, cmdOptions)
  local cmdName = CMD[cmdID] or tostring(cmdID)
  print('DEBUG (CommandFallback) '..unitID..' '.. CmdName(cmdID))
  return false
end


--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  print('DEBUG (UnitCreated) '..unitID..' '..unitDefID..' '..unitTeam)
  return
end


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  print('DEBUG (UnitFinished) '..unitID..' '..unitDefID..' '..unitTeam)
  return
end


function gadget:UnitFromFactory(unitID, unitDefID, unitTeam,
                                factID, factDefID, userOrders)
  print('DEBUG (UnitFromFactory) '
        ..unitID..' '..unitDefID..' '..unitTeam..' '
        ..factID..' '..factDefID..' '..tostring(userOrders))
  return
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  print('DEBUG (UnitDestroyed) '..unitID..' '..unitDefID..' '..unitTeam)
  return
end


function gadget:UnitIdle(unitID, unitDefID, unitTeam)
  print('DEBUG (UnitIdle) '..unitID..' '..unitDefID..' '..unitTeam)
  return
end


function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  print('DEBUG (UnitTaken) '
        ..unitID..' '..unitDefID..' '..unitTeam..' '..newTeam)
  return
end


function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  print('DEBUG (UnitGiven) '
        ..unitID..' '..unitDefID..' '..unitTeam..' '..oldTeam)
  return
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------











