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

local spGetGameFrame = Spring.GetGameFrame
local spSetUnitBlocking = Spring.SetUnitBlocking
local spGetUnitIsDead = Spring.GetUnitIsDead

local noEject = {
	[UnitDefNames["staticmissilesilo"].id] = true,
	[UnitDefNames["factoryship"].id] = true,
	[UnitDefNames["factoryplane"].id] = true,
	[UnitDefNames["factorygunship"].id] = true,
	[UnitDefNames["plateship"].id] = true,
	[UnitDefNames["plateplane"].id] = true,
	[UnitDefNames["plategunship"].id] = true,
	[UnitDefNames["pw_dropfac"].id] = true,
	[UnitDefNames["pw_bomberfac"].id] = true,
}

local pushDefs = {}
local factoryDefs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.factory_creation_push then
		pushDefs[i] = tonumber(ud.customParams.factory_creation_push)
	end
	if (ud.isFactory and (not ud.customParams.notreallyafactory) and ud.buildOptions) then
		factoryDefs[i] = true
	end
end


local ghostFrames = 30 --how long the unit will be ethereal
local nanoGhostFrames = 50

local setBlocking = {} --indexed by gameframe, contains a subtable of unitIDs

local function SetTemporaryNoBlock(unitID, frames)
	local frame = spGetGameFrame() + ghostFrames
	if not setBlocking[frame] then
		setBlocking[frame] = {}
	end
	setBlocking[frame][unitID] = true
	spSetUnitBlocking(unitID, false)
end

function gadget:GameFrame(n)
	if setBlocking[n] then --restore blocking
		for unitID, _ in pairs(setBlocking[n]) do
			if not spGetUnitIsDead(unitID) then
				spSetUnitBlocking(unitID, true)
			end
		end
		setBlocking[n] = nil
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if not builderID then
		return
	end
	local builderDefID = Spring.GetUnitDefID(builderID)
	if not builderDefID then
		return
	end
	if not factoryDefs[builderDefID] or noEject[builderDefID] then
		return
	end
	SetTemporaryNoBlock(unitID, nanoGhostFrames)
end

function gadget:UnitFromFactory(unitID, unitDefID, teamID, builderID, builderDefID)
	if factoryDefs[builderDefID] then
		--Spring.Echo("Ejecting unit")
		if not noEject[builderDefID] then
			SetTemporaryNoBlock(unitID, ghostFrames)
		end
		if pushDefs[unitDefID] then
			GG.AddGadgetImpulseRaw(unitID, 0, 8, 0)
		end
	end
end
