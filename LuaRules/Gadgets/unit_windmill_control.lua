
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


local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local windmills = IterableMap.New()

local TIDAL_HEIGHT = -10

local windMin, windMax, tidalStrength, windRange

local strength, next_strength, strength_step, step_count = 0,0,0,0

local MIN_BOUND = 0.4 -- minWind is restricted so minWind <= maxWind*MIN_BOUND
local BASE_ENERGY_PROPORTION_PER_ALT = 0.4 * 1/400 -- The minWind increase per alt as a proportion of maxWind
local BASE_ALT_EXTREME = 600

local energyPropPerAlt = BASE_ENERGY_PROPORTION_PER_ALT

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
		if (not windmills.IsEmpty()) then
			if step_count > 0 then
				strength = strength + strength_step
				step_count = step_count - 1
			end
			local _, _, _, windStrength, x, _, z = spGetWind()
			local windHeading = spGetHeadingFromVector(x,z)/2^15*math.pi+math.pi
			
			GG.WindHeading = windHeading
			GG.WindStrength = (strength - windMin)/windRange
			Spring.SetGameRulesParam("WindHeading", GG.WindHeading)
			Spring.SetGameRulesParam("WindStrength", GG.WindStrength)
			
		
			for i = 1, #teamList do
				teamEnergy[teamList[i]] = 0
			end
			local indexMax, keyByIndex, dataByKey = windmills.GetBarbarianData()
			for i = 1, indexMax do
				local unitID = keyByIndex[i]
				local entry = dataByKey[unitID]
				local windEnergy = (windMax - strength)*entry.myMin + strength
				local paralyzed = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
				if (not paralyzed) then
					local tid = entry.teamID
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

	local x, y, z = spGetUnitPosition(unitID)
	
	if Spring.GetGroundHeight(x, z) <= TIDAL_HEIGHT then
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
	
	local unitDef = UnitDefs[unitDefID]
	local windData = {
		myMin = math.max(0, math.min(MIN_BOUND, (y - GG.WindGroundMin)*energyPropPerAlt)),
		teamID = Spring.GetUnitTeam(unitID),
	}
	
	spSetUnitRulesParam(unitID,"minWind", windMin + windRange*windData.myMin, inlosTrueTable)
	spSetUnitTooltip(
		unitID, --Spring.GetUnitTooltip(unitID)..
		unitDef.humanName .. " - " .. unitDef.tooltip ..
		" (E " .. round(windMin+windRange*windData.myMin,1) .. "-" .. round(windMax,1) .. ")"
	)
	
	windmills.Add(unitID, windData)
	
	return true, windMin+windRange*windData.myMin, windRange*(1-windData.myMin)
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
	Spring.SetGameRulesParam("tidalHeight", TIDAL_HEIGHT)

	local minWindMult = 1
	if (mapInfo and mapInfo.custom and tonumber(mapInfo.custom.zkminwindmult) ~= nil ) then
		minWindMult = tonumber(mapInfo.custom.zkminwindmult)
	end
	
	local groundMin, groundMax = Spring.GetGroundExtremes()
	local waterlevel = Spring.GetGameRulesParam("waterlevel")
	local groundMin, groundMax = math.max(groundMin - waterlevel,0), math.max(groundMax - waterlevel, 1)
	local mexHeight = math.max(0, Spring.GetGameRulesParam("mex_min_height") or groundMin)

	GG.WindGroundMin = (groundMin + mexHeight)/2
	local groundExtreme = groundMax - GG.WindGroundMin
	if groundExtreme > BASE_ALT_EXTREME then
		energyPropPerAlt = BASE_ENERGY_PROPORTION_PER_ALT*BASE_ALT_EXTREME/groundExtreme
	end
	
	Spring.SetGameRulesParam("WindGroundMin", GG.WindGroundMin)
	Spring.SetGameRulesParam("WindSlope", energyPropPerAlt)
	Spring.SetGameRulesParam("WindMinBound", MIN_BOUND)

	--this is a function defined between 0 and 1, so we can adjust the gadget
	-- effect between 0% (flat maps) and 100% (mountained maps)
	--slope = minWindMult * 1/(1+math.exp(4 - groundExtreme/105))

	strength = (rand() * windRange) + windMin

	for i = 1, #teamList do
		teamEnergy[teamList[i]] = 0
		spSetTeamRulesParam(teamList[i], "WindIncome", 0, alliedTrueTable)
	end
	
	gadgetHandler:AddChatAction("windanim", ToggleWindAnimation, "Toggles windmill animations.")
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, unitTeam)
	if (windDefs[unitDefID]) then
		local data = windmills.Get(unitID)
		if data then
			data.teamID = unitTeam
			windmills.Set(unitID, data)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if (windDefs[unitDefID]) then
		windmills.Remove(unitID)
	end
end
