function gadget:GetInfo()
	return {
		name    = "Field Factory",
		desc    = "Allows units to take construction options from factories and build them in the field.",
		author  = "GoogleFrog",
		date    = "2 April 2024",
		license = "GNU GPL, v2 or later",
		layer   = 10, -- Wants to be before mission handler for locking.
		enabled = true,
	}
end

local CMD_FIELD_FAC_SELECT    = Spring.Utilities.CMD.FIELD_FAC_SELECT
local CMD_FIELD_FAC_UNIT_TYPE = Spring.Utilities.CMD.FIELD_FAC_UNIT_TYPE

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local facSelectCmd = {
	id      = CMD_FIELD_FAC_SELECT,
	type    = CMDTYPE.ICON_UNIT,
	cursor  = 'facselect',
	action  = 'field_fac_select',
	name    = 'Factory Select',
	params  = { },
	hidden  = false,
}

local canBuild = {}
local isFieldFac = {}
local nextDesiredUnitType = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Build option adding and removal.

local fieldFacRange = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.customParams.field_factory then
		fieldFacRange[unitDefID] = ud.buildDistance
	end
end

local ALLY_TABLE = {ally = true}

local factories = {
	[[factoryshield]],
	[[factorycloak]],
	[[factoryveh]],
	[[factoryplane]],
	[[factorygunship]],
	[[factoryhover]],
	[[factoryamph]],
	[[factoryspider]],
	[[factoryjump]],
	[[factorytank]],
	[[factoryship]],
	[[striderhub]],
	[[plateshield]],
	[[platecloak]],
	[[plateveh]],
	[[plateplane]],
	[[plategunship]],
	[[platehover]],
	[[plateamph]],
	[[platespider]],
	[[platejump]],
	[[platetank]],
	[[plateship]],
}

local buildParams = {
	type = 20,
	action = "buildunit_etc",
	id = -1,
	tooltip = "",
	cursor = "etc",
	showUnique = false,
	params = {},
	name = "etc",
	onlyTexture = false,
	disabled = false,
	hidden = false,
	queueing = true,
	texture = "",
}

local factoryDefIDs = {}
local fieldBuildOpts = {}
do
	local alreadyAdded = {}
	for i = 1, #factories do
		local factoryName = factories[i]
		local ud = UnitDefNames[factoryName]
		if ud then
			factoryDefIDs[ud.id] = true
			local buildList = ud.buildOptions
			for j = 1, #buildList do
				local buildDefID = buildList[j]
				if not alreadyAdded[buildDefID] then
					fieldBuildOpts[#fieldBuildOpts + 1] = buildDefID
					alreadyAdded[buildDefID] = true
				end
			end
		end
	end
end

local function RemoveUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		if canBuild[unitID] and canBuild[unitID] == lockDefID then
			canBuild[unitID] = nil
		end
	end
end

local function AddUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (not cmdDescID) then
		local name = UnitDefs[lockDefID].name
		buildParams.id = -lockDefID
		buildParams.cursor = name
		buildParams.name = name
		buildParams.action = "buildunit_name"
		Spring.InsertUnitCmdDesc(unitID, buildParams)
		canBuild[unitID] = lockDefID
		Spring.SetUnitRulesParam(unitID, "fieldFactoryUnit", lockDefID, ALLY_TABLE)
	end
end

local function FactoryCanBuild(unitID, unitDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -unitDefID)
	if not cmdDescID then
		return true, true
	end
	if (GG.att_EconomyChange[unitID] or 1) <= 0 then
		return true, false
	end
	local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
	return stunnedOrInbuild, false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command handling

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_FIELD_FAC_SELECT] = true, [CMD_FIELD_FAC_UNIT_TYPE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if not (cmdID == CMD_FIELD_FAC_UNIT_TYPE or cmdID == CMD_FIELD_FAC_SELECT) then
		return true
	end
	if not fieldFacRange[unitDefID] then
		return false
	end
	if cmdID == CMD_FIELD_FAC_UNIT_TYPE then
		nextDesiredUnitType[unitID] = cmdParams and cmdParams[1]
		return false
	end
	if cmdID == CMD_FIELD_FAC_SELECT then
		if not cmdParams and cmdParams[1] and Spring.ValidUnitID(cmdParams[1]) then
			return false
		end
		if not Spring.AreTeamsAllied(teamID, Spring.GetUnitTeam(cmdParams[1])) then
			return false
		end
		nextDesiredUnitType[unitID] = false
		local targetDefID = Spring.GetUnitDefID(cmdParams[1])
		return targetDefID and factoryDefIDs[targetDefID]
	end
	
	return true
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD_FIELD_FAC_SELECT then
		return false
	end
	
	local targetID = cmdParams and cmdParams[1]
	if not Spring.ValidUnitID(targetID) then
		Spring.ClearUnitGoal(unitID)
		return true, true
	end
	local x, y, z = Spring.GetUnitPosition(targetID)
	if not z then
		Spring.ClearUnitGoal(unitID)
		return true, true
	end
	if nextDesiredUnitType[unitID] then
		local temporaryProblem, permanentProblem = FactoryCanBuild(targetID, nextDesiredUnitType[unitID])
		if permanentProblem then
			Spring.ClearUnitGoal(unitID)
			return true, true
		end
		local distance = Spring.GetUnitSeparation(unitID, targetID, true)
		if distance <= fieldFacRange[unitDefID] and not temporaryProblem then
			if canBuild[unitID] ~= nextDesiredUnitType[unitID] then
				if canBuild[unitID] then
					RemoveUnit(unitID, canBuild[unitID])
				end
				AddUnit(unitID, nextDesiredUnitType[unitID])
			end
			nextDesiredUnitType[unitID] = nil
			Spring.ClearUnitGoal(unitID)
			return true, true
		end
	end
	Spring.SetUnitMoveGoal(unitID, x, y, z, fieldFacRange[unitDefID] - 16)
	return true, false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- API

function GG.FieldConstruction_NotifyPlop(unitID, factoryID, factoryDefID)
	if not factoryDefID then
		return
	end
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not (unitDefID and fieldFacRange[unitDefID]) then
		return false
	end
	local buildList = UnitDefs[factoryDefID].buildOptions
	if not buildList and buildList[2] then
		return
	end
	AddUnit(unitID, buildList[2])
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeamID, x, y, z)
	if not isFieldFac[builderID] then
		return true
	end
	return (not fieldBuildOpts[unitDefID]) or (canBuild[builderID] == unitDefID)
end

function gadget:UnitCreated(unitID, unitDefID)
	if not fieldFacRange[unitDefID] then
		return
	end
	isFieldFac[unitID] = true
	local previousUnit = Spring.GetUnitRulesParam(unitID, "fieldFactoryUnit")
	for i = 1, #fieldBuildOpts do
		RemoveUnit(unitID, fieldBuildOpts[i])
	end
	if previousUnit then
		AddUnit(unitID, previousUnit)
	end
	Spring.InsertUnitCmdDesc(unitID, facSelectCmd)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if not fieldFacRange[unitDefID] then
		return
	end
	isFieldFac[unitID] = nil
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_FIELD_FAC_SELECT)
	Spring.SetCustomCommandDrawData(CMD_FIELD_FAC_SELECT, "FactorySelect", {0.2, 0.7, 1.0, 0.7})
	Spring.AssignMouseCursor("FactorySelect", "cursorfacselect", true, true)
	local allUnits = Spring.GetAllUnits()
	for i=1,#allUnits do
		local unitID = allUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_FIELD_FAC_SELECT)
	Spring.SetCustomCommandDrawData(CMD_FIELD_FAC_SELECT, "FactorySelect", {0.2, 0.7, 1.0, 0.7})
	Spring.AssignMouseCursor("facselect", "cursorfacselect", true, true)
end

end