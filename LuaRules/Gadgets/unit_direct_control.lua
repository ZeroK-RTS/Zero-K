-- $Id: unit_direct_control.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_direct_control.lua
--  brief:   first person unit control
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "DirectControl",
    desc      = "Block direct control (FPS) for units",
    author    = "trepan",
    date      = "Jul 10, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--// changeset by author:
--  jK: block fps mode for all buildings/not mobile units

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local enabled = true

local badUnits = {
	"blackdawn",
	"armrock",
	"armsptk",
	"corstorm",
	"nsaclash",
	"logkoda",
	"cormist",
	"tawf114",
	"puppy",
	"dante",
	"hoverassault",
	"armmerl",
	"shieldarty",
	"armcarry",
	"cornukesub",
}

local badUnitDefs = {}


--------------------------------------------------------------------------------

local function AllowAction(playerID)
--[[
  if (playerID ~= 0) then
    Spring.SendMessageToPlayer(playerID, "Must be the host player")
    return false
  end
]]--
  if (not Spring.IsCheatingEnabled()) then
    Spring.SendMessageToPlayer(playerID, "Cheating must be enabled")
    return false
  end
  return true
end


local function ChatControl(cmd, line, words, playerID)
  if (AllowAction(playerID)) then
    if (#words == 0) then
      enabled = not enabled
    else
      enabled = (words[1] == '1')
    end
  end
  Spring.Echo('direct unit control: blocking is ' ..
              (enabled and 'enabled' or 'disabled'))
  return true
end


--------------------------------------------------------------------------------

function gadget:Initialize()

  for i, v in pairs(badUnits) do
    badUnitDefs[v] = true
  end
  for udid, ud in pairs(UnitDefs) do
    if (ud.isBuilding) or badUnitDefs[ud.name] or ud.customParams.nofps then
      badUnitDefs[udid] = ud.humanName
	end
  end
  
  local cmd  = "fpsctrl"
  local help = " [0|1]:  direct unit control blocking"
  gadgetHandler:AddChatAction(cmd, ChatControl, help)
  Script.AddActionFallback(cmd .. ' ', help)
end


function gadget:Shutdown()
  gadgetHandler:RemoveChatAction('fpsctrl')
  Script.RemoveActionFallback('fpsctrl')
end


--------------------------------------------------------------------------------

function gadget:AllowDirectUnitControl(unitID, unitDefID, unitTeam, playerID)
  if (not enabled) then
    return true
  end

  local badName = badUnitDefs[unitDefID]
  if (badName == nil) then 
    return true
  end

  Spring.SendMessageToPlayer(playerID,
    "Direct control is disabled for " .. badName .. "s")
  return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
