function gadget:GetInfo() return {
	name    = "Script notification",
	desc    = "Notifies scripts about various events.",
	author  = "Sprung",
	date    = "2015-03-12",
	license = "PD",
	layer   = -1,
	enabled = true,
} end

if (not gadgetHandler:IsSyncedCode()) then return end

local spGetScriptEnv = Spring.UnitScript.GetScriptEnv
local spCallAsUnit   = Spring.UnitScript.CallAsUnit

local function callScript (unitID, funcName, args)
	local func = spGetScriptEnv(unitID)
	if func then
		func = func[funcName]
		if func then
			return spCallAsUnit(unitID, func, args)
		end
	end
	return false
end

local function ScriptNotifyEMPed (unitID)
	callScript (unitID, "Stunned", 1)
end

local function ScriptNotifyDisarmed (unitID)
	callScript (unitID, "Stunned", 0)
end

function gadget:Initialize ()
	GG.ScriptNotifyEMPed    = ScriptNotifyEMPed
	GG.ScriptNotifyDisarmed = ScriptNotifyDisarmed
end