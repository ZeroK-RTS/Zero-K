--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Size Changer",
		desc      = "Changes the sizes of units so their centre of mass may be seen.",
		author    = "GoogleFrog",
		date      = "10 April 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local NULL_PIECE = "[null]"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetScale(unitID, base, scale)
	local p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16 = Spring.GetUnitPieceMatrix(unitID, base)
	local pieceTable = {p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16}

	Spring.Echo(p1, p2, p3, p4)
	Spring.Echo(p5, p6, p7, p8)
	Spring.Echo(p9, p10, p11, p12)
	Spring.Echo(p13, p14, p15, p16)

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
	pieceTable[14] = pieceTable[14] * scale
	pieceTable[15] = pieceTable[15] * scale

	Spring.SetUnitPieceMatrix(unitID, base, pieceTable)
end

local function FindBase(unitID)
	local pieces = Spring.GetUnitPieceList(unitID)
	for pieceNum = 1, #pieces do
		if Spring.GetUnitPieceInfo(unitID, pieceNum).parent == NULL_PIECE then
			return pieceNum
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	local base = FindBase(unitID)
	if base then
		SetScale(unitID, base, 2)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
