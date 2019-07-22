--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Gunship Bugger Off",
		desc      = "Prevents gunships from landing in the gunships factory upon creation.",
		author    = "GoogleFrog",
		date      = "1 November, 2018",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
	return false  --  no unsynced code
end

local spGiveOrderToUnit = Spring.GiveOrderToUnit
local TAU      = 2*math.pi
local RADIUS   = 10
local CMD_WAIT = CMD.WAIT

local gunships = {}
for unitDefID = 1, #UnitDefs do
	if Spring.Utilities.getMovetypeByID(unitDefID) == 1 then
		local ud = UnitDefs[unitDefID]
		if not ud.customParams.is_drone then
			gunships[unitDefID] = true
		end
	end
end

function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)
	if gunships[unitDefID] then
		local cmdID = Spring.Utilities.GetUnitFirstCommand(unitID)
		if cmdID and (cmdID == CMD_RAW_MOVE or cmdID == CMD_FIGHT) then
			return
		end
		
		local angle = math.random()*TAU
		local x, _, z = Spring.GetUnitPosition(unitID)
		Spring.Utilities.GiveClampedMoveGoalToUnit(unitID, x + RADIUS*math.cos(angle), z + RADIUS*math.sin(angle))
		GG.WaitWaitMoveUnit(unitID)
	end
end
