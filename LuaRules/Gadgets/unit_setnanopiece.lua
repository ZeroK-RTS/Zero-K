--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Set Nano Piece",
    desc      = "Sets nano piece positions for COB-scripted units",
    author    = "KingRaptor",
    date      = "2013-2-2",
    license   = "Public Domain",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local spGetUnitPieceMap     = Spring.GetUnitPieceMap
local spGetUnitPiecePosDir  = Spring.GetUnitPiecePosDir
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local units = {
  [UnitDefNames.cloakcon.id] = {"claw1"},
  [UnitDefNames.jumpcon.id] = {"flare"},
  [UnitDefNames.vehcon.id] = {"firepoint"},
  [UnitDefNames.tankcon.id] = {"nano1", "nano2"},
  [UnitDefNames.hovercon.id] = {"beam"},
  [UnitDefNames.shipcon.id] = {"beam"},
  
  [UnitDefNames.factorycloak.id] = {"claw1"},
  [UnitDefNames.factoryshield.id] = {"nanoemit"},
  [UnitDefNames.factoryspider.id] = {"nanoemit"},
  [UnitDefNames.factoryamph.id] = {"nanoemit"},
  [UnitDefNames.factoryhover.id] = {"beam1", "beam2", "beam3", "beam4", "beam5", "beam6"},
  [UnitDefNames.factorygunship.id] = {"beam1", "beam2"},
}

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if units[unitDefID] then
    local pieceMap = spGetUnitPieceMap(unitID)
    local nanoPieces = {}
    for i=1,#units[unitDefID] do
      local pieceName = units[unitDefID][i]
      local pieceNum = pieceMap[pieceName]
      --local pieceNumAlt = Spring.GetUnitScriptPiece(unitID, pieceNum)
      --Spring.Echo("Nanopiece nums (input)", i, UnitDefs[unitDefID].name, pieceNum, pieceNumAlt)
      nanoPieces[#nanoPieces+1] = pieceNum
    end
    Spring.SetUnitNanoPieces(unitID, nanoPieces)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
