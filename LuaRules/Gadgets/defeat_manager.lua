--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Defeat manager",
    desc      = "Manages defeat for teams",
    author    = "Google Frog",
    date      = "Feb 3, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-- Start unit setup creates the fake unit.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local fakeunitDefID = UnitDefNames["fakeunit"].id

local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetAllUnits		= Spring.GetAllUnits
local spGetUnitDefID	= Spring.GetUnitDefID
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
	return unitDefID ~= fakeunitDefID
end

--[[ Allow self-d to spec
function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	return unitDefID ~= fakeunitDefID
end
--]]

function checkAllUnits()
	deadAlliance = {}
	for _,allianceID in ipairs(spGetAllyTeamList()) do
		if allianceID ~= gaiaAlliance then
			deadAlliance[allianceID] = {count = 0, data = {}}
		end
	end
	
	for _, unitID in ipairs(spGetAllUnits()) do
		local ally = spGetUnitAllyTeam(unitID)
		if deadAlliance[ally] then
			if spGetUnitDefID(unitID) == fakeunitDefID then
				deadAlliance[ally].count = deadAlliance[ally].count + 1
				deadAlliance[ally].data[deadAlliance[ally].count] = unitID
			else
				deadAlliance[ally] = false
			end
		end
	end
	
	for ally, isDead in pairs(deadAlliance) do
		if isDead then
			for i = 1, deadAlliance[ally].count do
				Spring.DestroyUnit(deadAlliance[ally].data[i], false, false)
			end
		end
	end
end

function gadget:GameFrame(frame)
	if frame%30 == 0 then
		checkAllUnits()
	end
end