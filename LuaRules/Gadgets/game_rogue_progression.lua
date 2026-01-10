--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions = Spring.GetModOptions() or {}

function gadget:GetInfo()
	return {
		name      = "Rogue-K Progression",
		desc      = "Progression handler for Rogue-K. Implements post-game unlocks and selecting next mission.",
		author    = "GoogleFrog",
		date      = "8 January 2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = tonumber(modOptions.rk_enabled or 0) == 1,
	}
end

local rewardDefs = VFS.Include("LuaRules/Configs/RogueK/reward_defs.lua")

local CustomKeyToUsefulTable = Spring.Utilities.CustomKeyToUsefulTable

local PLAYER_ALLYTEAM = 0

-- How many options are shown for a reward and how many extra are added with tech points.
local BASE_OPTIONS = 3
local TECH_OPTIONS = 3

local extraRewards = {} -- TODO, mid-mission bonus objective rewards are registered here

local function SetupTeamProgression(teamID, rewards)
	local _,_,_,_,_,_, customKeys = Spring.GetTeamInfo(teamID, true)
	
	-- The host reads rk_loadout when creating the next game. Players send updated
	-- loadouts to luarules for this purpose.
	Spring.SetTeamRulesParam(teamID, "rk_loadout", customKeys.rk_loadout)
	
	for i = 1, #rewards do
		local reward = rewardDefs.categories[rewards[i]]
		Spring.Echo("humanNamehumanNamehumanName", reward.humanName)
		Spring.SetTeamRulesParam(teamID, "rk_reward_name_" .. i, rewards[i])
		Spring.SetTeamRulesParam(teamID, "rk_reward_display_count_" .. i, BASE_OPTIONS)
		Spring.SetTeamRulesParam(teamID, "rk_reward_display_tech_" .. i, TECH_OPTIONS)
		Spring.Utilities.PermuteList(reward.options)
		for j = 1, #reward.options do
			Spring.SetTeamRulesParam(teamID, "rk_reward_option_" .. i .. "_" .. j, reward.options[j].name)
		end
	end
end

function gadget:RecvLuaMsg(message, playerID)
	if not (message and string.find(message, "rk_loadout")) then
		return
	end
	local _, _, spectator, teamID = Spring.GetPlayerInfo(playerID)
	if spectator then
		return
	end
	local loadout = message:sub(12)
	Spring.SetTeamRulesParam(teamID, "rk_loadout", loadout)
end

local function SetupProgression()
	local planetID = tonumber(modOptions.rk_battle_planet)
	local galaxy = CustomKeyToUsefulTable(modOptions.rk_galaxy)
	local rewards = galaxy.planets[planetID].rewards
	for i = 1, #extraRewards do
		rewards[#rewards + 1] = extraRewards[i]
	end
	
	local teamList = Spring.GetTeamList(PLAYER_ALLYTEAM)
	for i = 1, #teamList do
		local teamID = teamList[i]
		SetupTeamProgression(teamID, rewards)
	end
end

function gadget:Initialize()
	SetupProgression()
end