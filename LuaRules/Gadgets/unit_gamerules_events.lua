--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "GameRules Events",
		desc = "Sets RulesParams to tell widgets what is going on in the game",
		author = "Google Frog",
		date = "15 August 2015",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- The gadget intends to only tell players whether a nuke was launched recently
-- The lack of nuke counting or accurate timing is intentional.

local removeWarningFrame = false

local function GameRules_NukeLaunched()
	local frame = Spring.GetGameFrame()
	Spring.SetGameRulesParam("recentNukeLaunch", 1)
	removeWarningFrame = frame + 150 + 50*math.random()
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
end
