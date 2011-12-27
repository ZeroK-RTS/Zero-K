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


function widget:Initialize()
  myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
  voiceMagic = "> ["..myName.."]voice"
  for i, unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    widget:UnitFinished(unitID, unitDefID)
  end
end


function widget:AddConsoleLine(msg)
  --[[
  if not StringStarts(msg, "@") then
    Spring.Echo("@"..msg)
  end
  --]]
  if StringStarts(msg, voiceMagic) then
    local tableString = string.sub(msg, string.len(voiceMagic) + 1)
    local voiceCommand = Deserialize("return "..tableString)
    if voiceCommand.commandName == "buildUnit" then
      for unitID in pairs(factories) do
        local builtUnitID = UnitDefNames[voiceCommand.unit].id
        for i=1, voiceCommand.number do
          Spring.GiveOrderToUnit(unitID, -builtUnitID, {}, voiceCommand.insert and {"alt"} or {})
        end
        if voiceCommand["repeat"] then
          Spring.GiveOrderToUnit(unitID, CMD.REPEAT, {1}, {})
        end
      end

    end
  end
end


function widget:UnitFinished(unitID, unitDefID, unitTeam)
 local unitDef = UnitDefs[unitDefID]
 if unitDef and unitDef.isFactory then
   factories[unitID] = true
 end
end


function widget:UnitDestroyed(unitID)
  factories[unitID] = nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
