local spGetUnitDefID = Spring.GetUnitDefID

------------------------------------------------------------------------------
--	How it works:
--	The system consists of two parts: this gadget and the Missile Silo script (scripts\missilesilo.lua). Each part does different things during four different events:
--		silo built:
--			add silo to array
--		silo destroyed:
--			gadget instructs silo to get all child missiles and blows them up on pad
--			remove silo from array
--		missile built:
--			AllowUnitCreation in gadget asks silo to checks slot.
--			If slot 1 is free, start construction . Slot is marked as filled by missileID once construction finishes, and parent is recorded.
--			If slot 1 is not free, check next slot until an empty one is found.
--			If no slots are free, block construction.
--		missile destroyed (including launch):
--			gadget instructs parent silo to check all slots and remove missile if found

if (gadgetHandler:IsSyncedCode()) then

function gadget:GetInfo()
  return {
    name      = "Missile Silo Controller",
    desc      = "Handles missile silos",
    author    = "KingRaptor (L.J. Lim)",
    date      = "31 August 2010",
    license   = "Public domain",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local siloDefID = UnitDefNames.missilesilo.id
local missileDefIDs = {
	[UnitDefNames.tacnuke.id] = true,
	[UnitDefNames.napalmmissile.id] = true,
	[UnitDefNames.empmissile.id] = true,
	[UnitDefNames.seismic.id] = true,
}

local silos = {}
local missileParents = {}	--stores the parent silo unitID for each missile unitID
local scheduleForDestruction

function gadget:Initialize()
	-- partial /luarules reload support
	-- it'll lose track of any missiles already built (meaning you can stack new missiles on them, and they don't die when the silo does)
	if Spring.GetGameFrame() > 1 then
		local unitList = Spring.GetAllUnits()
		for i,v in pairs(unitList) do
			if spGetUnitDefID(v) == siloDefID then silos[v] = true end
		end
	end
end

function gadget:GameFrame(n)
	if scheduleForDestruction then
		for i=1,#scheduleForDestruction do
			Spring.DestroyUnit(scheduleForDestruction[i], true)
		end
	end
	scheduleForDestruction = nil
end

function gadget:AllowUnitCreation(udefID, builderID)
	if (spGetUnitDefID(builderID) ~= siloDefID) then return true end
	local env = Spring.UnitScript.GetScriptEnv(builderID)
	return (Spring.UnitScript.CallAsUnit(builderID, env.BuildNewMissile)) --ask silo if it can build the missile
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if unitDefID == siloDefID then
		local env = Spring.UnitScript.GetScriptEnv(unitID)
		local missiles = Spring.UnitScript.CallAsUnit(unitID, env.GetMissiles)
		scheduleForDestruction = scheduleForDestruction or {}
		for index,missileID in pairs(missiles) do
			scheduleForDestruction[#scheduleForDestruction + 1] = missileID
		end
	elseif missileDefIDs[unitDefID] then
		local parent = missileParents[unitID]
		if parent then
			local env = Spring.UnitScript.GetScriptEnv(parent)
			if env then Spring.UnitScript.CallAsUnit(parent, env.RemoveMissile, unitID)	end		 --ask silo to remove missile from its inventory
		end
	end
end

function GG.DestroyMissile(unitID, unitDefID)
	gadget:UnitDestroyed(unitID, unitDefID)
end

function gadget:UnitCreated(unitID, unitDefID)
	if unitDefID == siloDefID then silos[unitID] = true end
end

--add newly finished missile to silo data
--this doesn't check half-built missiles, but there's actually no need to
function gadget:UnitFromFactory(unitID, unitDefID, unitTeam, facID, facDefID)
	if facDefID == siloDefID then
		local env = Spring.UnitScript.GetScriptEnv(facID)
		Spring.UnitScript.CallAsUnit(facID, env.AddMissile, unitID)
		missileParents[unitID] = facID
	end
end

end
