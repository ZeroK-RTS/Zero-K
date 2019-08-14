function gadget:GetInfo() return {
	name    = "Script notification",
	desc    = "Notifies scripts about various events.",
	author  = "Sprung",
	date    = "2015-03-12",
	license = "PD",
	layer   = -2,
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

function gadget:UnitStunned (unitID, unitDefID, unitTeam, state)
	if state then
		callScript (unitID, "Stunned", 2)
	else
		callScript (unitID, "Unstunned", 2)
	end
end

local function ScriptNotifyDisarmed (unitID, state)
	if state then
		callScript (unitID, "Stunned", 1)
	else
		callScript (unitID, "Unstunned", 1)
	end
end

local function ScriptNotifyUnpowered (unitID, state)
	if state then
		callScript (unitID, "Stunned", 4)
	else
		callScript (unitID, "Unstunned", 4)
	end
end

function gadget:UnitReverseBuilt (unitID)
	callScript (unitID, "Stunned", 3)
end
function gadget:UnitFinished (unitID)
	callScript (unitID, "Unstunned", 3)
end

function gadget:Initialize ()
	GG.ScriptNotifyDisarmed = ScriptNotifyDisarmed
	GG.ScriptNotifyUnpowered = ScriptNotifyUnpowered
end
