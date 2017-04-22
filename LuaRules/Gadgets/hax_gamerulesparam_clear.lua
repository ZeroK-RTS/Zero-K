--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo() 
	return {
		name      = "GameRulesParam clearer",
		desc      = "Workaround https://springrts.com/mantis/view.php?id=5412",
		author    = "GoogleFrog",
		date      = "5 December 2016",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge, -- Load before everything else
		enabled   = true,
	} 
end

function gadget:Initialize()
	local gameRulesParams = Spring.GetGameRulesParams()
	for key, value in pairs(gameRulesParams) do
		Spring.SetGameRulesParam(key, nil)
	end
end
