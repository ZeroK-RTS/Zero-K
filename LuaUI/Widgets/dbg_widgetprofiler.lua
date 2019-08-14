--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Widget Profiler",
    desc      = "",
    author    = "jK",
    version   = "2.0",
    date      = "2007,2008,2009",
    license   = "GNU GPL, v2 or later",
    layer     = math.huge,
    handler   = true,
    enabled   = false  --  loaded by default?
  }
end
--Do "/profilewidget <widget name> <second>" to count usage of a single widget for a defined amount of 'second'.
--eg: "/profilewidget Chili Framework 10" count how much usage the Chili Framework use in 10 game second.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local callinTimes       = {}

local oldUpdateWidgetCallIn
local oldInsertWidget

local listOfHooks = {}
setmetatable(listOfHooks, { __mode = 'k' })

local inHook = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Misc/Widget Profiler'
options = {
	hideLowValues = {
                name = "Hide low values",
		type = 'bool',
		value = false,
		desc = "Hide readings for widgets with <0.5% FPS cost",
	},
	fontSize = {
		name = 'Font size',
		type = 'number',
		min = 6, max = 24,
		value = 8,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SCRIPT_DIR = Script.GetName() .. '/'

local function IsHook(func)
  return listOfHooks[func]
end

local function Hook(g,name)
  local spGetTimer = Spring.GetTimer
  local spDiffTimers = Spring.DiffTimers
  local widgetName = g.whInfo.name

  local realFunc = g[name]
  g["_old" .. name] = realFunc

  if (widgetName=="WidgetProfiler") then
    return realFunc
  end
  local widgetCallinTime = callinTimes[widgetName] or {}
  callinTimes[widgetName] = widgetCallinTime
  widgetCallinTime[name] = widgetCallinTime[name] or {0,0}
  local timeStats = widgetCallinTime[name]

  local t

  local helper_func = function(...)
    local dt = spDiffTimers(spGetTimer(),t)
    timeStats[1] = timeStats[1] + dt
    timeStats[2] = timeStats[2] + dt
    inHook = nil
    return ...
  end

  local hook_func = function(...)
    if (inHook) then
      return realFunc(...)
    end

    inHook = true
    t = spGetTimer()
    return helper_func(realFunc(...))
  end

  listOfHooks[hook_func] = true

  return hook_func
end

local function ArrayInsert(t, f, g)
  if (f) then
    local layer = g.whInfo.layer
    local index = 1
    for i,v in ipairs(t) do
      if (v == g) then
        return -- already in the table
      end
      if (layer >= v.whInfo.layer) then
        index = i + 1
      end
    end
    table.insert(t, index, g)
  end
end


local function ArrayRemove(t, g)
  for k,v in ipairs(t) do
    if (v == g) then
      table.remove(t, k)
      -- break
    end
  end
end


local function StartHook()
  Spring.Echo("start profiling")

  local wh = widgetHandler

  local CallInsList = {}
  for name,e in pairs(wh) do
    local i = name:find("List")
    if (i)and(type(e)=="table") then
      CallInsList[#CallInsList+1] = name:sub(1,i-1)
    end
  end

  --// hook all existing callins
  for _,callin in ipairs(CallInsList) do
    local callinGadgets = wh[callin .. "List"]
    for _,w in ipairs(callinGadgets or {}) do
      w[callin] = Hook(w,callin)
    end
  end

  Spring.Echo("hooked all callins: OK")

  --// hook the UpdateCallin function

  oldUpdateWidgetCallIn =  wh.UpdateWidgetCallIn
  wh.UpdateWidgetCallIn = function(self,name,w)
    local listName = name .. 'List'
    local ciList = self[listName]
    if (ciList) then
      local func = w[name]
      if (type(func) == 'function') then
        if (not IsHook(func)) then
          w[name] = Hook(w,name)
        end
        ArrayInsert(ciList, func, w)
      else
        ArrayRemove(ciList, w)
      end
      self:UpdateCallIn(name)
    else
      print('UpdateWidgetCallIn: bad name: ' .. name)
    end
  end

  oldInsertWidget =  wh.InsertWidget
  widgetHandler.InsertWidget = function(self,widget)
    if (widget == nil) then
      return
    end

    oldInsertWidget(self,widget)

    for _,callin in ipairs(CallInsList) do
      local func = widget[callin]
      if (type(func) == 'function') then
        widget[callin] = Hook(widget,callin)
      end
    end
  end

  Spring.Echo("hooked UpdateCallin: OK")
end


local function StopHook()
  Spring.Echo("stop profiling")

  local wh = widgetHandler

  local CallInsList = {}
  for name,e in pairs(wh) do
    local i = name:find("List")
    if (i)and(type(e)=="table") then
      CallInsList[#CallInsList+1] = name:sub(1,i-1)
    end
  end

  --// unhook all existing callins
  for _,callin in ipairs(CallInsList) do
    local callinGadgets = wh[callin .. "List"]
    for _,w in ipairs(callinGadgets or {}) do
      if (w["_old" .. callin]) then
        w[callin] = w["_old" .. callin]
      end
    end
  end

  Spring.Echo("unhooked all callins: OK")

  --// unhook the UpdateCallin function
  wh.UpdateWidgetCallIn = oldUpdateWidgetCallIn
  wh.InsertWidget = oldInsertWidget

  Spring.Echo("unhooked UpdateCallin: OK")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  local startTimer

  function widget:Update()
    widgetHandler:RemoveWidgetCallIn("Update", self)
    StartHook()
    startTimer = Spring.GetTimer()
  end

  function widget:Shutdown()
    StopHook()
  end

local tick = 0.1
local averageTime = 5
local loadAverages = {}

local function CalcLoad(old_load, new_load, t)
  return old_load*math.exp(-tick/t) + new_load*(1 - math.exp(-tick/t))
  --return (old_load-new_load)*math.exp(-tick/t) + new_load
end

local maximum = 0
local totalLoads = {}
local allOverTime = 0
local allOverTimeSec = 0
local memusage = 0
local memString = ''

local sortedList = {}
local function SortFunc(a,b)
  --if (a[2]==b[2]) then
    return a[1]<b[1]
  --else
  --  return a[2]>b[2]
  --end
end

  local targetCumulSecond = 0
  local targetCountdown = 0
  local targetCallinCumul = {nil}
  local targetWname = ''

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
  
  function widget:TextCommand(command)
    if command:sub(1,13) == "profilewidget" then
      command = command:sub(15)
      if targetWname ~='' then
        targetWname = ''
        targetCallinCumul = {nil}
        targetCountdown = 0
      else
        local words = explode(" ",command)
        local countdown = tonumber(words[#words])
        if countdown and #words>=2 then
          local wname = table.concat(words,' ',1,#words-1)
          Spring.Echo(wname)
          targetWname = wname
          targetCountdown = countdown
        end
      end
      targetCumulSecond = 0
      end
    return false
  end

  function widget:DrawScreen()
    if not (next(callinTimes)) then
      return --// nothing to do
    end

    local deltaTime = Spring.DiffTimers(Spring.GetTimer(),startTimer)
    if (deltaTime>=tick) then
      if (options.hideLowValues.value) then sortedList = {} end -- clear the list (prevents duplicates)
      startTimer = Spring.GetTimer()

      totalLoads = {}
      maximum = 0
      allOverTime = 0
      local n = 1
      for wname,callins in pairs(callinTimes) do
        local total = 0
        local cmax  = 0
        local cmaxname = ""
        local countdownt = false
        for cname,timeStats in pairs(callins) do
          total = total + timeStats[1]
          if (timeStats[2]>cmax) then
            cmax = timeStats[2]
            cmaxname = cname
          end
          if not looped and targetCountdown > 0 and targetWname == wname then
            targetCumulSecond = targetCumulSecond + timeStats[1]
            targetCallinCumul[cname] = targetCallinCumul[cname] or 0
            targetCallinCumul[cname] = targetCallinCumul[cname] + timeStats[1]
            if not countdownt then
              targetCountdown = targetCountdown - deltaTime
              countdownt = true
            end
          end
          timeStats[1] = 0
        end

        local load = 100*total/deltaTime
        loadAverages[wname] = CalcLoad(loadAverages[wname] or load, load, averageTime)

        allOverTimeSec = allOverTimeSec + total

        local tLoad = loadAverages[wname]
        allOverTime = allOverTime + tLoad
        if (maximum<tLoad) then maximum=tLoad end
        if tLoad > 0.5 or not (options.hideLowValues.value) then
                sortedList[n] = {wname..'('..cmaxname..')',tLoad}
                n = n + 1
        end
      end
      
      memusage = collectgarbage("count")
      if memusage > 10000 then
	memString = ('%.1f'):format(memusage/1024) .. " M"
      else
	memString = ('%.0f'):format(memusage) .. "k"
      end

      table.sort(sortedList,SortFunc)
    end

    if (not sortedList[1]) then
      return --// nothing to do
    end

    local vsx, vsy = gl.GetViewSizes()
    local x,y = vsx-780, vsy-60
	local fSize = options.fontSize.value
	local fSpacing = options.fontSize.value - 1

    gl.Color(1,1,1,1)
    gl.BeginText()
    if targetWname=='' then
      for i=1,#sortedList do
        local v = sortedList[i]
        local wname = v[1]
        local tLoad = v[2]
        if maximum > 0 then
          gl.Rect(x+100-tLoad/maximum*100, y+1-(fSpacing)*i, x+100, y+9-(fSpacing)*i)
        end
        gl.Text(wname, x+150, y+1-(fSpacing)*i, fSize)
        gl.Text(('%.3f%%'):format(tLoad), x+105, y+1-(fSpacing)*i, fSize)
      end
    else
      local index2 = 1
      gl.Text(targetWname, x+200, y+1-(fSpacing*1.25)*(1+index2), fSize*1.5)
      gl.Text(('%.4fs'):format(targetCumulSecond), x+100, y+1-(fSpacing*1.25)*(1+index2), fSize*1.25)
      gl.Text('left', x+200, y+1-(fSpacing*1.25)*(1+index2+1), fSize*1.5)
      gl.Text(('%.1fs'):format(targetCountdown), x+100, y+1-(fSpacing*1.25)*(1+index2+1), fSize*1.25)
      index2 = index2 + 3
      for cname, value in pairs(targetCallinCumul) do
        gl.Text(cname, x+200, y+1-(fSpacing)*(1+index2), fSize)
        gl.Text(('%.4fs'):format(value), x+100, y+1-(fSpacing)*(1+index2), fSize)
        index2 = index2 + 1
      end
    end
    local i = #sortedList + 1
    gl.Text("\255\255\064\064total time", x+150, y-1-(fSpacing)*i, fSize)
    gl.Text("\255\255\064\064"..('%.3fs'):format(allOverTimeSec), x+105, y-1-(fSpacing)*i, fSize)
    i = i+1
    gl.Text("\255\255\064\064total FPS cost", x+150, y-1-(fSpacing)*i, fSize)
    gl.Text("\255\255\064\064"..('%.1f%%'):format(allOverTime), x+105, y-1-(fSpacing)*i, fSize)
    i = i+1
    
    gl.Text("\255\255\064\064memory usage", x+150, y-1-(fSpacing)*i, fSize)
    gl.Text("\255\255\064\064"..memString, x+105, y-1-(fSpacing)*i, fSize)
    gl.EndText()
  end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
