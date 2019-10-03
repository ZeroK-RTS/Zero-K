-- $Id: dbg_profiler.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Profiler",
    desc      = "",
    author    = "jK",
    date      = "2007,2008,2009",
    license   = "GNU GPL, v2 or later",
    layer     = math.huge,
    handler   = true,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local callinTimes       = {}
local callinTimesSYNCED = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SCRIPT_DIR = Script.GetName() .. '/'

local Hook = function(g,name) return function(...) return g[name](...) end end --//place holder

local inHook = false
local listOfHooks = {}
setmetatable(listOfHooks, { __mode = 'k' })

local function IsHook(func)
  return listOfHooks[func]
end

if (gadgetHandler:IsSyncedCode()) then
  Hook = function (g,name)
    local origFunc = g[name]

    local hook_func = function(...)
      if (inHook) then
        return origFunc(...)
      end

      inHook = true
      SendToUnsynced("prf_started", g.ghInfo.name, name)
      local results = {origFunc(...)}
      SendToUnsynced("prf_finished", g.ghInfo.name, name)
      inHook = false
      return unpack(results)
    end

    listOfHooks[hook_func] = true --note: using function in keys is unsafe in synced code!!!

    return hook_func
  end
else
  Hook = function (g,name)
    local spGetTimer = Spring.GetTimer
    local spDiffTimers = Spring.DiffTimers
    local gadgetName = g.ghInfo.name

    local realFunc = g[name]

    if (gadgetName=="Profiler") then
      return realFunc
    end
    local gadgetCallinTime = callinTimes[gadgetName] or {}
    callinTimes[gadgetName] = gadgetCallinTime
    gadgetCallinTime[name] = gadgetCallinTime[name] or {0,0}
    local timeStats = gadgetCallinTime[name]

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
end

local function ArrayInsert(t, f, g)
  if (f) then
    local layer = g.ghInfo.layer
    local index = 1
    for i=1,#t do
      local v = t[i]
      if (v == g) then
        return -- already in the table
      end
      if (layer >= v.ghInfo.layer) then
        index = i + 1
      end
    end
    table.insert(t, index, g)
  end
end


local function ArrayRemove(t, g)
  for k=1, #t do
    if (t[k] == g) then
      table.remove(t, k)
      -- break
    end
  end
end

local hookset = false

local function StartHook()
  if (hookset) then return end
  hookset = true
  Spring.Echo("start profiling")

  local gh = gadgetHandler

  local CallInsList = {}
  for name,e in pairs(gh) do
    local i = name:find("List")
    if (i)and(type(e)=="table") then
      CallInsList[#CallInsList+1] = name:sub(1,i-1)
    end
  end

  --// hook all existing callins
  for i=1, #CallInsList do
    local callin = CallInsList[i]
    local callinGadgets = gh[callin .. "List"]
    for _,g in ipairs(callinGadgets or {}) do
      g[callin] = Hook(g,callin)
    end
  end

  Spring.Echo("hooked all callins: OK")

  oldUpdateGadgetCallIn = gh.UpdateGadgetCallIn
  gh.UpdateGadgetCallIn = function(self,name,g)
    local listName = name .. 'List'
    local ciList = self[listName]
    if (ciList) then
      local func = g[name]
      if (type(func) == 'function') then
        if (not IsHook(func)) then
          g[name] = Hook(g,name)
        end
        ArrayInsert(ciList, func, g)
      else
        ArrayRemove(ciList, g)
      end
      self:UpdateCallIn(name)
    else
      print('UpdateGadgetCallIn: bad name: ' .. name)
    end
  end

  Spring.Echo("hooked UpdateCallin: OK")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

  function gadget:Initialize()
    gadgetHandler.actionHandler.AddChatAction(gadget, 'sprofile', StartHook,
      " : starts the gadget profiler (for debugging issues)"
    )
    --StartHook()
  end

  --function gadget:Shutdown()
  --end

  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
else
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------

  local startTimer
  local startTimerSYNCED
  local profile_unsynced = false
  local profile_synced = false
  local displayLowValue = true
  
  local targetCumulSecond = 0
  local targetCountdown = 0
  local targetCallinCumul = {nil}
  local targetCallinCumul_unsynced = {nil}
  local targetCumulSecond_unsynced = 0
  local targetCountdown_unsynced = 0
  local targetWname = ''

  local function UpdateDrawCallin()
    --gadget.DrawScreen = gadget.DrawScreen_
    gadgetHandler:UpdateGadgetCallIn("DrawScreen", gadget)
  end
  
  local function Start(cmd, msg, words, playerID)
    if (Spring.GetLocalPlayerID() ~= playerID) then
      return
    end

    if (not profile_unsynced) then
      UpdateDrawCallin()
      UpdateDrawCallin()
      startTimer = Spring.GetTimer()
      StartHook()
      profile_unsynced = true
    else
      profile_unsynced = false
    end
  end
  local function StartSYNCED(cmd, msg, words, playerID)
    if (Spring.GetLocalPlayerID() ~= playerID) then
      return
    end

    if (not profile_synced) then
      startTimerSYNCED = Spring.GetTimer()
      profile_synced = true
      UpdateDrawCallin()
      UpdateDrawCallin()
    else
      profile_synced = false
    end
  end
  local function StartBoth(cmd, msg, words, playerID)
    Start(cmd, msg, words, playerID)
	StartSYNCED(cmd, msg, words, playerID)
  end
    

  local timers = {}
  function SyncedCallinStarted(_,gname,cname)
    local t  = Spring.GetTimer()
    timers[#timers+1] = t
  end

  function SyncedCallinFinished(_,gname,cname)
    local dt = Spring.DiffTimers(Spring.GetTimer(),timers[#timers])
    timers[#timers]=nil

    local gadgetCallinTime = callinTimesSYNCED[gname] or {}
    callinTimesSYNCED[gname] = gadgetCallinTime
    gadgetCallinTime[cname] = gadgetCallinTime[cname] or {0,0}
    local timeStats = gadgetCallinTime[cname]

    timeStats[1] = timeStats[1] + dt
    timeStats[2] = timeStats[2] + dt
  end
  
  function FilterLowValueToggle(cmd, msg, words, playerID)
    if (Spring.GetLocalPlayerID() ~= playerID) then
     return
    end
    displayLowValue = not displayLowValue
  end
  
	function ToggleTargetGadget(cmd, msg, words, playerID)
		if (Spring.GetLocalPlayerID() ~= playerID) then
			return
		end
		
		if targetWname ~='' then
			targetWname = ''
			targetCallinCumul = {nil}
			targetCallinCumul_unsynced = {nil}
			targetCountdown = 0
			targetCountdown_unsynced = 0
		else
			local countdown = tonumber(words[#words])
			if countdown and #words>=2 then
				local wname = table.concat(words,' ',1,#words-1)
				Spring.Echo(wname)
				targetWname = wname
				targetCountdown = countdown
				targetCountdown_unsynced = countdown
			end
		end
		targetCumulSecond = 0
		targetCumulSecond_unsynced = 0
	end

  function gadget:Initialize()
    gadgetHandler.actionHandler.AddSyncAction(gadget, "prf_started",SyncedCallinStarted)
    gadgetHandler.actionHandler.AddSyncAction(gadget, "prf_finished",SyncedCallinFinished)

    gadgetHandler.actionHandler.AddChatAction(gadget, 'uprofile', Start, " : starts the gadget profiler (for debugging issues)")
    gadgetHandler.actionHandler.AddChatAction(gadget, 'sprofile', StartSYNCED,"")
	gadgetHandler.actionHandler.AddChatAction(gadget, 'ap', StartBoth,"")
	gadgetHandler.actionHandler.AddChatAction(gadget, 'fprofile', FilterLowValueToggle," : filter out low values")
	gadgetHandler.actionHandler.AddChatAction(gadget, 'profilegadget', ToggleTargetGadget," : profilegadget <gadget_name> <how_much_second_to_profile>.")
    --StartHook()
	
	--[[
	Default usage:
	"profile" -> "uprofile"	(activate whole system ,show percentage. show/hide SYNCED/UNSYNCED display)
	                 \-> "fprofile" (show/hide low percentage)
	                  \-> "profilegadget <gadgetname> <second>" (show/hide and reset SYNCED cumulative second for 1 gadget)
	--]]
  end

local tick = 0.1
local averageTime = 5
local loadAverages = {}

local function CalcLoad(old_load, new_load, t)
  return old_load*math.exp(-tick/t) + new_load*(1 - math.exp(-tick/t))
  --return (old_load-new_load)*math.exp(-tick/t) + new_load
end

local maximum = 0
local maximumSYNCED = 0
local totalLoads = {}
local allOverTime = 0
local allOverTimeSYNCED = 0
local allOverTimeSec = 0

local sortedList = {}
local sortedListSYNCED = {}
local function SortFunc(a,b)
  --if (a[2]==b[2]) then
    return a[1]<b[1]
  --else
  --  return a[2]>b[2]
  --end
end

  function gadget:DrawScreen()
    if not (next(callinTimes)) then
      return --// nothing to do
    end

    if (profile_unsynced) then
      local deltaTime = Spring.DiffTimers(Spring.GetTimer(),startTimer)
      if (deltaTime>=tick) then
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
            if targetCountdown_unsynced > 0 and targetWname == wname then
              targetCumulSecond_unsynced = targetCumulSecond_unsynced + timeStats[1]
              targetCallinCumul_unsynced[cname] = targetCallinCumul_unsynced[cname] or 0
              targetCallinCumul_unsynced[cname] = targetCallinCumul_unsynced[cname] + timeStats[1]
              if not countdownt then
                targetCountdown_unsynced = targetCountdown_unsynced - deltaTime
                countdownt = true
              end
            end
            timeStats[1] = 0
          end

          local load = 100*total/deltaTime
          loadAverages[wname] = CalcLoad(loadAverages[wname] or load, load, averageTime)

          allOverTimeSec = allOverTimeSec + total
 
          local tLoad = loadAverages[wname]
          sortedList[n] = {wname..'('..cmaxname..')',tLoad}
          allOverTime = allOverTime + tLoad
          if (maximum<tLoad) then maximum=tLoad end
          n = n + 1
        end

        table.sort(sortedList,SortFunc)
      end
    end

    if (profile_synced) then
      local deltaTimeSYNCED = Spring.DiffTimers(Spring.GetTimer(),startTimerSYNCED)
      if (deltaTimeSYNCED>=tick) then
        startTimerSYNCED = Spring.GetTimer()

        totalLoads = {}
        maximumSYNCED = 0
        allOverTimeSYNCED = 0
        local n = 1
        for wname,callins in pairs(callinTimesSYNCED) do
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
            if targetCountdown > 0 and targetWname == wname then
              targetCumulSecond = targetCumulSecond + timeStats[1]
              targetCallinCumul[cname] = targetCallinCumul[cname] or 0
              targetCallinCumul[cname] = targetCallinCumul[cname] + timeStats[1]
              if not countdownt then
                targetCountdown = targetCountdown - deltaTimeSYNCED
                countdownt = true
              end
            end
            timeStats[1] = 0
          end

          local load = 100*total/deltaTimeSYNCED
          loadAverages[wname] = CalcLoad(loadAverages[wname] or load, load, averageTime)

          allOverTimeSec = allOverTimeSec + total
 
          local tLoad = loadAverages[wname]
          sortedListSYNCED[n] = {wname..'('..cmaxname..')',tLoad}
          allOverTimeSYNCED = allOverTimeSYNCED + tLoad
          if (maximumSYNCED<tLoad) then maximumSYNCED=tLoad end
          n = n + 1
        end

        table.sort(sortedListSYNCED,SortFunc)
      end
    end

    if (not sortedList[1]) then
      return --// nothing to do
    end

    local vsx, vsy = gl.GetViewSizes()
    local x,y = 400, vsy-60
	local sX = 80
	local fSize = 8
	local fSpacing = 8

    local maximum_ = (maximumSYNCED > maximum) and (maximumSYNCED) or (maximum)

    gl.Color(1,1,1,1)
    gl.BeginText()
	local index1 = 1
    if (profile_unsynced) then
      if targetWname=='' then
        for i=1,#sortedList do
          local v = sortedList[i]
          local wname = v[1]
          local tLoad = v[2]
          if displayLowValue or tLoad > 0.05 then
            if maximum > 0 then
              gl.Rect(x+100-tLoad/maximum_*100, y+1-(fSpacing)*index1, x+100, y+9-(fSpacing)*index1)
            end
            gl.Text(wname, x+150, y+1-(fSpacing)*index1, fSize)
            gl.Text(('%.3f%%'):format(tLoad), x+105, y+1-(fSpacing)*index1, fSize)
            index1 = index1 + 1
          end
        end
      else
        gl.Text(targetWname, x+200, y+1-(fSpacing*1.25)*index1, fSize*1.5)
        gl.Text(('%.4fs'):format(targetCumulSecond_unsynced), x+100, y+1-(fSpacing*1.25)*index1, fSize*1.25)
        gl.Text('left', x+200, y+1-(fSpacing*1.25)*(index1+1), fSize*1.5)
        gl.Text(('%.1fs'):format(targetCountdown), x+100, y+1-(fSpacing*1.25)*(index1+1), fSize*1.25)
        index1 = index1 + 3
        for cname, value in pairs(targetCallinCumul_unsynced) do
          gl.Text(cname, x+200, y+1-(fSpacing)*index1, fSize)
          gl.Text(('%.4fs'):format(value), x+100, y+1-(fSpacing)*index1, fSize)
          index1 = index1 + 1
        end
      end
    end
	local index2 = 1
    if (profile_synced) then
      local j = 1

      gl.Rect(sX, y+5-(fSpacing)*j, sX+230, y+4-(fSpacing)*j)
      gl.Color(1,0,0)
      gl.Text("SYNCED", sX+115, y-(fSpacing)*j, fSize, "nOc")
      gl.Color(1,1,1,1)
      j = j
      if targetWname=='' then
        for i=1,#sortedListSYNCED do
          local v = sortedListSYNCED[i]
          local wname = v[1]
          local tLoad = v[2]
          if displayLowValue or tLoad > 0.05 then
            if maximum > 0 then
              gl.Rect(sX+100-tLoad/maximum_*100, y+1-(fSpacing)*(j+index2), sX+100, y+9-(fSpacing)*(j+index2))
            end
            gl.Text(wname, sX+150, y+1-(fSpacing)*(j+index2), fSize)
            gl.Text(('%.3f%%'):format(tLoad), sX+105, y+1-(fSpacing)*(j+index2), fSize)
            index2 = index2 + 1
          end
        end
      else
        gl.Text(targetWname, sX+200, y+1-(fSpacing*1.25)*(j+index2), fSize*1.5)
        gl.Text(('%.4fs'):format(targetCumulSecond), sX+100, y+1-(fSpacing*1.25)*(j+index2), fSize*1.25)
        gl.Text('left', sX+200, y+1-(fSpacing*1.25)*(j+index2+1), fSize*1.5)
        gl.Text(('%.1fs'):format(targetCountdown), sX+100, y+1-(fSpacing*1.25)*(j+index2+1), fSize*1.25)
        index2 = index2 + 3
        for cname, value in pairs(targetCallinCumul) do
          gl.Text(cname, sX+200, y+1-(fSpacing)*(j+index2), fSize)
          gl.Text(('%.4fs'):format(value), sX+100, y+1-(fSpacing)*(j+index2), fSize)
          index2 = index2 + 1
        end
      end
	end
    local i = index1 + 2
    gl.Text("\255\255\064\064total time", x+150, y-1-(fSpacing)*i, fSize)
    gl.Text("\255\255\064\064"..('%.3fs'):format(allOverTimeSec), x+105, y-1-(fSpacing)*i, fSize)
    i = i+1
    gl.Text("\255\255\064\064total FPS cost", x+150, y-1-(fSpacing)*i, fSize)
    gl.Text("\255\255\064\064"..('%.1f%%'):format(allOverTime+allOverTimeSYNCED), x+105, y-1-(fSpacing)*i, fSize)
    gl.EndText()
  end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
