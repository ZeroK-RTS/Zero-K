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

	pieceTable[1] = scale
	pieceTable[6] = scale
	pieceTable[11] = scale
	pieceTable[13] = pieceTable[13]*scale
	pieceTable[14] = pieceTable[14]*scale
	pieceTable[15] = pieceTable[15]*scale
	Spring.SetUnitPieceMatrix(unitID, base, pieceTable)
end

local function FindBase(unitID)
	local pieces = Spring.GetUnitPieceList(unitID)
	local pieceMap = Spring.GetUnitPieceMap(unitID)
	for i = 1, #pieces do
		if Spring.GetUnitPieceInfo(unitID, pieceMap[pieces[i]]).parent == NULL_PIECE then
			return pieceMap[pieces[i]]
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
