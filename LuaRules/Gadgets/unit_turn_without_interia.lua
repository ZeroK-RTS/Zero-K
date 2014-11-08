function gadget:GetInfo()
  return {
    name      = "Turn Without Interia",
    desc      = "Remove turn interia because I don't want to deal with configuring it propperly right now (and such a change would not work for 91.0 anyway).",
    author    = "Google Frog",
    date      = "7 Sep 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = not Game.version:find("91.0")
  }
end

if not gadgetHandler:IsSyncedCode() then
	return
end

local spSetGroundMoveTypeData  = Spring.MoveCtrl.SetGroundMoveTypeData
local getMovetype = Spring.Utilities.getMovetype

function gadget:UnitCreated(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local ud = UnitDefs[unitDefID]
	if getMovetype(ud) == 2 then -- Ground/Sea
		spSetGroundMoveTypeData(unitID, "turnAccel", ud.turnRate*1.2)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end