-- Legacy version of the file which pollutes the global namespace
-- Kept mostly for user widget backwards compatibility

local commandIDs = Spring.Utilities.CMD
local env = getfenv()
for cmdName, cmdID in pairs(commandIDs) do
	env["CMD_" .. cmdName] = cmdID
end

-- Legacy synonym, not present in the main table
env.CMD_SETHAVEN = commandIDs.RETREAT_ZONE
