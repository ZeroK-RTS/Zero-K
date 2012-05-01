--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Resign Gadget",
    desc      = "Resign stuff",
    author    = "KingRaptor",
    date      = "2012.5.1",
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
if (gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local function Resign(_, playerID)
  if tonumber(playerID) == Spring.GetMyPlayerID() then
    Spring.SendCommands('spectator')
  end
end

function gadget:Initialize()
  gadgetHandler:AddChatAction('resignteam', Resign, "resigns the player")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
