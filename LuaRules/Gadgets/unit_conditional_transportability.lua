function gadget:GetInfo() return {
	name    = "Conditional Transportability",
	desc    = "Allows units to only be transportable in some situations.",
	author  = "sprung",
	date    = "15-05-15",
	license = "PD",
	layer   = 0,
	enabled = true
} end

if (not gadgetHandler:IsSyncedCode()) then return end

function gadget:AllowCommand (unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local numParams = #cmdParams

	if (cmdID == CMD.INSERT and cmdParams[2]) then
		cmdID = cmdParams[2]
		cmdParams[1] = cmdParams[4]
		numParams = numParams - 3
	end

	if ((cmdID == CMD.LOAD_ONTO)
	and (Spring.GetUnitRulesParam(unitID, "untransportable") == 1)) then
		return false
	end

	if  (cmdID == CMD.LOAD_UNITS)
	and (numParams == 1) -- only block single-target load (not area load)
	and (Spring.GetUnitRulesParam(cmdParams[1], "untransportable") == 1) then
		return false
	end

	return true
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	Spring.SetUnitRulesParam(transportID, "untransportable", 1)

	if (Spring.GetUnitRulesParam(unitID, "untransportable") == 1) then
		-- there is no way to prevent load: allow it and immediately drop instead
		Spring.UnitScript.CallAsUnit(transportID, Spring.UnitScript.GetScriptEnv(transportID).ForceDropUnit, true)
	else
end

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	Spring.SetUnitRulesParam(transportID, "untransportable", 0)
end
