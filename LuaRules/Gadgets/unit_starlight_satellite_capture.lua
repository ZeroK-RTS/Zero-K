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

local transfers = {}

function gadget:UnitGiven(unitID, unitDefID, newTeam)
    local satID = Spring.GetUnitRulesParam(unitID,'has_satellite');
    if(satID) then
        transfers[satID] = newTeam
    end
end

function gadget:GameFrame(f)
    for satID, team in pairs(transfers) do
        Spring.TransferUnit(satID, team, false)
        transfers[satID] = nil
    end
end
