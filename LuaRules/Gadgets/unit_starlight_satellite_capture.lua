--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Starlight Satellite Capture",
		desc = "Whenever a Starlight with an active satellite is transferred, also transfer the satellite",
		author = "Anarchid",
		date = "1.07.2016",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spTransferUnit = Spring.TransferUnit

local transfers = {}
local alreadyAdded

function gadget:UnitGiven(unitID, unitDefID, newTeam)
	local satID = spGetUnitRulesParam(unitID, 'has_satellite')
	if not satID then
		return
	end

	transfers[satID] = newTeam
	if alreadyAdded then
		return
	end

	gadgetHandler:UpdateCallIn("GameFrame")
	alreadyAdded = true
end

function gadget:Initialize()
	alreadyAdded = false
	gadgetHandler:RemoveCallIn("GameFrame")
end

function gadget:GameFrame(f)
	for satID, team in pairs(transfers) do
		spTransferUnit(satID, team, false)
		transfers[satID] = nil
	end

	gadget:Initialize()
end

