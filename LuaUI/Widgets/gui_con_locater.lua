local version = "1.15"

function widget:GetInfo()
  return {
    name      = "Constructor locater",
    desc      = "Version " .. version .. ". Shows graphics around your constructors " ..
    "make finding them faster" ,
    author    = "Alcur",
    date      = "Aug 3, 2012",
    license   = "BSD 3-clause",
    layer     = 0,
    enabled   = false
  }
end

include"keysym.h.lua"





-- options begin

-- how many sides the marker "circles" will have
local circleDivs = 6

-- how fast the constructor-indicating graphics blink
local aniSpeedMultiplier = 3

-- color 1 for the constructor-indicating graphics
local red1 = 1
local green1 = 0.5
local blue1 = 0

-- color 2 for the constructor-indicating graphics
local red2 = 0
local green2 = 0.5
local blue2 = 1

-- if the camera aka. in-game view is below this height the constructor-indicating graphics
-- are disabled
local minActivationHeight = 1000

-- if the camera is above this height the constructor-indicating graphics are shown. 
-- Type "false" or "nil" (without the quotation marks) to disable
local activationHeight = 1

-- the keys that activate the constructor-indicating graphics
local activationKeyTable = {
    --[KEYSYMS.C] = true,
    [KEYSYMS.Q] = true,
    --[KEYSYMS.B] = true,
    [KEYSYMS.SPACE] = true,
}

-- enabling this means having your cursor on a constructor activates
-- the constructor-indicating graphics
local activateOnMouseOver = false

-- enabling this causes the widget to draw only on the mini map
local miniMapOnly = false

-- options end





local widgetName = widget:GetInfo().name

local abs = math.abs
local floor = math.floor
local pi = math.pi
local cos = math.cos
local sin = math.sin
local insert = table.insert
local remove = table.remove
local bit_inv = math.bit_inv

local glDrawGroundCircle = gl.DrawGroundCircle
local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glCreateList = gl.CreateList
local glCallList = gl.CallList
local glDeleteList = gl.DeleteList
local glVertex = gl.Vertex
local glDrawListAtUnit = gl.DrawListAtUnit
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glBeginEnd = gl.BeginEnd
local glTranslate = gl.Translate
local glScale = gl.Scale 
local glRotate = gl.Rotate
local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix

local IsGUIHidden = Spring.IsGUIHidden
local GetTeamUnits = Spring.GetTeamUnits
local myTeam = Spring.GetMyTeamID()
local GetUnitDefID = Spring.GetUnitDefID
local GetCameraPosition = Spring.GetCameraPosition
local GetGroundNormal = Spring.GetGroundNormal
local GetGroundHeight = Spring.GetGroundHeight
local TraceScreenRay = Spring.TraceScreenRay
local IsUnitInView = Spring.IsUnitInView
local IsUnitIcon = Spring.IsUnitIcon
local GetUnitPosition = Spring.GetUnitPosition
local GetUnitTeam = Spring.GetUnitTeam
local GetUnitBasePosition = Spring.GetUnitBasePosition
local GetFPS = Spring.GetFPS
local Echo = Spring.Echo

local unitListIndex = 0
local radstep = (2.0 * pi) / circleDivs
local radInDeg = 180/pi
local red = red1
local green = green1
local blue = blue1
local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local circleGlList
local aniFactor = 1
local mobileConDefIdTable = {}
local conMemoTable = {}
local keyPressed = false
local above = false
local useSecColors = true
local lastTime
local aniSpeed
local aniDelta



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

function radToDeg(rad)
    return rad*radInDeg
end

function makeCircle(x, y, z, scale)
    function  circleLines()
        for i = 1, circleDivs do
            local a = (i * radstep)
            glVertex(sin(a)*scale + x,
            y, cos(a)*scale + z)
        end     
    end

    glBeginEnd(GL.LINE_LOOP, circleLines)
end


function isMobileCon(unitDef)
    return unitDef.isBuilder and unitDef.canMove and not unitDef.isBuilding
end



function worldToMiniMapPos(x, z, mmxsize, mmzsize)

    --Echo(widgetName .. ": sx*mmxsize/vxsize, sy*mmysize/vysize = " .. sx*mmxsize/vxsize .. ", " .. sy*mmysize/vysize)

    return x*mmxsize/mapSizeX, z*mmzsize/mapSizeZ

end

function areConditionsMet()
    local cx, cy, cz = GetCameraPosition()

    if (keyPressed or above or (activationHeight and cy >= activationHeight)) and 
        cy >= minActivationHeight and not IsGUIHidden() then
        return true
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

end

loadClasses()






local conList = List:new()



function fillConList(unitIdList)
    if conList[1] then return end
    local unit
    local unitDef
    local unitDefId
    local unitPos = {}
    local curUnitIdList = unitIdList or Spring.GetTeamUnits(myTeam)
    --Echo(widgetName .. ": #curUnitIdList = " .. #curUnitIdList)
    for i = 1, #curUnitIdList do
        unit = curUnitIdList[i]
        unitDefId = GetUnitDefID(unit)
        unitDef = UnitDefs[unitDefId]
        if not conMemoTable[unit] and mobileConDefIdTable[unitDefId] then
            --Echo(widgetName .. ": new builder found")
            addToConTables(unit)
        end
    end

end

function addToConTables(unitId)
    if not unitId then return end
    conList:insert(unitId)
    conMemoTable[unitId] = true
end

function removeFromConTables(unitId, unitListIndex)
    if unitListIndex then 
        conList:remove(unitListIndex) 
    elseif unitId then
        conList:removeByValue(unitId)
    else
        return
    end
    conMemoTable[unitId] = nil
    --Echo(widgetName .. ": removed " .. tostring(unitId) .. ", " .. 
    --tostring(unitListIndex))
end

function widget:Update(timeSinceLastUpdate)
    aniSpeed = timeSinceLastUpdate*aniSpeedMultiplier
end

function widget:DrawInMiniMap(sx, sy)


    if areConditionsMet() then

        local cx, cy, cz = GetCameraPosition()

        glLineWidth(1)

        glColor(red, green, blue, aniFactor*0.4)

        local max = conList:len()

        for i = 1, max do

            local unit = conList[i]
            --Echo(widgetName .. ": unit = " .. unit)

            if not unit then
                --Echo(widgetName .. ": could not get unit id (DrawInMiniMap)")
            else
            
                local ux, uy, uz = GetUnitBasePosition(unit)
                

                if not ux then
                    --Echo(widgetName .. ": could not get unit coordinates (DrawInMiniMap)")
                    removeFromConTables(unit)
                else
                    local mmux, mmuz = worldToMiniMapPos(ux, uz, sx, sy)

                    gl.Rect(mmux - 5, sy-mmuz - 5, mmux + 5, sy-mmuz + 5)
 
                end
            end          
        end    
    end
end

function rewindAnimation()
    if aniFactor < 1 then
        aniFactor = 1
        useSecColors = true
        aniDelta = aniSpeed
        red = red1
        green = green1    
        blue = blue1
    end
end


function widget:DrawWorld()
    

    if not miniMapOnly and areConditionsMet() then
        local cx, cy, cz = GetCameraPosition()
        

        local camFactor
        local camYDiff


        if aniFactor < 0 then
            aniDelta = aniSpeed
            if useSecColors then
                red = red2
                green = green2
                blue = blue2
            else
                red = red1
                green = green1    
                blue = blue1
            end
            useSecColors = not useSecColors
        elseif aniFactor >= 1 then
            aniDelta = -aniSpeed
        end

        aniFactor = aniFactor + aniDelta

        
        glLineWidth(4)

        camFactor = cy/200+25

        if camFactor < 50 then
            camFactor = 50
        end

        glColor(red, green, blue, aniFactor)

        local max = conList:len()

        for i = 1, max do


            local unit = conList[i]

            if not unit then
                --Echo(widgetName .. ": could not get unit id (DrawWorld)")
            else
            --Echo(widgetName .. ": unit = " .. unit)
                if IsUnitInView(unit) then
                    local ux, uy, uz = GetUnitBasePosition(unit)

                    if not ux then
                        --Echo(widgetName .. ": could not get unit coordinates (DrawWorld)")
                        removeFromConTables(unit)
                    else
                        if IsUnitIcon(unit) then
                            --Echo(widgetName .. ": using inefficient drawing method")  
                            makeCircle(ux, uy, uz, camFactor)
                        else
                            --Echo(widgetName .. ": using efficient drawing method")         
                            glDrawListAtUnit(unit, circleGlList, false, camFactor, 
                            camFactor, camFactor)
                        end
                    end
                end
            end
        end

        
    else
        rewindAnimation()
    end

end

function widget:KeyPress(key, mods, isRepeat)

    if activationKeyTable[key] and isRepeat == false then

        fillConList()
    
        keyPressed = true
    end

end

function widget:KeyRelease(key)

    if activationKeyTable[key] then
        keyPressed = false
        rewindAnimation()
    end



end



function widget:UnitDestroyed(unitId, unitDefId)
    if conMemoTable[unitId] then
        removeFromConTables(unitId)
    end
end


function widget:UnitFinished(unitId, unitDefId)
    if mobileConDefIdTable[unitDefId] and GetUnitTeam(unitId) == myTeam then
        addToConTables(unitId)
    end
end

function widget:UnitTaken(unitId, unitDefId, unitTeam, newTeam)
    --Echo(widgetName .. ": unit taken: " .. tostring(unitTeam) .. ", " .. tostring(newTeam))
    if mobileConDefIdTable[unitDefId] and newTeam == myTeam  then
        addToConTables(unitId)
    end
end

function widget:UnitGiven(unitId, unitDefId, unitTeam, oldTeam)
    if conMemoTable[unitId] then
        removeFromConTables(unitId)
    end
end

function widget:IsAbove(x, y)

    if not activateOnMouseOver then
        return
    end

    local class, info = TraceScreenRay(x, y)

    if class == "unit" then
        local unitDefId = GetUnitDefID(info)
        if mobileConDefIdTable[unitDefId] then
            fillConList()

            above = true
        end
          
    elseif above then
        above = false
        rewindAnimation()
    end

end






function widget:Initialize()

    circleGlList = glCreateList(makeCircle, 0, 0, 0, 1.1)

    for k,v in pairs(UnitDefs) do
        if isMobileCon(v) then
            mobileConDefIdTable[k] = true
            --Echo(widgetName .. ": mobile con added to table")
        end
    end

end