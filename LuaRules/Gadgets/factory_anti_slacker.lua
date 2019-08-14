--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GetInfo()
  return {
    name      = "Factory Anti Slacker",
    desc      = "Inhibits factory blocking.",
    author    = "Licho, edited by KingRaptor",
    date      = "10.4.2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local spGetUnitDefID = Spring.GetUnitDefID
local spGetGameFrame = Spring.GetGameFrame
local spSetUnitBlocking = Spring.SetUnitBlocking
local spGetUnitIsDead = Spring.GetUnitIsDead

local noEject = {
	[UnitDefNames["staticmissilesilo"].id] = true,
	[UnitDefNames["factoryship"].id] = true,
	[UnitDefNames["factoryplane"].id] = true,
	[UnitDefNames["factorygunship"].id] = true,
}
local ghostFrames = 30	--how long the unit will be ethereal

local setBlocking = {} --indexed by gameframe, contains a subtable of unitIDs

function gadget:GameFrame(n)
	if setBlocking[n] then	--restore blocking
		for unitID, _ in pairs(setBlocking[n]) do
			if not spGetUnitIsDead(unitID) then spSetUnitBlocking(unitID, true) end
		end
		setBlocking[n] = nil
	end
end

function gadget:UnitFromFactory(unitID, unitDefID, teamID, builderID, builderDefID)
	if not noEject[builderDefID] then
		--Spring.Echo("Ejecting unit")
		local frame = spGetGameFrame() + ghostFrames
		if not setBlocking[frame] then setBlocking[frame] = {} end
		setBlocking[frame][unitID] = true
		spSetUnitBlocking(unitID, false)
	end
end
