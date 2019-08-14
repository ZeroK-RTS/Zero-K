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

local EMPTY_TABLE = {}
local TABLE_1 = {1}

local factories = {}

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
  -- make the widget work after for /luaui reload
  for i, unitID in ipairs(Spring.GetAllUnits()) do
    widget:UnitFinished(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
  end
  
end


function widget:VoiceCommand(commandName, voiceCommandParams)
  if commandName == "buildUnit" then
    -- todo: don't send to factories that can't build the unit
    for unitID in pairs(factories) do
      local builtUnitID = UnitDefNames[voiceCommandParams.unit].id
      for i=1, voiceCommandParams.number do
        -- todo: send large build orders with "shift" and "ctrl" to reduce network usage
        Spring.GiveOrderToUnit(unitID, -builtUnitID, EMPTY_TABLE, voiceCommandParams.insert and CMD.OPT_ALT or 0)
      end
      if voiceCommandParams["repeat"] then
        Spring.GiveOrderToUnit(unitID, CMD.REPEAT, TABLE_1, 0)
      end
    end
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
