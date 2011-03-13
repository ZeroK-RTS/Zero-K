--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Starlight Drawer",
    desc      = "Imma sketching with mah lazor",
    author    = "GoogleFrog",
    date      = "26 Feb 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
	enabled	  = false,
 }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mahLazorUnitDefID = UnitDefNames["mahlazer"].id

local mahLazors = {}

local MAH_UPDATE_FREQUENCY = 5

local CMD_ATTACK = CMD.ATTACK

--[[
function ping()
	local playerID = Spring.GetLocalPlayerID()
	local ping = select(6, Spring.GetPlayerInfo(playerID))
	Spring.Echo(ping)
	return ping
end
--]]

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if Spring.GetMyTeamID() == unitTeam and mahLazorUnitDefID == unitDefID then
		mahLazors[unitID] = {height = false }
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if mahLazors[unitID] then
		mahLazors[unitID] = nil
	end
end

function widget:GameFrame(frame)
	if frame%MAH_UPDATE_FREQUENCY == 0 then
		for unitID, data in pairs(mahLazors) do
			local cmd = Spring.GetUnitCommands(unitID)
			if cmd and #cmd > 2 and cmd[1].id == CMD_ATTACK and #cmd[1].params == 3 and cmd[2].id == CMD_ATTACK then
				if data.height then
					local c1height = Spring.GetGroundHeight(cmd[1].params[1],cmd[1].params[3])
					if data[i].height ~= c1height or math.abs(c1height - cmd[1].params[2]) > 32 then
						data.height = Spring.GetGroundHeight(cmd[2].params[1],cmd[2].params[3])
						Spring.GiveOrderToUnit(unitID, CMD_ATTACK, cmd[1].params, CMD.OPT_SHIFT)
						if Spring.GetUnitStates(unitID)["repeat"] then
							Spring.GiveOrderToUnit(unitID, CMD_ATTACK, {cmd[1].params[1], data.height, cmd[1].params[3]}, CMD.OPT_SHIFT)
						end
					end
				else
					data.height = Spring.GetGroundHeight(cmd[1].params[1],cmd[1].params[3])
				end
			end
		end
	end
end

function widget:Initialize()
	local team = Spring.GetMyTeamID()
	for _, unitID in ipairs(Spring.GetTeamUnits(team)) do
		widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), team)
	end
end

