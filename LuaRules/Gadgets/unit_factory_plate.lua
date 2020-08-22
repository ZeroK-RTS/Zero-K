--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Factory Plate",
		desc      = "Handles factory plate disable/enable.",
		author    = "GoogleFrog",
		date      = "22 August 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("LuaRules/Configs/constants.lua")

local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spValidUnitID       = Spring.ValidUnitID

local ALLY_ACCESS = {allied = true}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local FACTORY_RANGE_SQ = FACTORY_PLATE_RANGE^2 -- see LuaRules/Configs/constants.lua

local childOfFactory = {}
local parentOfPlate = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local cp = ud.customParams
	if cp.child_of_factory then
		childOfFactory[i] = UnitDefNames[cp.child_of_factory].id
	end
	if cp.parent_of_plate then
		parentOfPlate[i] = UnitDefNames[cp.parent_of_plate].id
	end
end

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local factories = IterableMap.New()
local plates    = IterableMap.New()

local updateStateNextFrame = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DistSq(x1, z1, x2, z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

local function IsFactoryEligible(plate, factory)
	if (not factory.enabled) or plate.allyTeamID ~= factory.allyTeamID or plate.tech ~= factory.tech then
		return false
	end
	return DistSq(plate.x, plate.z, factory.x, factory.z) <= FACTORY_RANGE_SQ
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateState(unitID, plateData, inFrame)
	if ((plateData.parent and true) or false) == plateData.enabled and not plateData.forceStateUpdate then
		return
	end
	plateData.enabled = ((plateData.parent and true) or false)
	plateData.forceStateUpdate = false
	
	local env = Spring.UnitScript.GetScriptEnv(unitID)
	if env then
		Spring.UnitScript.CallAsUnit(unitID, env.SetFactoryAccess, plateData.enabled)
	else
		plateData.forceStateUpdate = true
		if not inFrame then
			updateStateNextFrame = updateStateNextFrame or {}
			updateStateNextFrame[#updateStateNextFrame + 1] = unitID
		end
	end
	
	local noFactory = (plateData.enabled and 0) or 1
	spSetUnitRulesParam(unitID, "selfIncomeChange", 1 - noFactory, ALLY_ACCESS)
	spSetUnitRulesParam(unitID, "nofactory", noFactory, ALLY_ACCESS)
	GG.UpdateUnitAttributes(unitID)
end

local function CheckPotentialParent(unitID, plateData, index, factoryID, factoryData)
	if plateData.parent or not IsFactoryEligible(plateData, factoryData) then
		return
	end
	
	plateData.parent = factoryID
	UpdateState(unitID, plateData)
end

local function FindParent(unitID, plateData)
	for factoryID, factoryData in IterableMap.Iterator(factories) do
		if IsFactoryEligible(plateData, factoryData) then
			plateData.parent = factoryID
			UpdateState(unitID, plateData)
			return
		end
	end
	UpdateState(unitID, plateData)
end

local function DoOrphaning(unitID, plateData, index, factoryID)
	if plateData.parent ~= factoryID then
		return
	end
	
	plateData.parent = false
	FindParent(unitID, plateData)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckOrphansAgainstFactory(factoryID, factoryData)
	IterableMap.Apply(plates, CheckPotentialParent, factoryID, factoryData)
end

local function OrphanChildren(unitID)
	IterableMap.Apply(plates, DoOrphaning, unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateEnabled(unitID, factoryData, index)
	if not spValidUnitID(unitID) then
		return true -- Remove from iterable map
	end
	local newEnabled = not (spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID,"disarmed") == 1) or (spGetUnitRulesParam(unitID,"morphDisable") == 1))
	
	if factoryData.enabled == newEnabled then
		return
	end
	factoryData.enabled = newEnabled
	
	if newEnabled then
		CheckOrphansAgainstFactory(unitID, factoryData)
	else
		OrphanChildren(unitID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if updateStateNextFrame then
		for i = 1, #updateStateNextFrame do
			local unitID = updateStateNextFrame[i]
			local plateData = IterableMap.Get(plates, unitID)
			if plateData then
				UpdateState(unitID, plateData, true)
			end
		end
		updateStateNextFrame = false
	end
	
	if not (n % TEAM_SLOWUPDATE_RATE == 16) then
		return
	end
	IterableMap.Apply(factories, UpdateEnabled)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if parentOfPlate[unitDefID] then
		local x,_,z = Spring.GetUnitPosition(unitID)
		local _, _, inbuild = Spring.GetUnitIsStunned(unitID)
		IterableMap.Add(factories, unitID, {
			unitDefID = unitDefID,
			x = x,
			z = z,
			tech = unitDefID,
			allyTeamID = Spring.GetUnitAllyTeam(unitID),
			enabled = not inbuild,
		})
		
		local factoryData = IterableMap.Get(factories, unitID)
		if factoryData.enabled then
			CheckOrphansAgainstFactory(unitID, factoryData)
		end
	end
	
	if childOfFactory[unitDefID] then
		local x,_,z = Spring.GetUnitPosition(unitID)
		IterableMap.Add(plates, unitID, {
			unitDefID = unitDefID,
			x = x,
			z = z,
			tech = childOfFactory[unitDefID],
			allyTeamID = Spring.GetUnitAllyTeam(unitID),
			parent = false,
			enabled = false,
			forceStateUpdate = true,
		})
		
		local plateData = IterableMap.Get(plates, unitID)
		FindParent(unitID, plateData)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if parentOfPlate[unitDefID] then
		IterableMap.Remove(factories, unitID)
		OrphanChildren(unitID)
		return
	end
	if childOfFactory[unitDefID] then
		IterableMap.Remove(plates, unitID)
		return
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	gadget:UnitDestroyed(unitID, unitDefID, teamID)
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	gadget:UnitCreated(unitID, unitDefID, teamID)
end

function gadget:Initialize()
	IterableMap.Clear(factories)
	IterableMap.Clear(plates)
	
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
