--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "No Land At",
      desc      = "Removes Land At command",
      author    = "KingRaptor (L.J. Lim)",
      date      = "15/1/2011",
      license   = "Public Domain",
      layer     = 0,
      enabled   = true  
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--SYNCED
if gadgetHandler:IsSyncedCode() then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spFindUnitCmdDesc		= Spring.FindUnitCmdDesc
local spRemoveUnitCmdDesc	= Spring.RemoveUnitCmdDesc
local spGiveOrderToUnit		= Spring.GiveOrderToUnit

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD.AUTOREPAIRLEVEL)
	if cmdDescID then
		spGiveOrderToUnit(unitID, CMD.AUTOREPAIRLEVEL, {0}, {} )
		spRemoveUnitCmdDesc(unitID, cmdDescID)
	end
end

------------------------------------------------------

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		gadget:UnitCreated(units[i])
	end
end

end