local version = "0.98"

function widget:GetInfo()
  return {
    name      = "Completed unit notifier",
    desc      = "Version " .. version .. ". notifies when the production of an expensive " ..
    "or situational unit is finished",
    author    = "Sphiloth aka. Alcur",
    date      = "Aug 3, 2012",
    license   = "BSD 3-clause with unsanctioned use aiming for profit forbidden",
    layer     = 0,
    enabled   = true
  }
end




-- options begin

-- if true, the widget will not take into account your allies' units
local myTeamOnly = false

-- if true, the widget reports only changes in the unit production of
-- factories, e.g. if you make 10 glaives in succession only the first one
-- triggers a notification 
local factoryProductionChangesOnly = true

-- if true, your team mates will not be able see the labels
local localOnly = true

-- something to distinguish the labels from the ordinary ones
local labelSuffix = ""

-- labels concerning your units are prefixed with this 
local myTeamLabelPrefix = ""

-- all units that cost more than this will be notified of
local minHeavyCost = 850

-- case-sensitive. The widget will notify about these special cases
local specificUnits = {
["Charon"] = true,
["Snitch"] = true,
["Imp"] = true,
["Widow"] = true,
["Iris"] = true,
["Phantom"] = true,
["Hercules"] = true,
["Djinn"] = true,
["Owl"] = true,
["Skuttle"] = true,
["Eos"] = true,
["Quake"] = true,
["Shockley"] = true,
["Inferno"] = true,
["Impaler"] = true,
["Missile Silo"] = true,
["Dante"] = true,
["Paladin"] = true,
["Scorpion"] = true,
["Detriment"] = true,
["Funnelweb"] = true,
["Shogun"] = true,
["Reef"] = true,
["Scylla"] = true,
["Singularity"] = true,
}

-- exclusively anti-air units that cost at least this much will be notified about.
-- Making it equal to minHeavyCost will disable it
local minAACost = 500

-- enabling this means Strider Hubs, Athenas and factories will be reported
local reportFactories = true

-- in seconds. Type "false" or "nil" (without the quotation marks) for infinite
local markerLifeSpan = 10

-- in seconds, how often the widget should check if points are eligible for removal
local updateInterval = 5

-- setting this to "false" causes the widget to remove itself if the local player is spectating
local enableDuringSpec = true

-- the widget can enhance the readability of its labels by placing them in rows. This variable
-- determines how many additional rows will be made before the programme just adjusts the point 
-- by random amounts. In that case all of them will removed as soon as the first one in that point
-- expires due to scripting limitations
local maxMarkerRows = 3

-- this determines how often the same type of unit from the same builder will be reported.
-- For example, if its value is 2, every other unit will be reported
local reportInterval = 1

-- options end



local framesBetweenUpdates = updateInterval*30
local widgetName = widget:GetInfo().name
local myTeam = Spring.GetMyTeamID()
local myAllyTeam = Spring.GetMyAllyTeamID()
local allyList = Spring.GetAllyTeamList()
local AreTeamsAllied = Spring.AreTeamsAllied
local MarkerAddPoint = Spring.MarkerAddPoint
local MarkerErasePosition = Spring.MarkerErasePosition
local GetUnitPosition = Spring.GetUnitPosition
local IsUnitInView = Spring.IsUnitInView
local GetCameraPosition = Spring.GetCameraPosition
local DiffTimers = Spring.DiffTimers
local GetTimer = Spring.GetTimer
local GetGameSeconds = Spring.GetGameSeconds
local GetTeamUnits = Spring.GetTeamUnits
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitIsBuilding = Spring.GetUnitIsBuilding
local GetSpectatingState = Spring.GetSpectatingState
local mapSizeX = Game.mapSizeX
local mapSizeZ = Game.mapSizeZ
local Echo = Spring.Echo
local abs = math.abs
local floor = math.floor
local insert = table.insert
local remove = table.remove
local random = math.random
local run
local ExclusAAUnitDefs = {}
local lastUnitPerFactoryTable = {}


function isUnitDefOnlyAA(defId)
  if ExclusAAUnitDefs[defId] ~= nil then
    return ExclusAAUnitDefs[defId]
  end
  local weapons
  local onlyTargets
  local isAntiAir = false
  local attacksLandOrSea = false
  weapons = UnitDefs[defId].weapons
  local result = false
  if type(weapons) == "table" then
    for i = 1, #weapons do
      onlyTargets = weapons[i].onlyTargets
      if onlyTargets["sink"] or onlyTargets["land"] or onlyTargets["ship"] then
        attacksLandOrSea = true
        break
      end
      --Echo(widgetName .. ": unit " .. "cannot attack ships, subs or land")
      if not isAntiAir and (onlyTargets["fixedwing"] or onlyTargets["gunship"]) then
        isAntiAir = true
        --Echo(widgetName .. ": unit " .. "can attack gunships or fixedwing")
      end
    end
    if isAntiAir and not attacksLandOrSea then
      result = true
    end
  end
  ExclusAAUnitDefs[defId] = result
  return result
end

function canDefMove(unitDefID)
    return UnitDefs[unitDefID].canMove
end

function canDefStartUnits(unitDefID)
    return UnitDefs[unitDefID].buildOptions and 
    not #UnitDefs[unitDefID].buildOptions == 0
end

function isDefFactory(unitDefID)
    return UnitDefs[unitDefID].isFactory
end

function isTeamMyAlly(team)
  return AreTeamsAllied(myTeam, team)
end

function boolToNum(bool)
  if type(bool) ~= "boolean" then
    error('bad argument to "' .. debug.getinfo(1, "n").name ..
    '"(boolean expected, got ' .. type(bool) .. ")" )
  end
  local boolNum = 0
  if bool then
    boolNum = 1
  end
  return boolNum
end


function round(value, precision)


  local remainder = value%precision

  if remainder == 0 then
    return value
  end

  if remainder >= precision/2 then
    value = value + precision
  end

  value = value - remainder

  return value
end




function brake(interval)

  local lastRun = GetTimer()

  return  function ()
            local now = GetTimer()
            local permission = false
            if DiffTimers(now, lastRun) >= interval then
              lastRun = now
              permission = true
            end
            return permission
          end
end

function append(list, value)
  --Echo(widgetName .. ': entered "' .. debug.getinfo(1, "n").name .. '"')
  list[#list+1] = value
end

function contains(list, entry)
  --Echo(widgetName .. ': entered "' .. debug.getinfo(1, "n").name .. '"')
  for i = 1, #list do
    if list[i] == entry then return true end
  end
  return false
end



function loadClasses()

  List = {}

  function List:new(contents)
    local o = {}



    setmetatable(o, self)

    o.contents = contents or {}
    o.locked = false


    self.__index = function (table, key)
      if type(key) == "number" then
        return table:get(key)
      else
        return rawget(self, key)
      end
    end


    return o
  end

  function List:get(key)
    if key == nil then
      return self.contents
    elseif type(key) == "number" then
      return self.contents[key]
    end
  end


  function List:len()
    return #self:get()
  end

  function List:insert(pos, val)
    if not val then
      self:append(pos)
    else
      insert(self:get(), pos, val)
    end
  end


  function List:replace(pos, val)
    if not val then
      self:get()[self:len()] = val
    else
      self:get()[pos] = val
    end
  end

  function List:setContents(list)
    self.contents = list
  end

  function List:__newindex(key, value)
    if type(key) == "number" then
      self:replace(key, value)
    else
      rawset(self, key, value)
    end
  end

  function List:append(val)
    append(self:get(), val)
  end

  function List:remove(k)
    if type(k) == "number" then
      return remove(self:get(), k)
    end
  end

  function List:search(entry)
    local value
    local key
    for i = 1, self:len() do
      if self:get(i) == entry then value = entry; key = i end
    end
    return key, value
  end

  function List:find(entry)
    local tempT = self:get()
    local value
    local key
    for i = 1, self:len() do
      if tempT[i] == entry then value = entry; key = i end
    end
    return key, value
  end

  function List:contains(entry)
    local tempT = self:get()
    for i = 1, self:len() do
      if tempT[i] == entry then return true end
    end
    return false
  end

  function List:removeByValue(entry)
    local k, v = self:search(entry)
    return self:remove(k)
  end

  function List:lock()
    if self:isLocked() then
      error('unable to lock an already locked List object')
    end
    self.locked = true
  end

  function List:unlock()
    if not self:isLocked() then
      error('unable to unlock an already unlocked List object')
    end
    self.locked = false
  end

  function List:isLocked()
    return self.locked
  end


  

  ThreeDimArray = {}

  function ThreeDimArray:new()
    local o = {}

    setmetatable(o, self)

    o.nestingLevel = 1

    return o
  end

  function ThreeDimArray:__index(key)

    local nestingLevel = self.nestingLevel + 1
    if nestingLevel > 3 then
      self[key] = nil
    else
      local ar = ThreeDimArray:new()
      ar.nestingLevel = nestingLevel
      self[key] = ar
    end
    return rawget(self, key)
  end



  Point = {}

  Point.points = ThreeDimArray:new()

  function Point:isTaken(x, y, z)
    if x and y and z then
      return Point.points[x][y][z]
    else
      error('bad argument to "' .. debug.getinfo(1, "n").name ..
    '"(numbers expected, got a ' .. type(x) .. ' for x, a ' .. type(y) ..
    ' for y, a ' .. type(z) .. ' for z)' )
    end
  end

  function Point:new(x, y, z, text, localOnly)
    local spacing = 104
    x = round(x, spacing)
    --y = round(y, spacing) MarkerAddPoint ignores this coordinate
    z = round(z, spacing)
    if Point:isTaken(x, y, z) then
      --Echo(widgetName .. ": " .. tostring(x) .. ", " .. tostring(y) ..
      --  ", " .. tostring(z) .. " is taken")

      local zshift = -spacing
      local origZ = z
      local tries = 0
      local maxTries = maxMarkerRows

      if z <= abs(zshift)*10 + 128 then
        zshift = -zshift
      end




      while Point:isTaken(x, y, z) do

        z = z + zshift
        
        tries = tries + 1

        if tries > maxTries then
          z = origZ + random(-10, 10)*5
          x = x + random(-10, 10)*5
          break
        end
        
        --Echo(widgetName .. ": coords adjusted")
      end

    end

    --Echo(widgetName .. ": final coords: " .. tostring(x) .. ", " .. tostring(y) ..
    --", " .. tostring(z))

    local o = {}
    setmetatable(o, self)
    self.__index = self



    o.time = GetTimer()
    o.x = x
    o.y = y
    o.z = z
    o.text = text
    o.localOnly = localOnly



    MarkerAddPoint(o.x, o.y, o.z, o.text, o.localOnly)
    o:markTaken()

    return o
  end

  function Point:markTaken()
    Point.points[self.x][self.y][self.z] = true
  end

  function Point:free()
    Point.points[self.x][self.y][self.z] = nil
  end

  function Point:remove()
    MarkerErasePosition(self.x, self.y, self.z)
    self:free()
  end

  function Point:cull()
    local result = false
    if DiffTimers(GetTimer(), self.time) > markerLifeSpan then
      --Echo(DiffTimers(GetTimer(), self.time) .. " > " .. markerLifeSpan)
      self:remove()
      result = true
    end
    return result
  end
end

loadClasses()

local pList = List:new()

local finishedTable = {}

function widget:UnitFromFactory(unit, unitDefId, team, factId, factDefId, userOrders)

    if finishedTable[unit] then
        --Echo(widgetName .. ": unit already reported")
        finishedTable[unit] = nil
        return
    end


    
    if factId then
        if factoryProductionChangesOnly then
            if type(lastUnitPerFactoryTable[factId]) ~= "table" then 
                lastUnitPerFactoryTable[factId] = {}
                lastUnitPerFactoryTable[factId].count = 0
            end
            lastUnitPerFactoryTable[factId].count = lastUnitPerFactoryTable[factId].count + 1
            local factUnitId = GetUnitIsBuilding(factId)
            local factUnitDefId
            if factUnitId then
                factUnitDefId = GetUnitDefID(factUnitId)
            else
                local _, teamLeader = Spring.GetTeamInfo(team)
                local teamLeaderName = Spring.GetPlayerInfo(teamLeader)
                --local facName = (UnitDefs[factDefId] and UnitDefs[factDefId].humanName ) or "an unknown factory"
                --Echo(widgetName .. ": the current construction type of " .. 
                --facName .. " (" .. teamLeaderName .. ") could not be obtained")
            end
            if lastUnitPerFactoryTable[factId].uDefId == unitDefId and lastUnitPerFactoryTable[factId].count < reportInterval then
                --Echo(widgetName .. ": skipped " .. UnitDefs[unitDefId].humanName)
                return
            else
                lastUnitPerFactoryTable[factId].count = 0
                lastUnitPerFactoryTable[factId].uDefId = factUnitDefId         
            end       
        end
    end



    local uDef = UnitDefs[unitDefId]
    local metalCost = uDef.metalCost
    local lastUnitPerFactoryTable = {}


  --Echo( widgetName .. ": checking user defined conditions for unit")
    if metalCost >= minHeavyCost or (metalCost >= minAACost and isUnitDefOnlyAA(unitDefId)) or 
    (reportFactories and (isDefFactory(unitDefId) or uDef.name == "striderhub" or uDef.name == "athena")) or 
    specificUnits[uDef.humanName] then

        local ux, uy, uz
        ux, uy, uz = GetUnitPosition(unit)
   

        local _, camY = GetCameraPosition()

        local teamUnits = GetTeamUnits(myTeam)
      --Echo( widgetName .. ": " .. "team " .. team .. " produced " .. uDef.humanName .. " " .. unit)



        uy = 0 --MarkerAddPoint ignores this coordinate; making it a constant integer means no rounding is required


        if (not myTeamOnly or team == myTeam) and (not IsUnitInView(unit) or camY >= 1750) and
        not (#teamUnits <= 1 and uDef.customParams.commtype and GetGameSeconds() < 180) then
            --Echo(widgetName .. ": world coords: " .. tostring(Game.mapX) .. ", " .. tostring(Game.mapY) ..
            --"; " .. tostring(Game.mapSizeX) .. ", " .. tostring(Game.mapSizeZ))
            --Echo( widgetName .. ": " .. "the height diff between cam and unit is " .. (camY - uy))
            local p

            local _, teamLeader
            local otherTeamAttribution = ""
            local labelPrefix = ""

            if not GetSpectatingState() and team == myTeam then
                if myTeamLabelPrefix ~= "" then 
                    labelPrefix = myTeamLabelPrefix .. " "
                end
            else
                _, teamLeader = Spring.GetTeamInfo(team)
                otherTeamAttribution = " by " .. (Spring.GetPlayerInfo(teamLeader) or "an unknown player")
            end

            p = Point:new(ux, uy, uz, labelPrefix .. uDef.humanName .. 
                otherTeamAttribution .. " ready " .. labelSuffix, boolToNum(localOnly))
            pList:lock()
            pList:insert(p)
            pList:unlock()
            
            
            --Echo(widgetName .. ": " .. "pList: " .. tostring(k) .. ", " .. tostring(v))

        
        end
    end
end

local startedProductionTable = {}

function widget:UnitFinished(unit, unitDefId, team)
    
    --local uDef = UnitDefs[unitDefId]

    --if uDef.isBuilding or not uDef.canMove or uDef.customParams.commtype or
    if startedProductionTable[unit] then
        --finishedTable[unit] = true
        local builder = startedProductionTable[unit]
        startedProductionTable[unit] = nil
        widget:UnitFromFactory(unit, unitDefId, team, builder)
        
        
    end

end



function widget:UnitCreated(unit, unitDefId, team, builder)
    local uDef = UnitDefs[unitDefId]
    local bDef = {}
    if builder then
        bDef = UnitDefs[GetUnitDefID(builder)]
    else
        bDef.humanName = "unknown builder"
    end

    --Echo( widgetName .. ": unit created by " .. bDef.humanName)

    --if bDef.name == "armcsa" or  bDef.name == "striderhub" then
    if not bDef.isFactory then
        --Echo( widgetName .. ": " .. bDef.humanName .. " started production")
        startedProductionTable[unit] = builder
    end

end

function widget:Initialize()

    if not enableDuringSpec and GetSpectatingState() then
        Echo("<" .. widgetName .. "> Spectator mode. Widget removed.")
        widgetHandler:RemoveWidget()
    end

    run = brake(updateInterval)


end


function widget:GameFrame(frame)
    if markerLifeSpan and frame%framesBetweenUpdates==0 and not pList:isLocked() then
        --Echo( widgetName .. ": sleep period complete, updating")
        for k,point in ipairs(pList:get()) do
            --Echo( widgetName .. ": checking " .. tostring(k) .. ", " .. tostring(point))
            if type(k) == "number" and point:cull() then
            pList:remove(k)
            --Echo( widgetName .. ": culled " .. tostring(k) .. ", " .. tostring(point))
            --for k,v in ipairs(pList:get()) do
              --Echo(widgetName .. ": " .. "pList: " .. tostring(k) .. ", " .. tostring(v))
            --end
            end
        end
    end
end

