--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
  return {
    name      = "Turn Without Interia",
    desc      = "Remove turn interia because I don't want to deal with configuring it propperly right now (and such a change would not work for 91.0 anyway).",
    author    = "Google Frog",
    date      = "7 Sep 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

local spSetGroundMoveTypeData  = Spring.MoveCtrl.SetGroundMoveTypeData
local getMovetype              = Spring.Utilities.getMovetype
local spMoveCtrlGetTag         = Spring.MoveCtrl.GetTag

local turnAccels = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if getMovetype(unitDef) == 2 then -- Ground/Sea
		turnAccels[unitDefID] = unitDef.turnRate * 1.2
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	local turnAccel = turnAccels[unitDefID]
	if turnAccel and not spMoveCtrlGetTag(unitID) then
		-- FIXME: it should be possible to optimize this and get rid of the GetTag check.
		-- Doing the check before calling UnitCreated in Initialize() takes care of that venue (eg /luarules reload mid-jump)
		-- and moving the gadget to some high layer should take care of units that are perma-movectrl'd (eg mahlazer satellite or something)
		spSetGroundMoveTypeData(unitID, "turnAccel", turnAccel)
	end
end

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end