if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name    = "Block direct control",
		desc    = "Disables FPS mode.",
		author  = "GoogleFrog",
		date    = "5 November 2018",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true
	}
end

local spIsCheatingEnabled = Spring.IsCheatingEnabled

local modOptions = Spring.GetModOptions() or {}
local cheatNotRequired = modOptions.allowfpsmode == "1" or modOptions.allowfpsmode == 1

function gadget:AllowDirectUnitControl()
	return cheatNotRequired or spIsCheatingEnabled()
end

local function ToggleFpsMode(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	local arg = tonumber(words[1])
	if arg == 0 then
		cheatNotRequired = false
	elseif arg == 1 then
		cheatNotRequired = true
	else
		cheatNotRequired = not cheatNotRequired
	end
	
	Spring.Echo("First person view " .. ((cheatNotRequired and "enabled, select a unit and press Alt+P") or "disabled") .. ".")
	Spring.SetGameRulesParam("fps_need_cheat", cheatNotRequired and 0 or 1)
end

function gadget:Initialize()
	gadgetHandler:AddChatAction("allowfps", ToggleFpsMode, "Toggles whether FPS mode is allowed.")
	Spring.SetGameRulesParam("fps_need_cheat", cheatNotRequired and 0 or 1)
end
