--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "CAI 2",
		desc      = "Another AI that plays normal ZK",
		author    = "Google Frog",
		date      = "12 May 8 2015",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local spGetUnitLosState = Spring.GetUnitLosState
local spGetTeamInfo     = Spring.GetTeamInfo
local spGetTeamList     = Spring.GetTeamList
local spGetTeamLuaAI    = Spring.GetTeamLuaAI

local AllyTeamInfoHandler = VFS.Include("LuaRules/Gadgets/CAI/AllyTeamInfoHandler.lua")
local AiTeamHandler = VFS.Include("LuaRules/Gadgets/CAI/AiTeamHandler.lua")
local PathfinderGenerator = VFS.Include("LuaRules/Gadgets/CAI/PathfinderGenerator.lua")

local aiConfigByName = {
	CAI2 = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local allyTeamInfo = {}
local aiTeam = {}
local pathfinder = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function InitializePathfinder()
	-- veh, bot, spider, ship, hover, amph, air
	return {
		PathfinderGenerator.CreatePathfinder(UnitDefNames["tankassault"].id, "tank4", true),
		PathfinderGenerator.CreatePathfinder(UnitDefNames["striderdante"].id, "kbot4", true),
		PathfinderGenerator.CreatePathfinder(UnitDefNames["spidercrabe"].id, "tkbot4", true),
		PathfinderGenerator.CreatePathfinder(UnitDefNames["hoverarty"].id, "hover3"),
		PathfinderGenerator.CreatePathfinder(UnitDefNames["subraider"].id, "uboat3", true),
		PathfinderGenerator.CreatePathfinder(UnitDefNames["amphassault"].id, "akbot4", true),
		PathfinderGenerator.CreatePathfinder(UnitDefNames["hoverarty"].id, "hover3"),
		PathfinderGenerator.CreatePathfinder(),
	}
end

function gadget:GameFrame(n)
	for teamID, aiData in pairs(aiTeam) do
		aiData.GameFrameUpdate(n)
	end
	for allyTeamID, allyTeamData in pairs(allyTeamInfo) do
		allyTeamData.GameFrameUpdate(n)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if aiTeam[unitTeam] then
		aiTeam[unitTeam].UnitCreatedUpdate(unitID, unitDefID, unitTeam)
	end
	for allyTeamID, allyTeamData in pairs(allyTeamInfo) do
		local visibilityTable = spGetUnitLosState(unitID, allyTeamID, false)
		if visibilityTable and (visibilityTable.los or visibilityTable.typed) then
			allyTeamData.UnitCreatedUpdate(unitID, unitDefID, unitTeam)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if aiTeam[unitTeam] then
		aiTeam[unitTeam].UnitDestroyedUpdate(unitID, unitDefID, unitTeam)
	end
	for allyTeamID, allyTeamData in pairs(allyTeamInfo) do
		local visibilityTable = spGetUnitLosState(unitID, allyTeamID, false)
		if visibilityTable and (visibilityTable.los or visibilityTable.typed) then
			allyTeamData.UnitDestroyedUpdate(unitID, unitDefID, unitTeam)
		end
	end
end

function gadget:Initialize()
	local aiOnTeam = {}
	usingAI = false

	--// Mex spot detection
	if not GG.metalSpots then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "CAI2: Fatal error, map not supported due to metal map.")
		Spring.SetGameRulesParam("CAI2_disabled", 1)
		gadgetHandler:RemoveGadget()
	end
	
	--// Detect the AIs
	for _,team in ipairs(spGetTeamList()) do
		--local _,_,_,isAI,side = spGetTeamInfo(team, false)
		if aiConfigByName[spGetTeamLuaAI(team)] then
			local _,_,_,_,_,allyTeam,CustomTeamOptions = spGetTeamInfo(team)
			if (not CustomTeamOptions) or (not CustomTeamOptions["aioverride"]) then -- what is this for?
				
				if not pathfinder then
					pathfinder = InitializePathfinder()
				end
				
				if not allyTeamInfo[allyTeam] then
					allyTeamInfo[allyTeam] = AllyTeamInfoHandler.CreateAllyTeamInfoHandler(allyTeam, team, pathfinder)
				end
				
				aiTeam[team] = AiTeamHandler.CreateAiTeam(allyteamID, team, allyTeamInfo[allyTeam])
				aiOnTeam[allyTeam] = true
				usingAI = true
			end
		end
	end
	
	--// Setup AI if they exist or do nothing else.
	if usingAI then
		Spring.SetGameRulesParam("CAI2_disabled", 0)
	else
		Spring.SetGameRulesParam("CAI2_disabled", 1)
		gadgetHandler:RemoveGadget()
		return 
	end
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		if udid then
			gadget:UnitCreated(unitID, udid, Spring.GetUnitTeam(unitID))
		end
	end
end

--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------


end
