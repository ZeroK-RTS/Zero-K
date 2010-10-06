function widget:GetInfo()
  return {
    name      = "Chili Docking",
    desc      = "Provides docking and position saving for chili windows",
    author    = "Licho",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    experimental = false,
    enabled   = true  --  loaded by default?
  }
end

local Chili
local Window
local screen0

local forceUpdate = false 
options_path = 'Settings/Interface/Docking'
options_order = { 'dockEnabled', 'dockThreshold', }
options = {
	dockThreshold = {
		name = "Docking distance",
		type = 'number',
		advanced = true,
		value = 20,
		min=1,max=50,step=1,
		OnChange = {function() 
			forceUpdate = true
		end },
	},
	
	dockEnabled = {
		name = 'Use docking',
		advanced = false,
		type = 'bool',
		value = true,
		desc = 'Dock windows to screen edges and each other to prevent overlaps',
	},
}



local lastPos = {} -- "windows" indexed array of {x,y,x2,y2}
local settings = {} -- "window name" indexed array of {x,y,x2,y,2}


function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	-- setup Chili
	 Chili = WG.Chili
	 Window = Chili.Window
	 screen0 = Chili.Screen0
end 

local frameCounter = 0



-- returns snap orientation of box A compared to box B and distance of their edges  - orientation = L/R/T/D and distance of snap
local function GetBoxRelation(boxa, boxb) 
	local mpah = 0 -- midposition a horizontal
	local mpbh = 0
	local mpav = 0
	local mpbv = 0

	local snaph, snapv
	
	if not (boxa[2] > boxb[4] or boxa[4] < boxb[2]) then  -- "vertical collision" they are either to left or to right
		mpah = (boxa[3] + boxa[1])/2  -- gets midpos
		mpbh = (boxb[3] + boxb[1])/2 
		snaph = true 
	end 

	if not (boxa[1] > boxb[3] or boxa[3] <boxb[1]) then  -- "horizontal collision" they are above or below
		mpav = (boxa[4] + boxa[2])/2  -- gets midpos
		mpbv = (boxb[4] + boxb[2])/2 
		snapv = true
	end 
	
	
	local axis = nil
	local dist = 99999
	if (snaph) then 
		if mpah < mpbh then 
			axis = 'R'
			dist = boxb[1] - boxa[3]
		else 
			axis = 'L'
			dist = boxa[1] - boxb[3]
		end 
	end 
	
	if (snapv) then 
		if mpav < mpbv then 
			local nd = boxb[2] - boxa[4]
			if  math.abs(nd) < math.abs(dist) then  -- only snap this axis if its shorter "snap" distance 
				axis = 'D'
				dist = nd
			end 
		else 
			local nd = boxa[2] - boxb[4]
			if math.abs(nd) < math.abs(dist) then 
				axis = 'T'
				dist = nd
			end 
			
		end 
	end 
	
	if axis ~= nil then return axis, dist 
	else return nil, nil end
end 


-- returns closest axis to snap to existing windows or screen edges - first parameter is axis (L/R/T/D) second is snap distance 
local function GetClosestAxis(winPos, dockWindows, win)
	local dockDist = options.dockThreshold.value 
	local minDist =  dockDist + 1
	local minAxis= 'L'	
	
	local function CheckAxis(dist, newAxis) 
		if dist < minDist and dist ~= 0 then 
			if newAxis == 'L' and (winPos[1] - dist < 0 or winPos[3] - dist > screen0.width) then return end 
			if newAxis == 'R' and (winPos[1] + dist < 0 or winPos[3] + dist > screen0.width) then return end 
			if newAxis == 'T' and (winPos[2] - dist < 0 or winPos[4] - dist > screen0.height) then return end 
			if newAxis == 'D' and (winPos[2] + dist < 0 or winPos[4] + dist > screen0.height) then return end 
			minDist = dist
			minAxis = newAxis
		end 
	end 

	CheckAxis(winPos[1], 'L') 
	CheckAxis(winPos[2], 'T')
	CheckAxis(screen0.width - winPos[3], 'R')
	CheckAxis(screen0.height - winPos[4], 'D')
	if (minDist < dockDist and minDist ~= 0) then 
		return minAxis, minDist  -- screen edges have priority ,dont check anything else
	end 
	
	for w, dp in pairs(dockWindows) do 
		if win ~= w then 
			local a, d = GetBoxRelation(winPos, dp)
			if a ~= nil then 
				CheckAxis(d, a)
			end 
		end 
	end 

	
	if minDist < dockDist and minDist ~= 0 then 
		return minAxis, minDist
	else 
		return nil, nil
	end 
end 


-- snaps box data with axis and distance 
local function SnapBox(wp, a,d) 
	if a == 'L' then 
		wp[1] = wp[1] - d 
		wp[3] = wp[3] - d 
	elseif a== 'R' then 
		wp[1] = wp[1] + d 
		wp[3] = wp[3] + d 
	elseif a== 'T' then 
		wp[2] = wp[2] - d 
		wp[4] = wp[4] - d 
	elseif a== 'D' then 
		wp[2] = wp[2] + d 
		wp[4] = wp[4] + d 
	end 
end 

local lastCount = 0

function widget:DrawScreen() 
	frameCounter = frameCounter +1
	if (frameCounter % 88 ~= 87 and #screen0.children == lastCount) then return end 
	lastCount = #screen0.children
	
	local posChanged = false -- has position changed since last check

	local present = {}
	for _, win in ipairs(screen0.children) do 
		if (win.dockable) then 
			present[win] = true
			local lastWinPos = lastPos[win]
			if lastWinPos==nil then  -- new window appeared
				posChanged = true 
				local settingsPos = settings[win.name]
				if settingsPos ~= nil then  -- and we have setings stored for new window, apply it
					local w = settingsPos[3] - settingsPos[1]
					local h = settingsPos[4] - settingsPos[2]

					if win.fixedRatio then 
						local limit = 0
						if (w > h) then limit = w else limit = h end 
						if (win.width > win.height) then
							w = limit
							h = limit*win.height/win.width
						else 
							h = limit 
							w = limit*win.width/win.height
						end 
					end

					if win.resizable or win.tweakResizable then
						win:Resize(w, h, false, false)
					end
					win:SetPos(settingsPos[1], settingsPos[2])
					if not options.dockEnabled.value then 
						lastPos[win] = { win.x, win.y, win.x + win.width, win.y + win.height }
					end 
				end 
			elseif lastWinPos[1] ~= win.x or lastWinPos[2] ~= win.y or lastWinPos[3] ~= win.x+win.width or lastWinPos[4] ~= win.y + win.height then  -- window changed position
				posChanged = true 
			end 
		end 
	end 
	
	for win, _ in pairs(lastPos) do  -- delete those not present atm
		if not present[win] then lastPos[win] = nil end
	end 
	
	if forceUpdate or (posChanged and options.dockEnabled.value) then 
		forceUpdate = false
		local dockWindows = {}	 -- make work array of windows 
		for _, win in ipairs(screen0.children) do 
			if (win.dockable) then 
				dockWindows[win] = {win.x, win.y, win.x + win.width, win.y + win.height}
			end 
		end 
			
		-- dock windows 
		local mc = 2
		repeat 
			for win, wp in pairs(dockWindows) do  
				local numTries = 5
				repeat 
					--Spring.Echo("box "..wp[1].. " " ..wp[2] .. " " ..wp[3] .. " " .. wp[4])
					local a,d = GetClosestAxis(wp,dockWindows, win)
					if a~=nil then 
						SnapBox(wp,a,d)
						--Spring.Echo("snap "..a .. "  " ..d)
					end 
					numTries = numTries - 1 
				until a == nil or numTries == 0
				
				win:SetPos(wp[1], wp[2])
				local winPos = { win.x, win.y, win.x + win.width, win.y + win.height }
				lastPos[win] = winPos
				settings[win.name] = winPos
			end 

			mc = mc -1
		until mc == 0

	end 
end 





function widget:SetConfigData(data)
	settings = data
end

function widget:GetConfigData()
	return settings
end



