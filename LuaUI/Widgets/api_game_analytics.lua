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
	energysolar     = true,
	energywind       = true,
}

unitCategories.advancedEnergyBuildings = {
	energyheavygeo  = true,
	energyfusion = true,
	energysingu  = true,
	energygeo    = true,
}

unitCategories.energyBuildings = Spring.Utilities.MergeTable(unitCategories.basicEnergyBuildings, unitCategories.advancedEnergyBuildings)

unitCategories.lightGroundTurrets = {
	turretemp   = true,
	turretriot    = true,
	turretlaser     = true,
	turretmissile      = true,
	turrettorp = true,
	turretimpulse    = true,
}

unitCategories.heavyGroundTurrets = {
	turretantiheavy  = true,
	staticarty = true,
	turretheavylaser   = true,
	turretheavy  = true,
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

unitCategories.factories = Spring.Utilities.MergeTable(unitCategories.basicFactories, unitCategories.advancedFactories)

unitCategories.builders = {
	amphcon    = true,
	planecon      = true,
	-- athena  = true,
	cloakcon   = true,
	spidercon = true,
	tankcon     = true,
	jumpcon    = true,
	hovercon      = true,
	shieldcon   = true,
	vehcon     = true,
	gunshipcon = true,
	shipcon    = true,
}

unitCategories.gameEnder = {
	zenith    = true,
	mahlazer  = true,
	raveparty = true,
	striderbantha  = true, -- Not really a game ender, but beginners shouldn't build it early.
	striderdetriment   = true,
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


function widget:GameStart()
	Analytics.SendOnetimeEventWithTime("start_game_proper")
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

		if (x and x ~= 0) or (z and z ~= 0) then
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

function widget:GameOver(winners)

	if not winners or #winners == 0 then
		return -- exited
	end

	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
	local localAllyTeamID = Spring.GetLocalAllyTeamID()
	for i = 1, #winners do
		local allyTeamID = winners[i]
		if allyTeamID == localAllyTeamID then
			Analytics.SendOnetimeEventWithTime("game:end:won")
			return
		elseif allyteamID == gaiaAllyTeamID then
			-- Analytics.SendOnetimeEventWithTime("game:end:draw")
			return
		end
	end

	Analytics.SendOnetimeEventWithTime("game:end:lost")
end
