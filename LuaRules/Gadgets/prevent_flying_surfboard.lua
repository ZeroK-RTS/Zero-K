function gadget:GetInfo() return {
	name    = "Dont load Smurfboards",
	desc    = "Prevents awesomeness",
	author  = "sprung",
	date    = "17/11/13",
	license = "PD",
	layer   = 0,
	enabled = true
} end

if (not gadgetHandler:IsSyncedCode()) then return end

local surfboardDefID = UnitDefNames["armtboat"].id

function gadget:AllowCommand (unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local numParams = #cmdParams
    if (cmdID == CMD.INSERT and cmdParams[2]) then
		cmdID = cmdParams[2]
		cmdParams[1] = cmdParams[4] -- this only supports commands with 1 param
		numParams = numParams - 3
    end

	if ((cmdID == CMD.LOAD_ONTO) and (unitDefID == surfboardDefID)) then -- surfboard can't ask to embark
		return false
	elseif ((cmdID == CMD.LOAD_UNITS)
	and (numParams == 1) -- 1 for load specific unit; 3 for area load
	and Spring.ValidUnitID(cmdParams[1])
	and Spring.GetUnitDefID(cmdParams[1]) == surfboardDefID) then
		return false
	else
		return true
	end
end
