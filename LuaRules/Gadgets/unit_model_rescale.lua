--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Model Rescaler",
		desc      = "Changes the sizes of units so their centre of mass may be seen.",
		author    = "GoogleFrog",
		date      = "10 April 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modifiedUnits = {}
local INLOS_ACCESS = {inlos = true}

VFS.Include("LuaRules/Utilities/tablefunctions.lua")
local suCopyTable = Spring.Utilities.CopyTable
local spGetUnitDefID = Spring.GetUnitDefID

local rescaleUnitDefIDs = {}
for i = 1, #UnitDefs do
	local scale = tonumber(UnitDefs[i].customParams.model_rescale)
	if scale and scale ~= 1 and scale > 0 then
		rescaleUnitDefIDs[i] = scale
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local y_axis = 2
local function SetScale(unitID, base, scale, offset)
	scale = scale or 1
	offset = offset or 0

	-- these are for the frankenturret API which probably isn't easily
	-- doable under the new engine (in that the script can Move and Scale
	-- and ruin it). See commit 2947da281323d61e6d1ac518db7779a8fca23f5b
	local currentScale = (Spring.GetUnitRulesParam(unitID, "currentModelScale") or 1)
	Spring.SetUnitRulesParam(unitID, "currentModelScale", scale, INLOS_ACCESS)
	local currentOffset = (Spring.GetUnitRulesParam(unitID, "currentModelOffset") or 0)
	Spring.SetUnitRulesParam(unitID, "currentOffset", offset, INLOS_ACCESS)
	Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Move, base, y_axis, offset)

	-- technically this one gets ruined by the script doing manual Scale too
	-- FIXME: this scales relative to the base piece, but this just
	-- puts bot legs underground. Old method did the correct thing
	-- of scaling relative to the ground
	Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Scale, base, scale)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitModelRescale(unitID, scale, offset)
	local base = Spring.GetUnitRootPiece(unitID)
	if base then
		modifiedUnits[unitID] = true
		local unitDefID = spGetUnitDefID(unitID)
		scale = scale * (rescaleUnitDefIDs[unitDefID] or 1)
		SetScale(unitID, base, scale, offset)
	end
end

function gadget:UnitDestroyed(unitID)
	modifiedUnits[unitID] = nil
end

function gadget:Shutdown()
	for unitID in pairs(modifiedUnits) do
		UnitModelRescale(unitID, 1, 0)
	end
end

GG.UnitModelRescale = UnitModelRescale

if next(rescaleUnitDefIDs) then
	function gadget:UnitCreated(unitID, unitDefID)
		local scale = rescaleUnitDefIDs[unitDefID]
		if not scale then
			return
		end

		UnitModelRescale(unitID, 1)
	end
end
