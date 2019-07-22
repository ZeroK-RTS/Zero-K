
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "Windmill Control",
		desc     = "Controls windmill helix and overrides map wind settings",
		author   = "quantum",
		date     = "June 29, 2007",
		license  = "GNU GPL, v2 or later",
		layer    = 2, -- after `start_waterlevel.lua` (for map height adjustment)
		enabled  = true -- loaded by default?
	}
end

-- Changelog:
--   CarRepairer: Enhanced to allow overriding map's min/max wind values in mod options. Negative values (default) will use map's values.
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("LuaRules/Configs/constants.lua")

local windDefs = {
	[ UnitDefNames['energywind'].id ] = true,
}

local windmills = {}
local groundMin, groundMax = 0,0
local groundExtreme = 0
local slope = 0
local tidalHeight = -10

local windMin, windMax, windRange, tidalStrength

local strength, next_strength, strength_step, step_count = 0,0,0,0

local teamList = Spring.GetTeamList()
local teamEnergy = {}

local alliedTrueTable = {allied = true}
local inlosTrueTable = {inlos = true}

local MAPSIDE_MAPINFO = "mapinfo.lua"
local mapInfo = VFS.FileExists(MAPSIDE_MAPINFO) and VFS.Include(MAPSIDE_MAPINFO) or false



-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- Speed-ups

local spGetWind              = Spring.GetWind
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetHeadingFromVector = Spring.GetHeadingFromVector
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitIsStunned     = Spring.GetUnitIsStunned
local spGetUnitRulesParam    = Spring.GetUnitRulesParam
local spSetUnitRulesParam    = Spring.SetUnitRulesParam
local spSetTeamRulesParam    = Spring.SetTeamRulesParam
local spSetUnitTooltip       = Spring.SetUnitTooltip

local sformat = string.format
local pi_2    = math.pi * 2
local fmod    = math.fmod
local atan2   = math.atan2
local rand    = math.random

local function round(num, idp)
	return sformat("%." .. (idp or 0) .. "f", num)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Debug

local function ToggleWindAnimation(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then 
		--return
	end
	GG.Wind_SpinDisabled = not GG.Wind_SpinDisabled
	
	if GG.Wind_SpinDisabled then
		Spring.Echo("Wind animation disabled")
	else
		Spring.Echo("Wind animation enabled")
		local allUnits = Spring.GetAllUnits()
		for i = 1, #allUnits do
			local env = Spring.UnitScript.GetScriptEnv(allUnits[i])
			if env and env.InitializeWind then
				Spring.UnitScript.CallAsUnit(allUnits[i], env.InitializeWind)
			end
		end
	
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if (((n+16) % TEAM_SLOWUPDATE_RATE) < 0.1) then
		if (next(windmills)) then
			
			if step_count > 0 then
				strength = strength + strength_step
				step_count = step_count - 1
			end
			local _, _, _, windStrength, x, _, z = spGetWind()
			local windHeading = spGetHeadingFromVector(x,z)/2^15*math.pi+math.pi
			
			Spring.SetGameRulesParam("WindHeading", windHeading)
			Spring.SetGameRulesParam("WindStrength", (strength-windMin)/windRange)
		
			for i = 1, #teamList do
				teamEnergy[teamList[i]] = 0
			end
			for unitID, entry in pairs(windmills) do
				local windEnergy = (windMax - strength)*entry[1].alt + strength
				local paralyzed = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
				if (not paralyzed) then
					local tid = entry[2]
					local incomeFactor = spGetUnitRulesParam(unitID,"resourceGenerationFactor") or 1
					windEnergy = windEnergy*incomeFactor
					teamEnergy[tid] = teamEnergy[tid] + windEnergy -- monitor team energy
					spSetUnitRulesParam(unitID, "current_energyIncome", windEnergy, inlosTrueTable)
				else
					spSetUnitRulesParam(unitID, "current_energyIncome", 0, inlosTrueTable)
				end
			end
			for i = 1, #teamList do
				spSetTeamRulesParam (teamList[i], "WindIncome", teamEnergy[teamList[i]], alliedTrueTable)
			end
		end
		if (((n+16) % (32*30)) < 0.1) then
			next_strength = (rand() * windRange) + windMin
			strength_step = (next_strength - strength) * 0.1
			step_count = 10
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function SetupUnit(unitID)
	if not windMin then
		gadget:Initialize()
	end
	
	local unitDefID = spGetUnitDefID(unitID)
	local midy = (unitDefID and UnitDefs[unitDefID] and UnitDefs[unitDefID].model.midy) or 18
	
	local scriptIDs = {}

	local x, y, z = spGetUnitPosition(unitID)
	
	if Spring.GetGroundHeight(x,z) <= tidalHeight then
		spSetUnitRulesParam(unitID, "wanted_energyIncome", tidalStrength, inlosTrueTable)
		Spring.SetUnitRulesParam(unitID, "NotWindmill",1)
		Spring.SetUnitMaxHealth(unitID, 400)
		local health = Spring.GetUnitHealth(unitID)
		if health == 130 then
			Spring.SetUnitHealth(unitID, 400)
		end
		Spring.SetUnitCollisionVolumeData(unitID, 30, 30, 30, 0, 0, 0, 0, 1, 0)
		Spring.SetUnitMidAndAimPos(unitID, 0, -5, 0, 0, 2, 0, true)
		Spring.SetUnitRulesParam(unitID, "midpos_override", -5 - midy)
		Spring.SetUnitRulesParam(unitID, "aimpos_override", 2 - midy)
		return false
	end
	
	spSetUnitRulesParam(unitID, "isWind", 1, inlosTrueTable)
	
	local altitude = (y - groundMin)/groundExtreme
	scriptIDs.alt = math.max(0, math.min(1, altitude*slope))

	local unitDef = UnitDefs[unitDefID]
	spSetUnitRulesParam(unitID,"minWind",windMin+windRange*scriptIDs.alt, inlosTrueTable)
	spSetUnitTooltip(
		unitID, --Spring.GetUnitTooltip(unitID)..
		unitDef.humanName .. " - " .. unitDef.tooltip ..
		" (E " .. round(windMin+windRange*scriptIDs.alt,1) .. "-" .. round(windMax,1) .. ")"
	)
	windmills[unitID] = {scriptIDs, Spring.GetUnitTeam(unitID)}
	
	return true, windMin+windRange*scriptIDs.alt, windRange*(1-scriptIDs.alt)
	
end

GG.SetupWindmill = SetupUnit

function gadget:Initialize()

	local energyMult = Spring.GetModOptions().energymult
	energyMult = energyMult and tonumber(energyMult) or 1

	windMin = 0 * energyMult
	windMax = 2.5 * energyMult
	tidalStrength = 1.2 * energyMult
	windRange = windMax - windMin

	Spring.SetGameRulesParam("WindMin",windMin)
	Spring.SetGameRulesParam("WindMax",windMax)
	Spring.SetGameRulesParam("tidalStrength",tidalStrength)
	Spring.SetGameRulesParam("WindHeading", 0)
	Spring.SetGameRulesParam("WindStrength", 0)
	Spring.SetGameRulesParam("tidalHeight", tidalHeight)

	local minWindMult = 1
	if (mapInfo and mapInfo.custom and tonumber(mapInfo.custom.zkminwindmult) ~= nil ) then
		minWindMult = tonumber(mapInfo.custom.zkminwindmult)
	end
	
	groundMin, groundMax = Spring.GetGroundExtremes()
	local waterlevel = Spring.GetGameRulesParam("waterlevel")
	groundMin, groundMax = math.max(groundMin - waterlevel,0), math.max(groundMax - waterlevel,1)
	groundExtreme = groundMax - groundMin
	if groundExtreme < 1 then
		groundExtreme = 1
	end

	--this is a function defined between 0 and 1, so we can adjust the gadget 
	-- effect between 0% (flat maps) and 100% (mountained maps)
	slope = minWindMult * 1/(1+math.exp(4 - groundExtreme/105))
	
	Spring.SetGameRulesParam("WindGroundMin", groundMin)
	Spring.SetGameRulesParam("WindGroundExtreme", groundExtreme)
	Spring.SetGameRulesParam("WindSlope", slope)

	strength = (rand() * windRange) + windMin

	for i = 1, #teamList do
		teamEnergy[teamList[i]] = 0
		spSetTeamRulesParam(teamList[i], "WindIncome", 0, alliedTrueTable)
	end
	
	gadgetHandler:AddChatAction("windanim", ToggleWindAnimation, "Toggles windmill animations.")
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, unitTeam)
	if (windDefs[unitDefID]) then 
		if windmills[unitID] then
			windmills[unitID].teamID = unitTeam
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (windDefs[unitDefID]) then 
		windmills[unitID] = nil
	end
end
