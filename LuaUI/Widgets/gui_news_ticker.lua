function widget:GetInfo()
	return {
		name	= "News Ticker",
		desc	= "v1.012 Keeps you up to date on important battlefield events",
		author	= "KingRaptor",
		date	= "July 26, 2009",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= false  --  loaded by default?
	}
end
include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include("LuaRules/Configs/constants.lua")

--[[
-- Features:
_ Informs player of unit completion/death events, with sound events depending of incomes ( so no constant 'unit operational unit operational unit operational' when building heaps of peewees).
-- To do:
_ Maybe fusion this with minimap_events.lua and unit_marker.lua as they have a pretty similar task, maybe even unit_sounds.
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Window
local Panel
local Label
local screen0

local labels = {}
local window_ticker
local panel_ticker

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local soundTimeout = 0
local lastEventFrame = {}

local lastUpdate = 0
local lastMExcessEvent = 0
local lastEStallEvent = 0
local airSpotted = false
local nukeSpotted = false

local UPDATE_PERIOD = 0.03	-- seconds
local UPDATE_PERIOD_LONG = 0.5	-- seconds
local UPDATE_PERIOD_RESOURCES = 90	-- gameframes
local RESOURCE_WARNING_PERIOD = 900	-- gameframes
local MAX_EVENTS = 20
local metalMap = false

local mIncome = 0

local colorRed = {1,0,0,1}
local colorOrange = {1,0.5,0,1}
local colorYellow = {1,1,0,1}
local colorGreen = {0,1,0,1}

--local myPlayer				= Spring.GetMyPlayerID()
local myTeam				= Spring.GetMyTeamID()
--------------------------------------------------------------------------------
--SPEEDUPS
--------------------------------------------------------------------------------
local Echo			= Spring.Echo
local spGetTeam			= Spring.GetUnitTeam
local spGetGameSeconds		= Spring.GetGameSeconds
local spInView			= Spring.IsUnitInView
local spGetTeamRes		= Spring.GetTeamResources
local spGetLastAttacker		= Spring.GetUnitLastAttacker
local spGetSpectatingState	= Spring.GetSpectatingState
local spIsReplay		= Spring.IsReplay
local spGetMyTeamID		= Spring.GetMyTeamID
local spAreTeamsAllied		= Spring.AreTeamsAllied

local spPlaySoundFile		= Spring.PlaySoundFile
local spMarkerAddPoint		= Spring.MarkerAddPoint
--------------------------------------------------------------------------------
--CONFIG
--------------------------------------------------------------------------------
local fontSize = 12
local labelSpacing = 15
local scrollSpeed = math.ceil(60*UPDATE_PERIOD)

local function SetTickerVisiblity()
end

options_path = 'Settings/HUD Panels/News Ticker'
options = {
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			panel_ticker.backgroundColor = {1,1,1,self.value}
			panel_ticker:Invalidate()
		end,
	},
	minCostMult = {
		name = "Minimum cost mult (1-20)",
		type = "number",
		value = 10, min = 1, max = 20, step = 1,
		desc = "Multiplies metal income for minimum cost of newsworthy units",
	},
	hideBar = {
		name = "Hide Bar",
		type = "bool",
		value = false,
		desc = "Hides the visible bar",
		OnChange = function(self)
			SetTickerVisiblity(not self.value)
		end
	},
	useSounds = {
		name = "Use Sounds",
		type = "bool",
		value = true,
		desc = "Voice announcements for events.",
	},
	
}

local timeoutConstant = 60

local sounds = {
	unitComplete = {file = "sounds/reply/advisor/unit_operational.wav"},
	structureComplete = {file = "sounds/reply/advisor/construction_complete.wav"},
	factoryIdle = {file = "sounds/reply/advisor/factory_idle.wav"},
	
	aircraftShotDown = {file = "sounds/reply/advisor/aircraft_shot_down.wav"},
	commanderLost = {file = "sounds/reply/advisor/commander_lost.wav"},
	buildingDestroyed = {file = "sounds/reply/advisor/building_destroyed.wav"},
	unitLost = {file = "sounds/reply/advisor/unit_lost.wav"},
	
	enemyAirSpotted = {file = "sounds/reply/advisor/enemy_aircraft_spotted.wav"},
	
	stallingMetal = {file = "sounds/reply/advisor/stall_metal.wav"},
	stallingEnergy = {file = "sounds/reply/advisor/stall_energy.wav"},
	
	excessMetal = {file = "sounds/reply/advisor/excess_metal.wav"},
}
for name,data in pairs(sounds) do
	data.timeout = data.timeout or timeoutConstant
end

local noMonitor = {
	[UnitDefNames.terraunit.id] = true,
}

--local mFactor = 10 --multiply by current M income to get the minimum cost for newsworthiness
local useDeathMinCost = true
local useCompleteMinCost = true
local logDeathInView = true
local logCompleteInView = true

--local widgetString = "\255\255\255\255<Unit News> \008"	--ARGB

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--function isSpec()
--	if (spGetSpectatingState or spIsReplay) then
--		return true
--	end
--end

-- add a news event - makes a label and plays a sound if needed
local function AddEvent(str, unitDefID, color, sound, pos)
	if #labels > MAX_EVENTS then
		return
	end
	local frame = Spring.GetGameFrame()
	if unitDefID then
		if lastEventFrame[unitDefID] == frame then return end -- FIXME: stupid way of doing spam protection
		lastEventFrame[unitDefID] = frame
	end
	
	if not options.hideBar.value then
		local x = window_ticker.width
		local lastLabel = labels[#labels]
		if lastLabel then
			x = math.max(x, lastLabel.x + lastLabel.width + labelSpacing)
		end
		
		local posTable
		if pos then
			posTable = { function() SetCameraTarget(pos[1], pos[2], pos[3], 1) end }
		end
		
		
		local newLabel = Label:New{
			width=string.len(str) * fontSize/2;
			height="100%";
			autosize=true;
			x=x,
			y=0,
			align="left";
			valign="top";
			caption = str,
			textColor = color,
			fontSize = fontSize;
			fontShadow = true;
			parent = panel_ticker;
			OnClick = posTable;
		}
	
		
		-- implements button mouse functionality for the panel
		function newLabel:HitTest(x,y) return self end
		function newLabel:MouseDown(...)
			local inherited = newLabel.inherited
			self._down = true
			inherited.MouseDown(self, ...)
			return self
		end
	
		function newLabel:MouseUp(...)
			local inherited = newLabel.inherited
			if (self._down) then
				self._down = false
				inherited.MouseUp(self, ...)
				return self
			end
		end
		
		labels[#labels+1] = newLabel
	end
	
	if options.useSounds.value and soundTimeout < frame then
		if WG.Cutscene and WG.Cutscene.IsInCutscene() then
			return
		end
		local soundInfo = sounds[sound]
		if not soundInfo then return end
		spPlaySoundFile(soundInfo.file, 1, 'ui')
		soundTimeout = frame + soundInfo.timeout
	end
end

--WG.AddNewsEvent = AddEvent	-- if we ever want other widgets to use the ticker

-- scrolls labels, removes the ones that run off the edge
local function ProcessLabels()
	local toRemove = {}
	for i=1,#labels do
		local label = labels[i]
		--label.x = label.x - scrollSpeed
		--label:Invalidate()
		label:SetPos(label.x - scrollSpeed)
		if label.x + label.width <= 0 then
			toRemove[#toRemove+1] = i
		end
	end
	for i=1, #toRemove do
		--Spring.Echo("Removing label "..toRemove[i])
		labels[toRemove[i]]:Dispose()
		table.remove(labels, toRemove[i])
	end
end

local function CheckSpecState()
	 if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
		Echo("<Unit News> Spectator mode or replay. Widget removed.")
		widgetHandler:RemoveWidget()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local timerUpdate = 0
local timerUpdateLong = 0
function widget:Update(dt)
	if myTeam ~= spGetMyTeamID() then
		myTeam = spGetMyTeamID()
	end
	timerUpdate = timerUpdate + dt
	if timerUpdate > UPDATE_PERIOD then
		ProcessLabels()
		timerUpdate = 0
	end
	--[[
	timerUpdateLong = timerUpdateLong + dt
	if timerUpdateLong > UPDATE_PERIOD_LONG then
		CheckSpecState()
		timerUpdateLong = 0
	end
	]]--
end

function widget:GameFrame(n)
	if n%UPDATE_PERIOD_RESOURCES == 0 then
		local mlevel, mstore,mpull,mincome = spGetTeamRes(myTeam, "metal")
		mstore = mstore - HIDDEN_STORAGE
		mIncome = mincome	-- global = our local
		if mstore > 0 and mlevel/mstore >= 0.95 and (not metalMap) and lastMExcessEvent + RESOURCE_WARNING_PERIOD < n then
			AddEvent("Excessing metal", nil, colorYellow, "excessMetal")
			lastMExcessEvent = n
		end
		local elevel,estore,epull,eincome = spGetTeamRes(myTeam, "energy")
		estore = estore - HIDDEN_STORAGE
		if estore > 0 and  elevel/estore <= 0.2 and lastEStallEvent + RESOURCE_WARNING_PERIOD < n  then
			AddEvent("Stalling energy", nil, colorOrange, "stallingEnergy")
			lastEStallEvent = n
		end
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	if (not spAreTeamsAllied(unitTeam, myTeam)) then
		local unitDef = UnitDefs[Spring.GetUnitDefID(unitID)]
		local pos = {Spring.GetUnitPosition(unitID)}
		if unitDef.canFly and not airSpotted then
			AddEvent("Enemy aircraft spotted", nil, colorRed, "enemyAirSpotted", pos)
			airSpotted = true
		elseif unitDef.name == "staticnuke" and not nukeSpotted then
			AddEvent("Enemy nuke silo spotted", nil, colorRed, "enemyNukeSpotted", pos)
			nukeSpotted = true			
		end
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	--don't report cancelled constructions etc.
	local killer = spGetLastAttacker(unitID)
	if killer == nil or killer == -1 or noMonitor[unitDefID] then return end
	local ud = UnitDefs[unitDefID]
	--don't bother player with cheap stuff
	if (spGetTeam(unitID) ~= myTeam) or (ud.metalCost < (mIncome * options.minCostMult.value) and useDeathMinCost) then return end
	--can u c me?
	if (spInView(unitID)) and (logDeathInView == false) then return end
	
	local pos = {Spring.GetUnitPosition(unitID)}
	
	local humanName = Spring.Utilities.GetHumanName(ud)
	if (ud.canFly) then AddEvent(humanName .. " shot down", unitDefID, colorRed, "aircraftShotDown", pos)
	elseif (ud.isFactory) then AddEvent(humanName .. ": factory destroyed", unitDefID, colorRed, "buildingDestroyed", pos)
	elseif (ud.customParams.commtype) then AddEvent(humanName .. ": commander lost", unitDefID, colorRed, "commanderLost", pos)
	elseif (ud.isImmobile) then AddEvent(humanName .. ": building destroyed", unitDefID, colorRed, "buildingDestroyed", pos)
	elseif (ud.modCategories.ship) or (ud.modCategories.sub) then AddEvent(humanName .. " sunk", unitDefID, colorRed, "unitLost", pos)
	elseif (ud.isBuilder) then AddEvent(humanName .. ": constructor lost", unitDefID, colorRed, "unitLost", pos)
	else AddEvent(humanName .. ": unit lost", unitDefID, colorRed, "unitLost", pos)
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	--visibility check
	if (spGetTeam(unitID) ~= myTeam) or (spInView(unitID)) and (logCompleteInView == false) then return end
	local ud = UnitDefs[unitDefID]
	--for name,param in ud:pairs() do
	--	Spring.Echo(name,param)
	--end
	-- cheap units aren't newsworthy unless they're builders
	if ((not ud.isBuilder) and (UnitDefs[unitDefID].metalCost < (mIncome * options.minCostMult.value) and useCompleteMinCost)) or noMonitor[unitDefID] then return end
	local pos = {Spring.GetUnitPosition(unitID)}
	
	local humanName = Spring.Utilities.GetHumanName(ud)
	if (not ud.canMove) or (ud.isFactory) then
		AddEvent(humanName .. ": construction completed", unitDefID, colorGreen, "structureComplete", pos)
	else
		AddEvent(humanName .. ": unit operational", unitDefID, colorGreen, "unitComplete", pos)
	end
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if ud.isFactory and (spGetTeam(unitID) == myTeam) then
		local pos = {Spring.GetUnitPosition(unitID)}
		AddEvent(Spring.Utilities.GetHumanName(ud) .. ": factory idle", unitDefID, colorYellow, "factoryIdle", pos)
	end
end

function widget:TeamDied(teamID)
	local player = Spring.GetPlayerList(teamID)[1]
	-- chicken team has no players (normally)
	if player then
		local playerName = Spring.GetPlayerInfo(player, false)
		AddEvent(playerName .. ' died', nil, colorOrange)
	end
end

--[[
function widget:TeamChanged(teamID)
	--// ally changed
	local playerName = Spring.GetPlayerInfo(Spring.GetPlayerList(teamID)[1], false)
	widget:AddWarning(playerName .. ' allied')
end
--]]

function widget:PlayerChanged(playerID)
	local playerName,active,isSpec,teamID = Spring.GetPlayerInfo(playerID, false)
  local _,_,isDead = Spring.GetTeamInfo(teamID, false)
	if (isSpec) then
		if not isDead then
			AddEvent(playerName .. ' resigned', nil, colorOrange)
		end
	elseif (Spring.GetDrawFrame()>120) then --// skip `changed status` message flood when entering the game
		AddEvent(playerName .. ' changed status', nil, colorYellow)
	end
end

function widget:PlayerRemoved(playerID, reason)
	local playerName,active,isSpec = Spring.GetPlayerInfo(playerID, false)
	if spec then return end
	if reason == 0 then
		AddEvent(playerName .. ' timed out', nil, colorOrange)
	elseif reason == 1 then
		AddEvent(playerName .. ' quit', nil, colorOrange)
	elseif reason == 2 then
		AddEvent(playerName .. ' got kicked', nil, colorOrange)
	else
		AddEvent(playerName .. ' left (unknown reason)', nil, colorOrange)
	end
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	metalMap = (not Spring.GetGameRulesParam("mex_count") or Spring.GetGameRulesParam("mex_count") == -1)
	--Spring.Echo("Is metal map: " .. tostring(metalMap))
	-- setup Chili
	Chili = WG.Chili
	Label = Chili.Label
	Window = Chili.Window
	Panel = Chili.Panel
	screen0 = Chili.Screen0
	
	--local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	window_ticker = Window:New{
		padding = {0,0,0,0},
		--itemMargin = {0, 0, 0, 0},
		dockable = true,
		name = "news_ticker_window",
		y = 50,	-- positioned directly under resbars
		right = 0,
		width  = 430,
		height = fontSize + 2,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		resizable = false,
		--autosize = true,
		minHeight = fontSize * 2 + 2,
		color = {0, 0, 0, 0}
	}
	panel_ticker = Panel:New{
		x = 0,
		y = 1,
		width  = "100%",
		height = fontSize * 2,
		parent = window_ticker,
		backgroundColor = {nil,nil,nil,options.backgroundOpacity.value or 0.7},
		OnMouseDown={ function(self) --//shortcut to option menu.
				local _,_, meta,_ = Spring.GetModKeyState()
				if not meta then return false end
				WG.crude.OpenPath(options_path)
				WG.crude.ShowMenu() --make epic Chili menu appear.
				return true
				end }, 
	}
	
	SetTickerVisiblity = function(bool)
		if bool then
			screen0:AddChild(window_ticker)
		else
			screen0:RemoveChild(window_ticker)
		end
	end
end
