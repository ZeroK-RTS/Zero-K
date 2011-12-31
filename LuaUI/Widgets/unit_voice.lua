--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Voice Assistant",
    desc      = "",
    author    = "quantum",
    date      = "Dec 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myName
local voiceMagic
local factories = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function StringStarts(s, start)
   return string.sub(s, 1, string.len(start)) == start
end


local function Deserialize(text)
  local f, err = loadstring(text)
  if not f then
    Spring.Echo("error while deserializing (compiling): "..tostring(err))
    return
  end
  setfenv(f, {}) -- sandbox
  local success, arg = pcall(f)
  if not success then
    Spring.Echo("error while deserializing (calling): "..tostring(arg))
    return
  end
  return arg
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function EnableVoiceCommandOptions(unitDef)
  for _, buildOptionID in ipairs(unitDef.buildOptions) do
    local buildOptionDef = UnitDefs[buildOptionID]      
    Spring.Echo("!transmitlobby @voice@buildUnit@add;"..buildOptionDef.name..";"..buildOptionDef.humanName) -- zklobby listens to this
  end
  Spring.Echo("!transmitlobby @voice@buildUnit@reload")
end


local function DisableVoiceCommandOptions(unitDef)
  for _, buildOptionID in ipairs(unitDef.buildOptions) do
    local buildOptionDef = UnitDefs[buildOptionID]      
    Spring.Echo("!transmitlobby @voice@buildUnit@remove;"..buildOptionDef.name) -- zklobby listens to this
  end
  Spring.Echo("!transmitlobby @voice@buildUnit@reload")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()

  myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
  voiceMagic = "> ["..myName.."]!transmit voice"
  
  -- make the widget work after for /luaui reload
  for i, unitID in ipairs(Spring.GetAllUnits()) do
    widget:UnitFinished(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
  end
  
end


function widget:AddTransmitLine(msg)
  
  if StringStarts(msg, voiceMagic) then -- is a voice command
    local tableString = string.sub(msg, string.len(voiceMagic) + 1)
    
    -- deserialize voice command parameters in table form
    local voiceCommand = Deserialize("return "..tableString)
    
    if voiceCommand.commandName == "buildUnit" then
      -- todo: don't send to factories that can't build the unit
      for unitID in pairs(factories) do
        local builtUnitID = UnitDefNames[voiceCommand.unit].id
        for i=1, voiceCommand.number do
          -- todo: send large build orders with "shift" and "ctrl" to reduce network usage
          Spring.GiveOrderToUnit(unitID, -builtUnitID, {}, voiceCommand.insert and {"alt"} or {})
        end
        if voiceCommand["repeat"] then
          Spring.GiveOrderToUnit(unitID, CMD.REPEAT, {1}, {})
        end
      end
    end
    --[[
    if voiceCommand.commandName == "factoryPause" then
      if voiceCommand.mode == "suspend" then
        for unitID in pairs(factories) do
          -- implement "if not waiting"
          Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
        end
      elseif voiceCommand.mode == "resume" then
        for unitID in pairs(factories) do
          -- implement "if waiting"
          Spring.GiveOrderToUnit(unitID, CMD.WAIT, {}, {})
        end
      end
    end
    --]]
    
  end
  
end


-- todo: take into account factories given to me
function widget:UnitFinished(unitID, unitDefID, unitTeam)
  local myTeamID = Spring.GetMyTeamID()  
  if unitTeam ~= myTeamID then
    return
  end
  local unitDef = UnitDefs[unitDefID]  
  if unitDef and unitDef.isFactory then
    factories[unitID] = true
    if Spring.GetTeamUnitDefCount(myTeamID, unitDefID) < 2 then -- if this is the first factory of this type
      EnableVoiceCommandOptions(unitDef)
    end
  end
end


-- todo: take into account factories given to allies
function widget:UnitDestroyed(unitID, unitDefID)
  local myTeamID = Spring.GetMyTeamID()
  if factories[unitID] then
    if Spring.GetTeamUnitDefCount(myTeamID, unitDefID) < 2 then   -- if this is the last factory of this type
      factories[unitID] = nil
      DisableVoiceCommandOptions(UnitDefs[unitDefID])
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
