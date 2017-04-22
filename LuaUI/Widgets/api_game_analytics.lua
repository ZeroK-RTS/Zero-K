--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Game Analytics Handler",
		desc      = "Handles game analytics events",
		author    = "GoogleFrog",
		date      = "20 February 2017",
		license   = "GPL-v2",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config/Globals

local spGetTimer = Spring.GetTimer
local spDiffTimers = Spring.DiffTimers

local gameTimer
local myTeamID

local ANALYTICS_EVENT = "analyticsEvent_"
local ANALYTICS_EVENT_ERROR = "analyticsEventError_"
local ANALYTICS_VERSION = "v2"
local IS_DRY_RUN = false -- Whether to print the data instead of sending it

local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Categories

VFS.Include("LuaRules/Utilities/tablefunctions.lua")


local unitCategories = {}

unitCategories.basicEnergyBuildings = {
	armsolar     = true,
	armwin       = true,
}

unitCategories.advancedEnergyBuildings = {
	amgeo  = true, 
	armfus = true, 
	cafus  = true, 
	geo    = true, 
}

unitCategories.energyBuildings = Spring.Utilities.MergeTable(	unitCategories.basicEnergyBuildings, 
																unitCategories.advancedEnergyBuildings)

unitCategories.lightGroundTurrets = {
	armartic   = true,
	armdeva    = true,
	corllt     = true,
	corrl      = true,
	turrettorp = true,
	corgrav    = true,
}              

unitCategories.heavyGroundTurrets = {
	armanni  = true,
	corbhmth = true,
	corhlt   = true,
	cordoom  = true,
}

unitCategories.basicFactories = {
	factorycloak  = true,
	factoryhover  = true,
	factoryshield = true,
	factoryspider = true,
	factoryveh    = true,
}

unitCategories.advancedFactories = {
	factoryamph    = true,
	factorygunship = true,
	factoryjump    = true,
	factoryplane   = true,
	factoryship    = true,
	factorytank    = true,
}

unitCategories.factories = Spring.Utilities.MergeTable(	unitCategories.basicFactories,
														unitCategories.advancedFactories)

unitCategories.builders = {
	amphcon    = true,
	armca      = true,
	-- armcsa  = true,
	armrectr   = true,
	arm_spider = true,
	coracv     = true,
	corfast    = true,
	corch      = true,
	cornecro   = true,
	corned     = true,
	gunshipcon = true,
	shipcon    = true,
}

unitCategories.gameEnder = {
	zenith    = true,
	mahlazer  = true,
	raveparty = true,
	armbanth  = true, -- Not really a game ender, but beginners shouldn't build it early.
	armorco   = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local Analytics = {}

function Analytics.SendOnetimeEvent(eventName, value)
	if not luaMenu then
		return
	end

	local Send = IS_DRY_RUN and Spring.Echo or Spring.SendLuaMenuMsg

	local eventNameWithVersion = "game_" .. ANALYTICS_VERSION .. ":" .. eventName;

	if value then
		Send(ANALYTICS_EVENT .. eventNameWithVersion .. "|" .. value)
	else
		Send(ANALYTICS_EVENT .. eventNameWithVersion)
	end
end

function Analytics.SendErrorEvent(eventName, severity)
	if not luaMenu then
		return
	end
end

function Analytics.SendOnetimeEventWithTime(eventName)
	Analytics.SendOnetimeEvent(eventName, (gameTimer and spDiffTimers(spGetTimer(), gameTimer)) or 0)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Analytics collectors


function widget:GameFrame(frameNumber)
	if frameNumber == 0 then		
		Analytics.SendOnetimeEventWithTime("start_game_proper")
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

local loadSent = false
local startposSent = false

function widget:Update(dt)
	if not gameTimer then
		gameTimer = spGetTimer()
	end
	
	if not loadSent then
		local spectating = Spring.GetSpectatingState()
		loadSent = true
		
		if spectating then
			Analytics.SendOnetimeEvent("loaded_spectator")
			widgetHandler:RemoveCallIn("Update")
			return
		else
			Analytics.SendOnetimeEvent("loaded_player")
		end
	end
	myTeamID = Spring.GetMyTeamID()
	
	if not startposSent then
		local x,y,z = Spring.GetTeamStartPosition(myTeamID)
		if x then
			startposSent = true
			Analytics.SendOnetimeEventWithTime("startpoint_placed")
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitTeam ~= myTeamID then
		return
	end
	
	local ud = unitDefID and UnitDefs[unitDefID]
	if not ud then
		return
	end

	if builderID then
		-- Only trigger for builtunits. Not capture, share, Claw, commander spawn etc..
		Analytics.SendOnetimeEventWithTime("unit:first_start_building:" .. ud.name)
		
		for categoryName, units in pairs(unitCategories) do
			if units[ud.name] then
				Analytics.SendOnetimeEventWithTime("unit_category:first_start_building_" .. categoryName)
			end
		end
		
	end
end

function widget:Initialize() 
	WG.Analytics = Analytics
	Analytics.SendOnetimeEvent("begin_load")
end




