-- $Id: unit_ping2blip.lua 3566 2008-12-28 05:53:22Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Ping2Blip",
    desc      = "Creates fake radar signal on seismic ping for targetting purposes.",
    author    = "CarRepairer",
    date      = "2008-05-15",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring = Spring
local UnitDefs = UnitDefs

local pingedUnits = {}

--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------


function gadget:UnitSeismicPing(x, y, z, strength, detectorTeam, unitID, unitDefID)
	local _,_,_,_,_,detectorAllyTeam = Spring.GetTeamInfo(detectorTeam)
	local detectedAllyTeam = Spring.GetUnitAllyTeam(unitID)
	if detectorAllyTeam == detectedAllyTeam then return end
	
	local losState = Spring.GetUnitLosState(unitID, detectorAllyTeam)
	
	if losState.radar then
			Spring.Echo("Ping: (r) detectorteam", detectorAllyTeam, detectedAllyTeam, UnitDefs[unitDefID].name)
	else
		Spring.Echo("Ping: (!r) detectorteam", detectorTeam, UnitDefs[unitDefID].name)
		Spring.SetUnitLosState(unitID, detectorAllyTeam, {radar=true})
		pingedUnits[unitID] = detectorAllyTeam
	end
	
	--Spring.SetUnitLosMask(unitID, allyTeamID, number | table) -> nil
    --Spring.SetUnitLosState(unitID, allyTeamID, number | table) -> nil
	
end


function gadget:Initialize()
end

function gadget:GameFrame(n)

	if ( n % 8 < 0.1) then
		for unitID, allyTeam in pairs(pingedUnits) do
			--local allyTeam = pingedUnits[unitID]
			Spring.SetUnitLosState(unitID, allyTeam, {radar=false})
			pingedUnits[unitID] = nil
		end

	end
	
end


--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--  UNSYNCED
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------

