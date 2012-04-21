
function gadget:GetInfo()
  return {
    name      = "Mex Placement",
    desc      = "Controls mex placement and income",
    author    = "Google Frog", -- 
    date      = "21 April 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end

include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
-- Command Definition
--------------------------------------------------------------------------------

local mexDefID = UnitDefNames["cormex"].id

local cmdMex = {
	id      = CMD_AREA_MEX,
	type    = CMDTYPE.ICON_AREA,
	tooltip = 'Define an area to make mexes in',
	name    = 'Mex',
	cursor  = 'Repair',
	action  = 'areamex',
	params  = {}, 
}

local canMex = {}
for udid, ud in ipairs(UnitDefs) do 
	for i, option in ipairs(ud.buildOptions) do 
		if mexDefID == option then
			canMex[udid] = true
			Spring.Echo(ud.name)
		end
	end
end


--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local spotByID = {}
local spotData = {}

local metalSpots = {}
local metalSpotsByPos = {}

--------------------------------------------------------------------------------
-- Command Handling
--------------------------------------------------------------------------------

local sameOrder = {}

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == -mexDefID) and metalSpots then
		local x = cmdParams[1]
		local z = cmdParams[3]
		--Spring.MarkerAddPoint(x,0,z,x .. ", " .. z)
		return x and z and metalSpotsByPos[x] and metalSpotsByPos[x][z]
	end
	return true
end

function gadget:Initialize()
	metalSpots = GG.metalSpots
	metalSpotsByPos = GG.metalSpotsByPos
	-- register command
	gadgetHandler:RegisterCMDID(CMD_AREA_MEX)
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

--------------------------------------------------------------------------------
-- Unit Tracker
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if canMex[unitDefID] then
		Spring.InsertUnitCmdDesc(unitID, cmdMex)
	end
	
	if unitDefID == mexDefID then
		local x,_,z = Spring.GetUnitPosition(unitID)
		if metalSpots then
			local spotID = metalSpotsByPos[x] and metalSpotsByPos[x][z]
			if spotID then
				spotByID[unitID] = spotID
				spotData[spotID] = {unitID = unitID}
				Spring.SetUnitRulesParam(unitID, "mexIncome", metalSpots[spotID].metal)
				--GG.UnitEcho(unitID,spotID)
			end
		else
			local metal = GG.IntegrateMetal(x, z)
			Spring.SetUnitRulesParam(unitID, "mexIncome", metal)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitDefID == mexDefID and spotByID[unitID] then
		spotData[spotByID[unitID]] = nil
		spotByID[unitID] = nil
	end
end