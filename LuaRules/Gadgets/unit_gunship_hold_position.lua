--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Gunship Hold Position",
      desc      = "Makes gunships actually hold position when told to do so",
      author    = "Google Frog",
      date      = "15 Dec 2010",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true  
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

local CMD_REPEAT = CMD.REPEAT
local CMD_MOVE = CMD.MOVE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local holdUnits = {
	[UnitDefNames["armkam"].id] = true,
	[UnitDefNames["bladew"].id] = true,
	[UnitDefNames["corape"].id] = true,
	[UnitDefNames["armbrawl"].id] = true,
	[UnitDefNames["blackdawn"].id] = true,
	[UnitDefNames["corcrw"].id] = true,
}

local units = {}
local unitsByIndex = {count = 0, units = {}}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function removeUnit(unitID)
	if units[unitID].index ~= unitsByIndex.count then
		unitsByIndex.units[units[unitID].index] = unitsByIndex.units[unitsByIndex.count]
		units[unitsByIndex.units[unitsByIndex.count]].index = units[unitID].index
		unitsByIndex.units[unitsByIndex.count] = nil
	end
	unitsByIndex.count = unitsByIndex.count - 1
	units[unitID] = nil
end

local function addUnit(unitID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	unitsByIndex.count = unitsByIndex.count + 1
	unitsByIndex.units[unitsByIndex.count] = unitID
	units[unitID] = {re = re, x = x, y = y, z = z, index = unitsByIndex.count}
end


function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag)
	if holdUnits[unitDefID] then
		local cmd = Spring.GetCommandQueue(unitID)
		local movestate = Spring.GetUnitStates(unitID)["movestate"]
		if (not units[unitID]) and #cmd == 0 and movestate == 0 then
			addUnit(unitID)
		end
	end

end

function gadget:GameFrame(n)

	if n%6 == 3 and unitsByIndex.count ~= 0 then
		local i = 1
		while i <= unitsByIndex.count do
			local unitID = unitsByIndex.units[i]
			if Spring.ValidUnitID(unitID) then
			
				local cx, cy, cz = units[unitID].x, units[unitID].y, units[unitID].z
				
				local ux,uy,uz = Spring.GetUnitPosition(unitID)
				if (cx-ux)^2 + (cz-uz)^2 > 20^2 then
					Spring.SetUnitMoveGoal(unitID,cx,cy,cz)
				end

				i = i + 1
			else
				removeUnit(unitID)
			end
		end

	end
	
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)

	if holdUnits[unitDefID] then
		if units[unitID] then
			if not (cmdID == CMD.STOP or cmdID == CMD.FIRE_STATE or cmdID == CMD.SELFD or cmdID == CMD.ONOFF or 
				cmdID == CMD.CLOAK or cmdID == CMD.REPEAT or cmdID == CMDTYPE.ICON_MODE or cmdID == CMDTYPE.ICON_MODE) then
				removeUnit(unitID)
			end
		else
			if cmdID == CMD.MOVE_STATE and cmdParams[1] == 0 then
				local cmd = Spring.GetCommandQueue(unitID)
				if #cmd == 0 then
					addUnit(unitID)
				end
			end
		end
	end
	
	return true
end

function gadget:UnitDestroyed(unitID,unitDefID,teamID)
	if units[unitID] then
		removeUnit(unitID)
	end
end
