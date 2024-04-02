function gadget:GetInfo()
	return {
		name    = "Field Factory",
		desc    = "Allows units to take construction options from factories and build them in the field.",
		author  = "GoogleFrog",
		date    = "2 April 2024",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
	}
end

local fieldFacDefID = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.customParams.field_factory then
		fieldFacDefID[unitDefID] = true
	end
end

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
}

local removedCmdDesc = {}
local fieldBuildOpts = {}
do
	local alreadyAdded = {}
	for i = 1, #factories do
		local factoryName = factories[i]
		if UnitDefNames[factoryName] then
			local buildList = UnitDefNames[factoryName].buildOptions
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

local canBuild = {}
local isFieldFac = {}

local function RemoveUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (cmdDescID) then
		if not removedCmdDesc[lockDefID] then
			local toRemove = Spring.GetUnitCmdDescs(unitID, cmdDescID, cmdDescID)
			removedCmdDesc[lockDefID] = toRemove[1]
		end
		Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
		if canBuild[unitID] and canBuild[unitID] == lockDefID then
			canBuild[unitID] = nil
		end
	end
end

local function AddUnit(unitID, lockDefID)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, -lockDefID)
	if (not cmdDescID) and removedCmdDesc[lockDefID] then
		Spring.InsertUnitCmdDesc(unitID, removedCmdDesc[lockDefID])
		canBuild[unitID] = lockDefID
	end
end

function GG.FieldConstruction_NotifyPlop(unitID, factoryID, factoryDefID)
	if not factoryDefID then
		return
	end
	local buildList = UnitDefs[factoryDefID].buildOptions
	if not buildList and buildList[2] then
		return
	end
	AddUnit(unitID, buildList[2])
end

function gadget:UnitCreated(unitID, unitDefID)
	if not fieldFacDefID[unitDefID] then
		return
	end
	isFieldFac[unitID] = true
	for i = 1, #fieldBuildOpts do
		RemoveUnit(unitID, fieldBuildOpts[i])
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if not fieldFacDefID[unitDefID] then
		return
	end
	isFieldFac[unitID] = nil
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeamID, x, y, z)
	if not isFieldFac[builderID] then
		return true
	end
	return (not fieldBuildOpts[unitDefID]) or (canBuild[builderID] == unitDefID)
end
