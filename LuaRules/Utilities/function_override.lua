-- Overrides some inbuilt spring functions
local origValidUnitID = Spring.ValidUnitID

local function newValidUnitID(unitID)
	return unitID and origValidUnitID(unitID)
end

Spring.ValidUnitID = newValidUnitID