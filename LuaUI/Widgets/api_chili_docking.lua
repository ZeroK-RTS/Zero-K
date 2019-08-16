local version = "v1.001"

function widget:GetInfo()
  return {
    name      = "Chili Docking",
    desc      = version .." Provides docking and position saving for chili windows",
    author    = "Licho",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    experimental = false,
    handler   = true, -- to read widget status. eg: "widgetHandler.knownWidgets[name]"
    enabled   = true,  --  loaded by default?
    alwaysStart = true,
  }
end

local Chili
local Window
local screen0

local lastPos = {} -- "windows" indexed array of {x,y,x2,y2}
local settings = {} -- "window name" indexed array of {x,y,x2,y,2}
local buttons = {} -- "window name" indexed array of minimize buttons
local forceUpdate = false
local frameCounter = 0

local lastCount = 0
local lastWidth = 0
local lastHeight = 0

----------------------------------------------------
-- Options
----------------------------------------------------
options_path = 'Settings/HUD Panels/Extras/Docking'
options_order = { 'dockEnabled', 'dockEnabledPanels', 'minimizeEnabled', 'dockThreshold'}
options = {
	dockThreshold = {
		name = "Docking distance",
		type = 'number',
		advanced = true,
		value = 5,
		min=1,max=50,step=1,
		OnChange = {function()
			forceUpdate = true
		end },
	},
	dockEnabled = {
		name = 'Enable docking',
		advanced = false,
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Dock windows to screen edges',
	},
	dockEnabledPanels = {
		name = 'Use docking between panels',
		advanced = false,
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Dock windows each other to prevent overlaps. Requires docking to be enabled via the previous setting.',
	},
	minimizeEnabled = {
		name = 'Minimizable windows',
		advanced = false,
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'When enabled certain windows will have minimization tabs.',
	},
}

----------------------------------------------------
----------------------------------------------------

local function Docking_GetWindowSettings(name)
	if name and settings and settings[name] then
		local settingsPos = settings[name]
		
		local x = settingsPos[1]
		local y = settingsPos[2]
		local w = settingsPos[3] - x
		local h = settingsPos[4] - y
		return x,y,w,h
	end
end
function WG.GetWindowPosAndSize(windowName)
	if not windowName then
		return false
	end
	local window = screen0:GetChildByName(windowName)
	if not window then
		return false
	end
	return window.x, window.y, window.width, window.height
end

function WG.SetWindowPosAndSize(window,x,y,w,h)
	lastPos[window] = nil
	settings[window] = {x,y,x+w,y+h}
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget) --"widget" as extra argument because "handler=true"
		return
	end
	WG.Docking_GetWindowSettings = Docking_GetWindowSettings

	-- setup Chili
	Chili = WG.Chili
	Window = Chili.Window
	screen0 = Chili.Screen0
end

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
	
	if axis ~= nil then
		return axis, dist
	else
		return nil, nil
	end
end

-- returns closest axis to snap to existing windows or screen edges - first parameter is axis (L/R/T/D) second is snap distance
local function GetClosestAxis(winPos, dockWindows, win, screenEdgeOnly)
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
	
	if screenEdgeOnly then
		return nil, nil
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

local function GetButtonPos(win)
	local size = 5 -- button thickness
	local mindist = win.x*5000 + win.height
	local mode = 'L'
	
	local dist = win.y*5000 + win.width
	if dist < mindist then
		mindist = dist
		mode = 'T'
	end
	
	dist = (screen0.width - win.x - win.width)*5000 + win.height
	if dist < mindist then
		mindist = dist
		mode = 'R'
	end
	
	dist = (screen0.height - win.y - win.height)*5000 + win.width
	if dist < mindist then
		mindist = dist
		mode = 'B'
	end
	
	if mode == 'L' then
		return {x=win.x-3, y= win.y, width = size, height = win.height}
	elseif mode =='T' then
		return {x=win.x, y= win.y-3, width = win.width, height = size}
	elseif mode =='R' then
		return {x=win.x + win.width - size-3, y= win.y, width = size, height = win.height}
	elseif mode=='B' then
		return {x=win.x, y= win.y + win.height - size-3, width = win.width, height = size}
	end
end

function widget:Update()
	frameCounter = frameCounter +1
	if (not screen0) or (frameCounter % 88 ~= 87 and #screen0.children == lastCount) then
		return
	end
	lastCount = #screen0.children
	
	local posChanged = false -- has position changed since last check

	if (screen0.width ~= lastWidth or screen0.height ~= lastHeight) then
		forceUpdate = true
		lastWidth = screen0.width
		lastHeight = screen0.height
	end
	
	local present = {}
	local names = {}
	for _, win in ipairs(screen0.children) do  -- NEEDED FOR MINIMIZE BUTTONS: table.shallowcopy(
		if win.dockable then
			names[win.name] = win
			present[win.name] = true
			local lastWinPos = lastPos[win.name]
			if lastWinPos == nil then  -- new window appeared
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

					if (win.resizable or win.tweakResizable) and not win.dockableNoResize then
						win:Resize(w, h, false, false)
					end
					
					win:SetPos(settingsPos[1], settingsPos[2])
				end
			elseif lastWinPos[1] ~= win.x or lastWinPos[2] ~= win.y or lastWinPos[3] ~= win.x+win.width or lastWinPos[4] ~= win.y + win.height then  -- window changed position
				posChanged = true
				settings[win.name] = { win.x, win.y, win.x + win.width, win.y + win.height } --save data immediately (useful when docking is not enabled)
			end
		end
	end
	
	for winName, data in pairs(lastPos) do  -- delete those not present atm (Redo/refresh docking when window un-minimized)
		if not (data.keepPresent or present[winName]) then
			lastPos[winName] = nil
		end
	end

	-- BUTTONS to minimize stuff
	-- FIXME HACK use object:IsDescendantOf(screen0) from chili to detect visibility, not this silly hack stuff with button.winVisible
	for name, win in pairs(names) do
		if win.minimizable and options.minimizeEnabled.value then
			local button = buttons[name]
			if not button then
				button = Chili.Button:New{
					x = win.x,
					y = win.y,
					width = 50,
					height = 20,
					caption = '',
					dockable = false,
					winName = win.name,
					tooltip = 'Minimize ' .. win.name,
					backgroundColor={0,1,0,1},
					widgetName = win.parentWidgetName,
					win = win,
					OnClick = {
						function(self)
							if button.winVisible then
								win.hidden = true -- todo this is needed for minimap to hide self, remove when windows can detect if its on the sreen or not
								button.tooltip = 'Expand ' .. button.winName
								button.backgroundColor={1,0,0,1}
								if not win.selfImplementedMinimizable then
									screen0:RemoveChild(win)
								else
									win.selfImplementedMinimizable(false)
								end
							else
								win.hidden = false
								button.tooltip = 'Minimize ' .. button.winName
								button.backgroundColor={0,1,0,1}
								if not win.selfImplementedMinimizable then
									screen0:AddChild(win)
								else
									win.selfImplementedMinimizable(true)
								end
							end
							button.winVisible = not button.winVisible
						end
					}
				}
				screen0:AddChild(button)
				button:BringToFront()
				buttons[name] = button
			end
			local pos = GetButtonPos(win)
			button:SetPos(pos.x,pos.y, pos.width, pos.height)
			if not button.winVisible then
				button.winVisible = true
				win.hidden = false
				button.tooltip = 'Minimize ' .. button.winName
				button.backgroundColor={0,1,0,1}
				button:Invalidate()
			end
		else
			local button = buttons[name]
			if button then
				screen0:RemoveChild(button)
				buttons[name] = nil
			end
		end
	end
	
	for name, button in pairs(buttons) do
		if not names[name] and button.winVisible then -- widget hid externally
			button.winVisible = false
            button.tooltip = 'Expand ' .. button.winName
			button.backgroundColor={1,0,0,1}
			button:Invalidate()
		end
		local widgetInfo = button.widgetName and widgetHandler.knownWidgets[button.widgetName]
		if widgetInfo and not widgetInfo.active then --check if widget was removed
			button:Dispose();
			buttons[name] = nil
		end
		if button.win.parent and button.win.parent.name ~= screen0.name then
			button:Dispose();
			buttons[name] = nil
		end
	end
	
	if forceUpdate or posChanged then
		forceUpdate = false
		local dockWindows = {}	 -- make work array of windows
		for _, win in ipairs(screen0.children) do
			local dock = win.collide or win.dockable
			if (dock) then
				if win.dockableSavePositionOnly or (not options.dockEnabled.value) then
					local winPos = {win.x, win.y, win.x + win.width, win.y + win.height}
					lastPos[win.name] = winPos
					settings[win.name] = winPos
				else
					dockWindows[win] = {win.x, win.y, win.x + win.width, win.y + win.height}
				end
			end
		end
		
		-- dock windows
		local mc = 2
		repeat
			for win, wp in pairs(dockWindows) do
				local numTries = 5
				repeat
					--Spring.Echo("box "..wp[1].. " " ..wp[2] .. " " ..wp[3] .. " " .. wp[4])
					local a,d = GetClosestAxis(wp, dockWindows, win, not options.dockEnabledPanels.value)
					if a~=nil then
						SnapBox(wp,a,d)
						--Spring.Echo("snap "..a .. "  " ..d)
					end
					numTries = numTries - 1
				until a == nil or numTries == 0
				win:SetPos(wp[1], wp[2])
				local winPos = { win.x, win.y, win.x + win.width, win.y + win.height }
				lastPos[win.name] = winPos
				settings[win.name] = winPos
			end

			mc = mc -1
		until mc == 0

	end
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end

function widget:SetConfigData(data)
	local vsx, vsy = gl.GetViewSizes()
	for k, v in pairs (data) do
		if v[5] then
			v[1] = v[1] + vsx
			v[3] = v[3] + vsx
			v[5] = nil
		end
		if v[6] then
			v[2] = v[2] + vsy
			v[4] = v[4] + vsy
			v[6] = nil
		end
	end
	settings = data
end

function widget:GetConfigData()
	local data = Spring.Utilities.CopyTable(settings, true)
	local vsx, vsy = gl.GetViewSizes()
	for k, v in pairs (data) do
		-- if closer to the edge opposite 0, save relative to it (to keep stuff at edge if someone migrates to a larger screen)
		if vsx - v[3] < v[1] then
			v[1] = v[1] - vsx
			v[3] = v[3] - vsx
			v[5] = true
		end
		if vsy - v[4] < v[2] then
			v[2] = v[2] - vsy
			v[4] = v[4] - vsy
			v[6] = true
		end
	end
	return data
end
