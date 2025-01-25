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

local origPieceTable = {}
local INLOS_ACCESS = {inlos = true}

VFS.Include("LuaRules/Utilities/tablefunctions.lua")
local suCopyTable = Spring.Utilities.CopyTable

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetScale(unitID, base, scale, offset)
	scale = scale or 1
	offset = offset or 0
	
	local currentScale = (Spring.GetUnitRulesParam(unitID, "currentModelScale") or 1)
	Spring.SetUnitRulesParam(unitID, "currentModelScale", scale, INLOS_ACCESS)
	local currentOffset = (Spring.GetUnitRulesParam(unitID, "currentModelOffset") or 0)
	Spring.SetUnitRulesParam(unitID, "currentOffset", offset, INLOS_ACCESS)
	
	local pieceTable = suCopyTable(origPieceTable[unitID])
	--for i = 0, 3 do
	--	Spring.Echo(pieceTable[i*4 + 1], pieceTable[i*4 + 2], pieceTable[i*4 + 3], pieceTable[i*4 + 4])
	--end

	pieceTable[1] = pieceTable[1] * scale
	pieceTable[2] = pieceTable[2] * scale
	pieceTable[3] = pieceTable[3] * scale

	pieceTable[5] = pieceTable[5] * scale
	pieceTable[6] = pieceTable[6] * scale
	pieceTable[7] = pieceTable[7] * scale

	pieceTable[9] = pieceTable[9] * scale
	pieceTable[10] = pieceTable[10] * scale
	pieceTable[11] = pieceTable[11] * scale

	pieceTable[13] = pieceTable[13] * scale
	pieceTable[14] = pieceTable[14] * scale + offset
	pieceTable[15] = pieceTable[15] * scale

	Spring.SetUnitPieceMatrix(unitID, base, pieceTable)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitModelRescale(unitID, scale, offset)
	local base = Spring.GetUnitRootPiece(unitID)
	if base then
		if not origPieceTable[unitID] then
			origPieceTable[unitID] = {Spring.GetUnitPieceMatrix(unitID, base)}
		end

		SetScale(unitID, base, scale, offset)
	end
end

function gadget:UnitDestroyed(unitID)
	origPieceTable[unitID] = nil
end

function gadget:Shutdown()
	for unitID in pairs(origPieceTable) do
		UnitModelRescale(unitID, 1, 0)
	end
end

GG.UnitModelRescale = UnitModelRescale

local rescaleUnitDefIDs = {}
for i = 1, #UnitDefs do
	local scale = tonumber(UnitDefs[i].customParams.model_rescale)
	if scale and scale ~= 1 and scale > 0 then
		rescaleUnitDefIDs[i] = scale
	end
end

if next(rescaleUnitDefIDs) then
	function gadget:UnitCreated(unitID, unitDefID)
		local scale = rescaleUnitDefIDs[unitDefID]
		if not scale then
			return
		end

		UnitModelRescale(unitID, scale)
	end
end
