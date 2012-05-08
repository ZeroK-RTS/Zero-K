-- $Id: gui_build_eta.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_build_eta.lua
--  brief:   display estimated time of arrival for builds
--  author:  Dave Rodgers
--
--  >> modified by: jK <<
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "BuildETA",
		desc      = "Displays estimated time of arrival for builds",
		author    = "trepan (modified by jK) (stall ETA fixed by Google Frog)",
		date      = "Feb, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gl     = gl  --  use a local copy for faster access
local Spring = Spring
local table  = table

local etaTable = {}


--------------------------------------------------------------------------------

options_path = 'Settings/Interface/Build ETA'
options_order = { 'showonlyonshift'}
options = {
	
	showonlyonshift = {
		name = 'Show only on shift',
		type = 'bool',
		value = false,
		--OnChange = function() Spring.SendCommands{'showhealthbars'} end,
	},
}

		
--------------------------------------------------------------------------------

local vsx, vsy = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
end


--------------------------------------------------------------------------------

local function MakeETA(unitID,unitDefID)
	if (unitDefID == nil) then return nil end
	local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
	if (buildProgress == nil) then 
		return nil 
	end

	local ud = UnitDefs[unitDefID]
	if (ud == nil)or(ud.height == nil) then 
		return nil 
	end

	return {
		firstSet = true,
		lastTime = Spring.GetGameSeconds(),
		lastProg = buildProgress,
		rate     = nil,
		lastNewTime = nil,
		timeLeft = nil,
		--prev     = {count = 0, times = {}}, --for the super complex unneded stuff
		yoffset  = ud.height+14,
	}
end


--------------------------------------------------------------------------------

function widget:Initialize()
	local myUnits = Spring.GetTeamUnits(Spring.GetMyTeamID())
	for _,unitID in ipairs(myUnits) do
		local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
		if (buildProgress < 1) then
			etaTable[unitID] = MakeETA(unitID,Spring.GetUnitDefID(unitID))
		end
	end
end


--------------------------------------------------------------------------------

local function updateTime(bi, dt, newTime)

	if bi.lastNewTime and dt < 2 then
		bi.timeLeft = (newTime + bi.lastNewTime - dt)/2
	else
		bi.timeLeft = newTime
	end

	bi.lastNewTime = newTime

end

--[[ Stuff for multiple averaging over many past times, a bit overcomplex
local function updateTime(bi, dt, newTime)
	
	local i = 1
	local timeLeft = newTime
	
	while i <= bi.prev.count do
		bi.prev.times[i].age = bi.prev.times[i].age + dt
		bi.prev.times[i].value = bi.prev.times[i].value - dt
		if bi.prev.times[i].age > 1 then
			bi.prev.times[i] = bi.prev.times[bi.prev.count]
			bi.prev.times[bi.prev.count] = nil
			bi.prev.count = bi.prev.count - 1
			
		else
			timeLeft = timeLeft + bi.prev.times[i].value
			i = i + 1
		end
	end

	bi.prev.count = bi.prev.count + 1
	bi.prev.times[bi.prev.count] = {value = newTime, age = 0}
	
	bi.timeLeft = timeLeft/bi.prev.count
	
end
--]]

local lastGameUpdate = Spring.GetGameSeconds()

function widget:Update()

	local _,_,pause = Spring.GetGameSpeed()
	if (pause) then
		return
	end

	local gs = Spring.GetGameSeconds()
	if (gs == lastGameUpdate) then
		return
	end
	lastGameUpdate = gs
  
	local killTable = {}
	for unitID,bi in pairs(etaTable) do
		local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
		if ((not buildProgress) or (buildProgress >= 1.0)) then
			table.insert(killTable, unitID)
		else
			local dp = buildProgress - bi.lastProg 
			local dt = gs - bi.lastTime
			if (dt > 2) then
				bi.firstSet = true
				bi.rate = nil
				bi.timeLeft = nil
			end
			
			if dt > 0.5 then
				local rate = dp / dt

				if (rate ~= 0) then
					if (bi.firstSet) then
						if (buildProgress > 0.001) then
							bi.firstSet = false
						end
					else
						--[[ Nothing uses this currently but it could be useful in the future
						local rf = 0.5
						if (bi.rate == nil) then
							bi.rate = rate
						else
							bi.rate = ((1 - rf) * bi.rate) + (rf * rate)
						end
						-]]
						if (rate > 0) then
							updateTime(bi, dt, (1 - buildProgress) / rate)
						elseif (rate < 0) then
							updateTime(bi, -dt, buildProgress / rate)
						end
					end
					bi.lastTime = gs
					bi.lastProg = buildProgress
				end
			end
			
		end
	end
	for _,unitID in pairs(killTable) do
		etaTable[unitID] = nil
	end
end


--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local spect,spectFull = Spring.GetSpectatingState()
	if Spring.AreTeamsAllied(unitTeam,Spring.GetMyTeamID()) or (spect and spectFull) then
		etaTable[unitID] = MakeETA(unitID,unitDefID)
	end
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	etaTable[unitID] = nil
end


function widgetHandler:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	etaTable[unitID] = nil
end

local terraunitDefID = UnitDefNames["terraunit"].id

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitDefID ~= terraunitDefID then
		etaTable[unitID] = nil
	end
end


--------------------------------------------------------------------------------

local function DrawEtaText(timeLeft,yoffset)
	local etaStr
	if (timeLeft == nil) then
		etaStr = '\255\255\255\1ETA\255\255\255\255:\255\1\1\255???'
	else
		if (timeLeft > 60) then
			etaStr = "\255\255\255\1ETA\255\255\255\255:" .. string.format('\255\1\255\1%d', timeLeft / 60) .. "m, " .. string.format('\255\1\255\1%.1f', timeLeft % 60) .. "s"
		elseif (timeLeft > 0) then
			etaStr = "\255\255\255\1ETA\255\255\255\255:" .. string.format('\255\1\255\1%.1f', timeLeft) .. "s"
		else
			etaStr = "\255\255\255\1ETA\255\255\255\255:" .. string.format('\255\255\1\1%.1f', -timeLeft) .. "s"
		end
	end

	gl.Translate(0, yoffset,0)
	gl.Billboard()
	gl.Translate(0, 5 ,0)
	--fontHandler.DrawCentered(etaStr)
	gl.Text(etaStr, 0, 0, 8, "c")
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() or (options.showonlyonshift.value and not select(4,Spring.GetModKeyState())) then return end
	gl.DepthTest(true)

	gl.Color(1, 1, 1)
	--fontHandler.UseDefaultFont()

	for unitID, bi in pairs(etaTable) do
		gl.DrawFuncAtUnit(unitID, false, DrawEtaText, bi.timeLeft,bi.yoffset)
	end

	gl.DepthTest(false)
end
  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
