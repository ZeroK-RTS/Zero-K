
function gadget:GetInfo()
	return {
		name      = "Dev Command Checker",
		desc      = "Checks sent commands",
		author    = "GoogleFrog",
		date      = "11 Nov 2019",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge + 1,
		enabled   = true,  --  loaded by default?
		handler   = true,
	}
end


if (not gadgetHandler:IsSyncedCode()) then
	return
end

local spIsCheatingEnabled = Spring.IsCheatingEnabled

local lightCheckEnabled = false
local heavyCheckEnabled = false

local function LightCheck(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	
	lightCheckEnabled = not lightCheckEnabled
	Spring.Echo("Light Command Checker " .. ((lightCheckEnabled and "Enabled.") or "Disabled."))
end

local function HeavyCheck(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	
	if words[1] and tonumber(words[1]) then
		local frame = math.abs(tonumber(words[1]) or 1)
		heavyCheckEnabled = frame
		Spring.Echo("Heavy Command Checker set to frame " .. heavyCheckEnabled)
	else
		Spring.Echo("Heavy Command Checker Disabled (send frame parameter).")
	end
end

local SIZE_LIMIT = 10^8
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if heavyCheckEnabled and Spring.GetGameFrame() >= heavyCheckEnabled then
		Spring.Utilities.UnitEcho(unitID, cmdID)
		Spring.Echo("T", teamID, "C", cmdID)
		Spring.Utilities.TableEcho(cmdParams, "cmdParams")
		Spring.Utilities.TableEcho(cmdOptions, "cmdOptions")
		for i = 1, #cmdParams do
			Spring.Echo("Param", i, cmdParams[i], cmdParams[i] < -SIZE_LIMIT or cmdParams[i] > SIZE_LIMIT)
		end
	elseif lightCheckEnabled then
		Spring.Echo("T", teamID, "C", cmdID, "P", cmdParams and #cmdParams)
	end
	return true
end

function gadget:Initialize()
	gadgetHandler.actionHandler.AddChatAction(self, "cmdl", LightCheck, "LightCheck")
	gadgetHandler.actionHandler.AddChatAction(self, "cmdh", HeavyCheck, "LightCheck")
end
