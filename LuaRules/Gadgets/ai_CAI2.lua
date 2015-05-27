--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "CAI 2",
    desc      = "AI that plays normal ZK",
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

local AllyTeamInfoHandler = VFS.Include("LuaRules/Gadgets/CAI/AllyTeamInfoHandler.lua")
local AiTeamHandler = VFS.Include("LuaRules/Gadgets/CAI/AiTeamHandler.lua")

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
		--local _,_,_,isAI,side = spGetTeamInfo(team)
		if aiConfigByName[spGetTeamLuaAI(team)] then
			local _,_,_,_,_,_,CustomTeamOptions = spGetTeamInfo(team)
			if (not CustomTeamOptions) or (not CustomTeamOptions["aioverride"]) then -- what is this for?
				local _,_,_,_,_,allyTeam = spGetTeamInfo(team)
				
				if not allyTeamInfo[allyTeam] then
					allyTeamInfo[allyTeam] = AllyTeamInfoHandler.CreateAllyteamInfoHandler(allyTeam, team)
				end
				
				aiTeam[team] = AiTeamHandler.CreateAiTeam(allyteamID, team, allyTeamInfo[allyTeam])
				
				initialiseAiTeam(team, allyTeam, aiConfigByName[spGetTeamLuaAI(team)])
				aiOnTeam[allyTeam] = true
				usingAI = true
			end
		end
	end
	
	--// Setup AI if they exist or do nothing else.
	if not usingAI then
		Spring.SetGameRulesParam("CAI2_disabled", 1)
		gadgetHandler:RemoveGadget()
		return 
	end
	
end


--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------



end
