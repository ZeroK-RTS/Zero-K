if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Set public randomseed",
	license = "PD",
	layer   = -math.huge + 1, -- after hax_gamerulesparam_clear
	enabled = true,
} end

function gadget:Initialize()
	Spring.SetGameRulesParam("public_random_seed", math.random(1, 1000000))
end
