
local openState = false
local factoryState = false

local function UpdateInbuild(newOpen, newFactory)
	openState = newOpen
	factoryState = newFactory
	--Spring.Utilities.UnitEcho(unitID, (openState and "OPEN " or "_ ") .. (factoryState and " ACT" or " _"))
	SetUnitValue(COB.INBUILDSTANCE, (openState and factoryState and 1) or 0)
end

function SetInBuildDistance(newOpenState)
	UpdateInbuild(newOpenState, factoryState)
end

function SetFactoryAccess(newFactoryState)
	UpdateInbuild(openState, newFactoryState)
end
