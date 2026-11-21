-- This file is part of Zero-K (GPL v2 or later), see LICENSE.
-- Run from the game checkout: lua5.1 tests/portal_relations.lua
local checks = 0
local function Check(value)
	checks = checks + 1
	assert(value, "portal relation regression " .. checks)
end
Spring = {
	Utilities = {},
	GetUnitPosition = function(id)
		if id == 3 then
			return 150, 0, 50
		end
		if id == 4 then
			return 110, 0, 50
		end
	end,
}
gadgetHandler = { GG = {} }
dofile("LuaRules/Utilities/portal_relations.lua")
local u = Spring.Utilities
Check(u.IsSamePortalRegion(nil, nil))
Check(u.IsPortalPositionAllowed(nil, nil, nil))
Check(u.IsSamePortalPosition(0, 0, 1000, 1000))
local portal = {
	home = { [1] = 1, [2] = 2 },
	Region = function(x, z)
		if not x or not z or z < 0 or z >= 100 then
			return
		end
		if x >= 0 and x < 100 then
			return 1
		end
		if x >= 120 and x < 220 then
			return 2
		end
	end,
}
gadgetHandler.GG.PortalWorlds = portal
Check(u.IsSamePortalRegion(1, 1))
Check(not u.IsSamePortalRegion(1, 2))
Check(u.IsSamePortalRegion(2, 3)) -- physical fallback during creation
Check(not u.IsSamePortalRegion(1, 4)) -- unit in the cubicle barrier
Check(not u.IsSamePortalRegion(1, nil))
Check(not u.IsSamePortalRegion(1, 99))
Check(u.IsPortalPositionAllowed(1, 99, 99))
Check(not u.IsPortalPositionAllowed(1, 100, 50))
Check(not u.IsPortalPositionAllowed(1, 120, 50))
Check(not u.IsSamePortalPosition(0, 0, 120, 0))
Check(not u.IsSamePortalPosition(110, 0, 111, 0))
portal.home[1] = 2 -- cached links must see the updated logical membership
Check(u.IsSamePortalRegion(1, 2))
Check(u.IsPortalPositionAllowed(1, 120, 50))
Check(not u.IsPortalPositionAllowed(1, 0, 0))
gadgetHandler.GG.PortalWorlds = nil
Check(u.IsSamePortalRegion(1, 2))
Check(u.IsPortalPositionAllowed(1, -1, -1))
print("PORTAL_RELATIONS_PASS " .. checks)
