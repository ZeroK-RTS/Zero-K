--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "GameRules Events",
		desc = "Sets RulesParams to tell widgets what is going on in the game, and tells skirmish AIs the same",
		author = "Google Frog",
		date = "15 August 2015",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- The gadget intends to only tell players whether a nuke was launched recently
-- The lack of nuke counting or accurate timing is intentional.

local removeWarningFrame = false

local function GameRules_NukeLaunched()
	local frame = Spring.GetGameFrame()
	Spring.SetGameRulesParam("recentNukeLaunch", 1)
	removeWarningFrame = frame + 150 + 50*math.random()
	SendToUnsynced("GameRules_AIMessage", "NUKE_LAUNCHED")
end

-- Nuke explosions are globally visible, so AIs get their position. Whether an
-- airburst was an intercept or a shield hit is not visible, so it is not sent.
local function GameRules_NukeDetonated(px, py, pz)
	SendToUnsynced("GameRules_AIMessage", "NUKE_EXPLOSION:" .. math.floor(px) .. "," .. math.floor(py) .. "," .. math.floor(pz))
end

function gadget:GameFrame(frame)
	if removeWarningFrame and removeWarningFrame < frame then
		Spring.SetGameRulesParam("recentNukeLaunch", 0)
		removeWarningFrame = false
	end
end

function gadget:Initialize()
	Spring.SetGameRulesParam("recentNukeLaunch", 0)
	GG.GameRules_NukeLaunched = GameRules_NukeLaunched
	GG.GameRules_NukeDetonated = GameRules_NukeDetonated
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else -- UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SendAIMessage(_, msg)
	local localPlayer = Spring.GetLocalPlayerID()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, _, _, isAI = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local _, _, aiHost = Spring.GetAIInfo(teamID)
			if aiHost == localPlayer then
				Spring.SendSkirmishAIMessage(teamID, msg)
			end
		end
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("GameRules_AIMessage", SendAIMessage)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("GameRules_AIMessage")
end

end
