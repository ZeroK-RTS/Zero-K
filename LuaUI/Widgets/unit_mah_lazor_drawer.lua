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

local mahLazors = {data = {}, count = 0}
local mahLazorIDs = {}

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
		mahLazors.count = mahLazors.count + 1
		mahLazors.data[mahLazors.count] = {id = unitID, height = false }
		mahLazorIDs[unitID] = mahLazors.count
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if mahLazorIDs[unitID] then
		mahLazors.data[mahLazorIDs[unitID]] = mahLazors.data[mahLazors.count]
		mahLazors.data[mahLazors.count] = nil
		mahLazorIDs[mahLazors.data[mahLazorIDs[unitID]]] = mahLazorIDs[unitID]
		mahLazors.count = mahLazors.count - 1
		mahLazorIDs[unitID] = nil
	end
end

function widget:GameFrame(frame)
	if frame%MAH_UPDATE_FREQUENCY == 0 then
		for i = 1, mahLazors.count do
			local mahLazor = mahLazors.data[i].id
			local cmd = Spring.GetUnitCommands(mahLazor)
			if cmd and #cmd > 2 and cmd[1].id == CMD_ATTACK and #cmd[1].params == 3 and cmd[2].id == CMD_ATTACK then
				if mahLazors.data[i].height then
					if mahLazors.data[i].height ~= Spring.GetGroundHeight(cmd[1].params[1],cmd[1].params[3]) then
						Spring.GiveOrderToUnit(mahLazor, CMD_ATTACK, cmd[1].params, CMD.OPT_SHIFT)
						mahLazors.data[i].height = Spring.GetGroundHeight(cmd[2].params[1],cmd[2].params[3])
						if Spring.GetUnitStates(mahLazor)["repeat"] then
							Spring.GiveOrderToUnit(mahLazor, CMD_ATTACK, cmd[1].params, CMD.OPT_SHIFT)
						end
					end
				else
					mahLazors.data[i].height = Spring.GetGroundHeight(cmd[1].params[1],cmd[1].params[3])
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

