function gadget:GetInfo()
    return {
        name    = "Cyclops attack move fixing",
        desc    = "Makes Cyclops move closer when it can't hit with canon",
        author  = "dyth68",
        date    = "2022-05-12",
        license = "Public Domain",
        layer   = 83,
        enabled = true
    }
end

local cyclopsi = {}
local cyclopsDefID = UnitDefNames["tankheavyassault"].id
local spGetUnitWeaponTestRange = Spring.GetUnitWeaponTestRange
local spGetUnitWeaponTarget    = Spring.GetUnitWeaponTarget
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetTeamUnitsByDefs     = Spring.GetTeamUnitsByDefs
local Echo                     = Spring.Echo
local spGetUnitCommands        = Spring.GetUnitCommands


function gadget:UnitCreated(unitID, unitDefID, teamId)
	if unitDefID == cyclopsDefID then
		cyclopsi[unitID] = true
	end
end


function gadget:UnitDestroyed(unitID, unitDefID, teamId)
	if unitDefID == cyclopsDefID then
		cyclopsi[unitID] = nil
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	if unitDefID == cyclopsDefID then
		cyclopsi[unitID] = true
	end
end

function gadget:Initialize()
	for _,teamID in ipairs(Spring.GetTeamList()) do
		for _, unitID in ipairs(spGetTeamUnitsByDefs(teamID, cyclopsDefID)) do
			cyclopsi[unitID] = true
		end
	end
end

function gadget:GameFrame(frame)
	for cyclopsId, _ in pairs(cyclopsi) do
		local _, _, canontargetID = spGetUnitWeaponTarget (cyclopsId, 1)
		local targetType, _, slowBeamTargetID = spGetUnitWeaponTarget (cyclopsId, 2)
		if (targetType == 1) and (canontargetID == nil) then
			--Echo("Retargetting Cyclops")
			local x, y, z = spGetUnitPosition(cyclopsId)
			local tx, ty, tz = spGetUnitPosition(slowBeamTargetID)
			local nx, nz = x * 0.95 + tx * 0.05, z * 0.95 + tz * 0.05
			local ny = math.max(0, Spring.GetGroundHeight(nx, nz))
			local cmd1 = spGetUnitCommands(cyclopsId, 1)[1]
			if cmd1 and cmd1.options.internal then
				spGiveOrderToUnit(cyclopsId, CMD.REMOVE, {1, cmd1.tag}, {"ctrl"})
			end
			spGiveOrderToUnit(cyclopsId, CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, nx, ny, nz}, CMD.OPT_ALT)
		end
	end
end